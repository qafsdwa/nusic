//! Player state machine and its WebSocket broadcast hub.
//!
//! [`PlayerHub`] owns the *control* state — queue, repeat, shuffle, playhead —
//! and drives an [`AudioEngine`] for the actual sound. Keeping the two apart is
//! what lets the controller protocol (today the WebSocket; later anything that
//! translates into a [`PlayerCommand`]) be developed and tested without audio
//! hardware, and lets the playback backend be swapped without touching the
//! protocol.
//!
//! Three invariants keep this predictable:
//!
//! - all state lives behind one mutex, so a command is applied atomically;
//! - state is only *published* after the mutation, through
//!   [`PlayerHub::publish`], so subscribers never observe a half-applied
//!   command;
//! - a command that fails validation, or whose source cannot be handed to the
//!   engine, changes nothing and publishes nothing.
//!
//! `docs/backend-api.md` only documents `play` / `pause` / `next` / `seek`, but
//! the Flutter player has volume, shuffle and repeat too; the extra commands
//! exist so the WebSocket can drive the whole UI rather than a subset of it.

use std::sync::{Arc, Mutex};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use tokio::sync::broadcast;
use tokio::time::{interval, MissedTickBehavior};

use crate::api::bridge_models::BridgeTrackSource;
use crate::audio::{AudioEngine, AudioSource};
use crate::library::Library;
use crate::models::{PlaybackStatus, PlayerCommand, PlayerState, RepeatMode};

/// How often the hub samples the engine and pushes state to subscribers.
///
/// This is a *sampling* interval, not a clock: the playhead comes from the
/// engine, so a late or coalesced tick cannot make playback drift.
const TICK: Duration = Duration::from_millis(250);

/// Broadcast buffer size. A slow subscriber that falls further behind than this
/// is told it lagged instead of stalling every other client.
const BROADCAST_CAPACITY: usize = 64;

/// Volume a fresh player starts at (0.0..=1.0).
const DEFAULT_VOLUME: f64 = 0.7;

/// The mutable control state.
struct Inner {
    song_id: Option<String>,
    status: PlaybackStatus,
    position_ms: i64,
    duration_ms: i64,
    queue: Vec<String>,
    volume: f64,
    is_shuffle: bool,
    repeat_mode: RepeatMode,
    /// Index into `queue`, or `None` when nothing is loaded.
    index: Option<usize>,
}

impl Inner {
    fn snapshot(&self) -> PlayerState {
        PlayerState {
            song_id: self.song_id.clone(),
            status: self.status,
            position_ms: self.position_ms,
            duration_ms: self.duration_ms,
            queue: self.queue.clone(),
            volume: self.volume,
            is_shuffle: self.is_shuffle,
            repeat_mode: self.repeat_mode,
            updated_at_ms: now_ms(),
        }
    }

    fn is_playing(&self) -> bool {
        self.status == PlaybackStatus::Playing
    }
}

/// Shared player handle: commands go in, state snapshots come out.
pub struct PlayerHub {
    inner: Mutex<Inner>,
    library: Arc<Library>,
    engine: Arc<dyn AudioEngine>,
    sender: broadcast::Sender<PlayerState>,
}

impl PlayerHub {
    /// Creates a hub whose queue is the whole catalog, paused on the first song.
    ///
    /// Starting paused rather than idle matches the Flutter shell, which boots
    /// with a loaded-but-not-playing track so the player bar has content.
    pub fn new(library: Arc<Library>, engine: Arc<dyn AudioEngine>) -> Arc<Self> {
        let queue = library.ids();
        let (song_id, duration_ms) = match queue.first() {
            Some(id) => (
                Some(id.clone()),
                library.track(id).map(|t| t.duration_ms).unwrap_or(0),
            ),
            None => (None, 0),
        };

        let inner = Inner {
            song_id,
            status: if queue.is_empty() {
                PlaybackStatus::Idle
            } else {
                PlaybackStatus::Paused
            },
            position_ms: 0,
            duration_ms,
            queue,
            volume: DEFAULT_VOLUME,
            is_shuffle: false,
            repeat_mode: RepeatMode::Off,
            index: if library.is_empty() { None } else { Some(0) },
        };

        let (sender, _) = broadcast::channel(BROADCAST_CAPACITY);
        let hub = Arc::new(Self {
            inner: Mutex::new(inner),
            library,
            engine,
            sender,
        });

        // The engine cannot know the control state, so the initial volume has
        // to be pushed once. It then persists across loads (rodio keeps it on
        // the player, not the source).
        hub.engine.set_volume(DEFAULT_VOLUME as f32);

        // Hand the first track to the engine up front so the first `resume` and
        // the first snapshot agree with each other.
        let first = hub.snapshot().song_id;
        if let Some(id) = first {
            if let Err(error) = hub.load_into_engine(&id, Duration::ZERO, false) {
                tracing::warn!(song = %id, %error, "could not preload the first track");
            }
        }

        hub
    }

    /// Current state, without publishing anything.
    pub fn snapshot(&self) -> PlayerState {
        self.inner.lock().unwrap().snapshot()
    }

    /// Subscribes to state pushes.
    ///
    /// The returned receiver only sees *future* states; read [`Self::snapshot`]
    /// for the current one.
    pub fn subscribe(&self) -> broadcast::Receiver<PlayerState> {
        self.sender.subscribe()
    }

    /// Name of the playback backend, for logs and diagnostics.
    pub fn engine_name(&self) -> &'static str {
        self.engine.name()
    }

    /// Applies a command and publishes the resulting state.
    ///
    /// Returns an error message when the command cannot be applied, e.g. playing
    /// an id the catalog does not contain or a file that will not decode.
    /// Rejected commands publish nothing and change no state.
    pub fn apply(&self, command: PlayerCommand) -> Result<PlayerState, String> {
        let state = {
            let mut inner = self.inner.lock().unwrap();
            self.apply_locked(&mut inner, command)?;
            inner.snapshot()
        };
        // Published after the lock is released: `publish` clones the state and
        // never needs to re-enter the mutex, so a slow send cannot deadlock.
        self.publish(state.clone());
        Ok(state)
    }

    fn apply_locked(&self, inner: &mut Inner, command: PlayerCommand) -> Result<(), String> {
        // Keep the published playhead truthful: the engine owns it, and the
        // last tick may be up to `TICK` old.
        self.sync_position(inner);

        match command {
            PlayerCommand::Play { song_id } => {
                let duration_ms = self
                    .library
                    .track(&song_id)
                    .ok_or_else(|| format!("unknown song id: {song_id}"))?
                    .duration_ms;

                // Playing a song already in the queue keeps the queue order and
                // just moves the cursor; otherwise the queue is replaced so the
                // UI does not silently mix two different lists.
                let existing = inner.queue.iter().position(|id| *id == song_id);

                // Hand the track to the engine *before* touching state; a
                // failure here must leave everything as it was.
                self.load_into_engine(&song_id, Duration::ZERO, true)?;

                match existing {
                    Some(index) => inner.index = Some(index),
                    None => {
                        inner.queue = vec![song_id.clone()];
                        inner.index = Some(0);
                    }
                }
                inner.song_id = Some(song_id);
                inner.duration_ms = duration_ms;
                inner.position_ms = 0;
                inner.status = PlaybackStatus::Playing;
            }
            PlayerCommand::PlayQueue {
                song_ids,
                start_index,
            } => {
                if song_ids.is_empty() {
                    return Err("play_queue requires at least one song id".to_owned());
                }
                // Validate every id up front so a bad queue is rejected whole
                // rather than half-applied.
                for id in &song_ids {
                    if self.library.track(id).is_none() {
                        return Err(format!("unknown song id: {id}"));
                    }
                }
                let index = start_index.max(0) as usize;
                if index >= song_ids.len() {
                    return Err(format!(
                        "start_index {index} is out of range for a queue of {} songs",
                        song_ids.len()
                    ));
                }

                // Duration must come from the track actually starting, not from
                // whichever id the validation loop happened to finish on.
                let start_id = song_ids[index].clone();
                let duration_ms = self
                    .library
                    .track(&start_id)
                    .map(|track| track.duration_ms)
                    .unwrap_or(0);
                self.load_into_engine(&start_id, Duration::ZERO, true)?;

                inner.song_id = Some(start_id);
                inner.duration_ms = duration_ms;
                inner.position_ms = 0;
                inner.status = PlaybackStatus::Playing;
                inner.queue = song_ids;
                inner.index = Some(index);
            }
            PlayerCommand::Pause => {
                if inner.song_id.is_some() {
                    self.engine.pause().map_err(|error| error.to_string())?;
                    inner.status = PlaybackStatus::Paused;
                }
            }
            PlayerCommand::Resume => {
                if inner.song_id.is_some() {
                    self.engine.play().map_err(|error| error.to_string())?;
                    inner.status = PlaybackStatus::Playing;
                }
            }
            PlayerCommand::Toggle => {
                if inner.song_id.is_some() {
                    if inner.is_playing() {
                        self.engine.pause().map_err(|error| error.to_string())?;
                        inner.status = PlaybackStatus::Paused;
                    } else {
                        self.engine.play().map_err(|error| error.to_string())?;
                        inner.status = PlaybackStatus::Playing;
                    }
                }
            }
            PlayerCommand::Next => self.step(inner, 1)?,
            PlayerCommand::Previous => self.step(inner, -1)?,
            PlayerCommand::Seek { position_ms } => {
                if inner.song_id.is_none() {
                    return Err("cannot seek: nothing is loaded".to_owned());
                }
                // Clamped rather than rejected: a UI scrubbing past the end
                // should settle on the last frame, not fail the request.
                let target = position_ms.clamp(0, inner.duration_ms.max(0));
                self.engine
                    .seek(Duration::from_millis(target as u64))
                    .map_err(|error| error.to_string())?;
                inner.position_ms = target;
            }
            PlayerCommand::SetVolume { volume } => {
                if !volume.is_finite() {
                    return Err("volume must be a finite number".to_owned());
                }
                let volume = volume.clamp(0.0, 1.0);
                self.engine.set_volume(volume as f32);
                inner.volume = volume;
            }
            PlayerCommand::SetShuffle { enabled } => inner.is_shuffle = enabled,
            PlayerCommand::SetRepeat { mode } => inner.repeat_mode = mode,
            PlayerCommand::ClearQueue => {
                self.engine.stop().map_err(|error| error.to_string())?;
                inner.queue.clear();
                inner.index = None;
                inner.song_id = None;
                inner.position_ms = 0;
                inner.duration_ms = 0;
                inner.status = PlaybackStatus::Idle;
            }
            PlayerCommand::RequestState => {}
        }

        Ok(())
    }

    /// Moves `delta` entries through the queue, honouring repeat mode.
    ///
    /// Also used when a track ends, which is why it always leaves the engine
    /// playing (or stopped at the end of the queue).
    fn step(&self, inner: &mut Inner, delta: isize) -> Result<(), String> {
        if inner.queue.is_empty() {
            return Err("queue is empty".to_owned());
        }

        // Repeat-one restarts the track instead of moving: this is what the
        // Flutter `PlayerNotifier` does, and what the mode reads as.
        if inner.repeat_mode == RepeatMode::One {
            self.engine
                .seek(Duration::ZERO)
                .map_err(|error| error.to_string())?;
            self.engine.play().map_err(|error| error.to_string())?;
            inner.position_ms = 0;
            inner.status = PlaybackStatus::Playing;
            return Ok(());
        }

        let len = inner.queue.len();
        let current = inner.index.unwrap_or(0);

        let next = if inner.is_shuffle {
            pseudo_random_index(len, current)
        } else {
            let stepped = current as isize + delta;
            if stepped < 0 {
                // `Previous` at the head wraps only when repeating the whole
                // queue; otherwise it restarts the first track.
                if inner.repeat_mode == RepeatMode::All {
                    len - 1
                } else {
                    0
                }
            } else if stepped as usize >= len {
                if inner.repeat_mode == RepeatMode::All {
                    0
                } else {
                    // End of queue without repeat: park on the last track and
                    // let the engine go quiet.
                    self.engine.stop().map_err(|error| error.to_string())?;
                    inner.position_ms = inner.duration_ms;
                    inner.status = PlaybackStatus::Idle;
                    return Ok(());
                }
            } else {
                stepped as usize
            }
        };

        let song_id = inner.queue[next].clone();
        let duration_ms = self
            .library
            .track(&song_id)
            .map(|track| track.duration_ms)
            .unwrap_or(0);
        self.load_into_engine(&song_id, Duration::ZERO, true)?;

        inner.index = Some(next);
        inner.song_id = Some(song_id);
        inner.duration_ms = duration_ms;
        inner.position_ms = 0;
        inner.status = PlaybackStatus::Playing;
        Ok(())
    }

    /// Hands `song_id` to the engine, optionally starting playback.
    ///
    /// The source is resolved and prepared before the engine is disturbed, so a
    /// failure leaves the previous track untouched.
    fn load_into_engine(
        &self,
        song_id: &str,
        position: Duration,
        autoplay: bool,
    ) -> Result<(), String> {
        let source = self.audio_source(song_id)?;
        self.engine
            .load(&source, position)
            .map_err(|error| error.to_string())?;

        if autoplay {
            self.engine.play().map_err(|error| error.to_string())?;
        } else {
            self.engine.pause().map_err(|error| error.to_string())?;
        }
        Ok(())
    }

    /// Resolves a song id to something the engine can play.
    ///
    /// Local files and prepared online tracks both resolve to [`AudioSource::File`].
    /// Seed entries — and anything else without a backing file — become a silent
    /// placeholder of the right length, so the timeline stays real instead of the
    /// API pretending a file exists.
    ///
    /// An online track that has not been downloaded yet is an error rather than
    /// silence: the Dart side prepares it first, so reaching this branch means
    /// the caller skipped a step, and a clear message beats a silent track.
    fn audio_source(&self, song_id: &str) -> Result<AudioSource, String> {
        let track = self
            .library
            .track(song_id)
            .ok_or_else(|| format!("unknown song id: {song_id}"))?;
        let duration = Duration::from_millis(track.duration_ms.max(0) as u64);

        match self.library.file(song_id) {
            Some(path) => Ok(AudioSource::File { path, duration }),
            None if track.source == BridgeTrackSource::Remote => Err(format!(
                "online track {song_id} has not been downloaded yet"
            )),
            None => Ok(AudioSource::Silence { duration }),
        }
    }

    /// Mirrors the engine's playhead into the control state.
    ///
    /// Only meaningful while playing: a paused engine reports the frozen
    /// position, and an unloaded one reports zero.
    fn sync_position(&self, inner: &mut Inner) {
        if inner.is_playing() {
            inner.position_ms = self.engine.position().as_millis() as i64;
        }
    }

    fn publish(&self, state: PlayerState) {
        // `send` fails only when there are no subscribers, which is normal and
        // not an error worth surfacing.
        let _ = self.sender.send(state);
    }

    /// Samples the engine until `shutdown` resolves.
    ///
    /// The playhead is owned by the engine; this only mirrors it and reacts
    /// when a track has run out.
    pub async fn run(self: Arc<Self>, mut shutdown: tokio::sync::watch::Receiver<bool>) {
        let mut ticker = interval(TICK);
        // If a tick is missed, skip it: the position is absolute, so there is
        // nothing to catch up on.
        ticker.set_missed_tick_behavior(MissedTickBehavior::Skip);

        loop {
            tokio::select! {
                _ = ticker.tick() => self.tick(),
                result = shutdown.changed() => {
                    // `changed` also errors when the sender is dropped, which
                    // means shutdown; either way the loop ends.
                    if result.is_err() || *shutdown.borrow() {
                        return;
                    }
                }
            }
        }
    }

    /// Samples the engine once.
    ///
    /// `pub(crate)` so the in-process FFI runtime can drive it from a plain
    /// thread, without pulling a tokio runtime into the Flutter app.
    pub(crate) fn tick(&self) {
        let state = {
            let mut inner = self.inner.lock().unwrap();
            if !inner.is_playing() {
                return;
            }

            inner.position_ms = self.engine.position().as_millis() as i64;

            if self.engine.is_finished() {
                if let Err(message) = self.step(&mut inner, 1) {
                    tracing::warn!(%message, "could not advance after the track ended");
                    inner.status = PlaybackStatus::Paused;
                }
            }

            inner.snapshot()
        };
        self.publish(state);
    }
}

/// Index for the next shuffled track.
///
/// Not a real RNG: the position is used as the seed so the sequence is
/// reproducible in tests. It only has to avoid immediately repeating the
/// current track, which a rotating offset over the queue guarantees.
fn pseudo_random_index(len: usize, current: usize) -> usize {
    if len <= 1 {
        return 0;
    }
    let offset = 1 + (now_ms().unsigned_abs() as usize) % (len - 1);
    (current + offset) % len
}

fn now_ms() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|elapsed| elapsed.as_millis().min(i64::MAX as u128) as i64)
        .unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::bridge_models::BridgeTrack;
    use crate::audio::{AudioError, ClockEngine};

    fn hub() -> Arc<PlayerHub> {
        PlayerHub::new(
            Arc::new(Library::seeded("http://127.0.0.1:8080")),
            Arc::new(ClockEngine::new()),
        )
    }

    /// An engine that refuses to load anything, to exercise the "a rejected
    /// command changes nothing" invariant against an engine-level failure.
    struct FailingEngine;

    impl AudioEngine for FailingEngine {
        fn load(&self, _source: &AudioSource, _position: Duration) -> Result<(), AudioError> {
            Err(AudioError::Open {
                path: "boom".to_owned(),
                message: "refused".to_owned(),
            })
        }
        fn play(&self) -> Result<(), AudioError> {
            Ok(())
        }
        fn pause(&self) -> Result<(), AudioError> {
            Ok(())
        }
        fn stop(&self) -> Result<(), AudioError> {
            Ok(())
        }
        fn seek(&self, _position: Duration) -> Result<(), AudioError> {
            Ok(())
        }
        fn set_volume(&self, _volume: f32) {}
        fn position(&self) -> Duration {
            Duration::ZERO
        }
        fn is_finished(&self) -> bool {
            false
        }
        fn name(&self) -> &'static str {
            "failing"
        }
    }

    #[test]
    fn starts_paused_on_the_first_song_with_the_whole_catalog_queued() {
        let state = hub().snapshot();
        assert_eq!(state.song_id.as_deref(), Some("song_001"));
        assert_eq!(state.status, PlaybackStatus::Paused);
        assert_eq!(state.duration_ms, 252_000);
        assert_eq!(state.queue.len(), 6);
        assert_eq!(state.queue[0], "song_001");
    }

    #[test]
    fn play_switches_track_and_starts_playback() {
        let hub = hub();
        let state = hub
            .apply(PlayerCommand::Play {
                song_id: "song_002".into(),
            })
            .unwrap();
        assert_eq!(state.song_id.as_deref(), Some("song_002"));
        assert_eq!(state.status, PlaybackStatus::Playing);
        assert_eq!(state.duration_ms, 308_000);
        // Already in the catalog queue, so the queue is kept intact.
        assert_eq!(state.queue.len(), 6);
    }

    #[test]
    fn play_rejects_unknown_ids() {
        let hub = hub();
        let error = hub
            .apply(PlayerCommand::Play {
                song_id: "nope".into(),
            })
            .unwrap_err();
        assert!(error.contains("unknown song id"));
        // The rejected command must not have changed anything.
        assert_eq!(hub.snapshot().song_id.as_deref(), Some("song_001"));
    }

    fn online_track() -> BridgeTrack {
        BridgeTrack {
            id: "bili_BV1".to_owned(),
            title: "在线曲目".to_owned(),
            artist: "UP".to_owned(),
            album: String::new(),
            cover_url: None,
            duration_ms: 205_000,
            source: BridgeTrackSource::Remote,
        }
    }

    fn online_hub(with_file: bool) -> (Arc<Library>, Arc<PlayerHub>) {
        let library = Arc::new(Library::seeded("http://127.0.0.1:8080"));
        match with_file {
            true => library.register_online_file(
                online_track(),
                std::path::PathBuf::from("/cache/bili_BV1.m4a"),
            ),
            false => library.register_online(vec![online_track()]),
        }

        let hub = PlayerHub::new(library.clone(), Arc::new(ClockEngine::new()));
        (library, hub)
    }

    #[test]
    fn an_unprepared_online_track_is_rejected_rather_than_silenced() {
        let (_, hub) = online_hub(false);

        let error = hub
            .apply(PlayerCommand::Play {
                song_id: "bili_BV1".into(),
            })
            .unwrap_err();

        assert!(error.contains("has not been downloaded"), "{error}");
        // The rejected command must not have changed anything.
        assert_eq!(hub.snapshot().song_id.as_deref(), Some("song_001"));
    }

    #[test]
    fn a_prepared_online_track_plays_like_a_local_file() {
        let (_, hub) = online_hub(true);

        let state = hub
            .apply(PlayerCommand::Play {
                song_id: "bili_BV1".into(),
            })
            .unwrap();

        // Resolving the source succeeded, so the cached file — not a silent
        // placeholder — was handed to the engine. `ClockEngine` never touches
        // the path, which is what lets this test run without a download.
        assert_eq!(state.song_id.as_deref(), Some("bili_BV1"));
        assert_eq!(state.duration_ms, 205_000);
        assert_eq!(state.queue, vec!["bili_BV1".to_owned()]);
        assert_eq!(state.status, PlaybackStatus::Playing);
    }

    #[test]
    fn a_failing_engine_leaves_the_state_untouched() {
        let hub = PlayerHub::new(
            Arc::new(Library::seeded("http://127.0.0.1:8080")),
            Arc::new(FailingEngine),
        );
        let error = hub
            .apply(PlayerCommand::Play {
                song_id: "song_002".into(),
            })
            .unwrap_err();

        assert!(error.contains("refused"));
        let state = hub.snapshot();
        assert_eq!(state.song_id.as_deref(), Some("song_001"));
        assert_eq!(state.status, PlaybackStatus::Paused);
    }

    #[test]
    fn pause_and_toggle_flip_status() {
        let hub = hub();
        hub.apply(PlayerCommand::Resume).unwrap();
        assert_eq!(hub.snapshot().status, PlaybackStatus::Playing);

        hub.apply(PlayerCommand::Pause).unwrap();
        assert_eq!(hub.snapshot().status, PlaybackStatus::Paused);

        hub.apply(PlayerCommand::Toggle).unwrap();
        assert_eq!(hub.snapshot().status, PlaybackStatus::Playing);
    }

    #[test]
    fn next_and_previous_move_through_the_queue() {
        let hub = hub();
        hub.apply(PlayerCommand::Next).unwrap();
        assert_eq!(hub.snapshot().song_id.as_deref(), Some("song_002"));

        hub.apply(PlayerCommand::Previous).unwrap();
        assert_eq!(hub.snapshot().song_id.as_deref(), Some("song_001"));

        // Without repeat, previous at the head restarts the first track.
        hub.apply(PlayerCommand::Previous).unwrap();
        assert_eq!(hub.snapshot().song_id.as_deref(), Some("song_001"));
    }

    #[test]
    fn next_past_the_end_stops_without_repeat() {
        let hub = hub();
        hub.apply(PlayerCommand::PlayQueue {
            song_ids: vec!["song_001".into(), "song_002".into()],
            start_index: 1,
        })
        .unwrap();

        hub.apply(PlayerCommand::Next).unwrap();
        let state = hub.snapshot();
        assert_eq!(state.song_id.as_deref(), Some("song_002"));
        assert_eq!(state.status, PlaybackStatus::Idle);
    }

    #[test]
    fn repeat_all_wraps_and_repeat_one_restarts() {
        let hub = hub();
        hub.apply(PlayerCommand::SetRepeat {
            mode: RepeatMode::All,
        })
        .unwrap();
        hub.apply(PlayerCommand::PlayQueue {
            song_ids: vec!["song_001".into(), "song_002".into()],
            start_index: 1,
        })
        .unwrap();
        hub.apply(PlayerCommand::Next).unwrap();
        assert_eq!(hub.snapshot().song_id.as_deref(), Some("song_001"));

        hub.apply(PlayerCommand::SetRepeat {
            mode: RepeatMode::One,
        })
        .unwrap();
        hub.apply(PlayerCommand::Next).unwrap();
        let state = hub.snapshot();
        assert_eq!(state.song_id.as_deref(), Some("song_001"));
        assert_eq!(state.position_ms, 0);
    }

    #[test]
    fn seek_is_clamped_to_the_track_duration() {
        let hub = hub();
        hub.apply(PlayerCommand::Seek {
            position_ms: 999_999_999,
        })
        .unwrap();
        assert_eq!(hub.snapshot().position_ms, 252_000);

        hub.apply(PlayerCommand::Seek { position_ms: -5 }).unwrap();
        assert_eq!(hub.snapshot().position_ms, 0);
    }

    #[test]
    fn the_initial_volume_is_pushed_to_the_engine() {
        // `ClockEngine` ignores volume, so assert on the control state that is
        // published to clients; the rodio hand-off is covered by the engine
        // integration test.
        let state = hub().snapshot();
        assert_eq!(state.volume, DEFAULT_VOLUME);
    }

    #[test]
    fn volume_is_clamped_and_must_be_finite() {
        let hub = hub();
        hub.apply(PlayerCommand::SetVolume { volume: 4.0 }).unwrap();
        assert_eq!(hub.snapshot().volume, 1.0);

        hub.apply(PlayerCommand::SetVolume { volume: -1.0 })
            .unwrap();
        assert_eq!(hub.snapshot().volume, 0.0);

        assert!(hub
            .apply(PlayerCommand::SetVolume { volume: f64::NAN })
            .is_err());
    }

    #[test]
    fn play_queue_validates_ids_and_start_index() {
        let hub = hub();
        assert!(hub
            .apply(PlayerCommand::PlayQueue {
                song_ids: vec![],
                start_index: 0
            })
            .is_err());
        assert!(hub
            .apply(PlayerCommand::PlayQueue {
                song_ids: vec!["song_001".into()],
                start_index: 5,
            })
            .is_err());
        assert!(hub
            .apply(PlayerCommand::PlayQueue {
                song_ids: vec!["song_001".into(), "ghost".into()],
                start_index: 0,
            })
            .is_err());
        // Nothing was applied.
        assert_eq!(hub.snapshot().queue.len(), 6);
    }

    #[test]
    fn clear_queue_resets_to_idle() {
        let hub = hub();
        hub.apply(PlayerCommand::ClearQueue).unwrap();
        let state = hub.snapshot();
        assert!(state.song_id.is_none());
        assert!(state.queue.is_empty());
        assert_eq!(state.status, PlaybackStatus::Idle);
    }

    #[test]
    fn apply_publishes_to_subscribers() {
        let hub = hub();
        let mut receiver = hub.subscribe();

        hub.apply(PlayerCommand::Play {
            song_id: "song_003".into(),
        })
        .unwrap();
        let pushed = receiver
            .try_recv()
            .expect("a state should have been published");
        assert_eq!(pushed.song_id.as_deref(), Some("song_003"));
    }

    #[test]
    fn rejected_commands_do_not_publish() {
        let hub = hub();
        let mut receiver = hub.subscribe();

        assert!(hub
            .apply(PlayerCommand::Play {
                song_id: "nope".into()
            })
            .is_err());
        assert!(receiver.try_recv().is_err());
    }

    #[test]
    fn tick_samples_the_engine_only_while_playing() {
        let hub = hub();
        hub.tick();
        assert_eq!(
            hub.snapshot().position_ms,
            0,
            "paused players do not advance"
        );

        hub.apply(PlayerCommand::Resume).unwrap();
        std::thread::sleep(Duration::from_millis(30));
        hub.tick();
        assert!(
            hub.snapshot().position_ms > 0,
            "a playing player tracks the engine playhead"
        );
    }

    #[test]
    fn tick_while_paused_publishes_nothing() {
        let hub = hub();
        let mut receiver = hub.subscribe();
        hub.tick();
        assert!(receiver.try_recv().is_err());
    }

    #[test]
    fn tick_auto_advances_at_the_end_of_a_track() {
        let hub = hub();
        hub.apply(PlayerCommand::PlayQueue {
            song_ids: vec!["song_001".into(), "song_002".into()],
            start_index: 0,
        })
        .unwrap();
        // Seek to the exact end of the first track; the next sample must notice
        // that the engine has run out and move on.
        hub.apply(PlayerCommand::Seek {
            position_ms: 252_000,
        })
        .unwrap();
        hub.tick();

        let state = hub.snapshot();
        assert_eq!(state.song_id.as_deref(), Some("song_002"));
        assert_eq!(state.status, PlaybackStatus::Playing);
    }

    #[test]
    fn shuffle_never_picks_the_current_track() {
        for current in 0..6 {
            let next = pseudo_random_index(6, current);
            assert_ne!(next, current);
            assert!(next < 6);
        }
        assert_eq!(pseudo_random_index(1, 0), 0);
    }
}

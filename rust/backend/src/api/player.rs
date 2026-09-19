//! Player control and state, callable directly from Dart.
//!
//! The engine speaks the same vocabulary as the HTTP front-end
//! ([`crate::models::PlayerCommand`]); this module is the adapter that lets the
//! app drive it with the shared contract types instead of JSON.

// `StreamSink` is generated into this crate by flutter_rust_bridge, not
// exported by the runtime crate.
use crate::frb_generated::StreamSink;

use crate::api::bridge_models::{
    BridgePlaybackStatus, BridgePlayerCommand, BridgePlayerSnapshot, BridgeRepeatMode, BridgeTrack,
};
use crate::runtime;
use crate::models::{PlaybackStatus, PlayerCommand, PlayerState, RepeatMode};

/// Builds the library and player, and starts pushing state to subscribers.
///
/// Idempotent, so Flutter can re-create providers without restarting.
pub fn init(music_dir: Option<String>, volume: f64) -> Result<(), String> {
    runtime::init(music_dir.as_deref(), volume)
}

/// Current state, without subscribing.
pub fn snapshot() -> Result<BridgePlayerSnapshot, String> {
    let runtime = runtime::current()?;
    to_snapshot(&runtime.library, runtime.player.snapshot())
}

/// Applies a command and returns the resulting state.
pub fn command(command: BridgePlayerCommand) -> Result<BridgePlayerSnapshot, String> {
    let runtime = runtime::current()?;
    let translated = to_engine_command(command);
    let state = runtime
        .player
        .apply(translated)
        .map_err(|error| error.to_string())?;
    to_snapshot(&runtime.library, state)
}

/// Pushes a state snapshot whenever the player changes.
///
/// Runs a plain thread rather than a tokio task: the Flutter app has no tokio
/// runtime, and the work is a cheap poll.
pub fn subscribe(sink: StreamSink<BridgePlayerSnapshot>) -> Result<(), String> {
    let runtime = runtime::current()?;
    let library = runtime.library.clone();
    let player = runtime.player.clone();

    // Send the current state immediately so the UI is never blank while it
    // waits for the first change.
    let initial = to_snapshot(&library, player.snapshot())?;
    if sink.add(initial).is_err() {
        return Ok(());
    }

    std::thread::Builder::new()
        .name("muse-ffi-stream".to_owned())
        .spawn(move || {
            // A dedicated receiver per subscriber keeps every Dart `Stream`
            // independent; a lagging one cannot stall the others.
            let mut receiver = player.subscribe();
            loop {
                match receiver.try_recv() {
                    Ok(state) => {
                        let Ok(snapshot) = to_snapshot(&library, state) else {
                            continue;
                        };
                        if sink.add(snapshot).is_err() {
                            // The Dart side stopped listening.
                            return;
                        }
                    }
                    Err(tokio::sync::broadcast::error::TryRecvError::Empty) => {
                        std::thread::sleep(std::time::Duration::from_millis(50));
                    }
                    // Missed pushes are harmless: every push is a full
                    // snapshot, so the next one restores consistency.
                    Err(tokio::sync::broadcast::error::TryRecvError::Lagged(_)) => {}
                    Err(tokio::sync::broadcast::error::TryRecvError::Closed) => return,
                }
            }
        })
        .map_err(|error| format!("cannot start the state stream: {error}"))?;

    Ok(())
}

/// Maps the shared contract command onto the engine's vocabulary.
fn to_engine_command(command: BridgePlayerCommand) -> PlayerCommand {
    match command {
        BridgePlayerCommand::Play { track_id } => PlayerCommand::Play { song_id: track_id },
        BridgePlayerCommand::PlayTrack { track } => PlayerCommand::Play { song_id: track.id },
        BridgePlayerCommand::PlayQueue {
            tracks,
            start_index,
        } => PlayerCommand::PlayQueue {
            song_ids: tracks.into_iter().map(|track| track.id).collect(),
            start_index,
        },
        BridgePlayerCommand::Pause => PlayerCommand::Pause,
        BridgePlayerCommand::Resume => PlayerCommand::Resume,
        BridgePlayerCommand::Toggle => PlayerCommand::Toggle,
        BridgePlayerCommand::Next => PlayerCommand::Next,
        BridgePlayerCommand::Previous => PlayerCommand::Previous,
        BridgePlayerCommand::Seek { position_ms } => PlayerCommand::Seek { position_ms },
        BridgePlayerCommand::SetVolume { volume } => PlayerCommand::SetVolume { volume },
        BridgePlayerCommand::SetShuffle { enabled } => PlayerCommand::SetShuffle { enabled },
        BridgePlayerCommand::SetRepeat { mode } => PlayerCommand::SetRepeat {
            mode: from_contract_repeat(mode),
        },
        BridgePlayerCommand::ClearQueue => PlayerCommand::ClearQueue,
        BridgePlayerCommand::RequestSnapshot => PlayerCommand::RequestState,
    }
}

/// Projects the engine state onto the shared contract.
///
/// The engine tracks ids (small payloads for the HTTP path); the contract
/// carries full tracks, which is what the app renders.
fn to_snapshot(
    library: &crate::library::Library,
    state: PlayerState,
) -> Result<BridgePlayerSnapshot, String> {
    let queue: Vec<BridgeTrack> = state
        .queue
        .iter()
        .map(|id| {
            library
                .track(id)
                // A queue entry the catalog no longer knows about would
                // otherwise shift every later index.
                .unwrap_or_else(|| placeholder(id))
        })
        .collect();

    let current_track = state
        .song_id
        .as_deref()
        .map(|id| library.track(id).unwrap_or_else(|| placeholder(id)));

    let current_index = state
        .song_id
        .as_deref()
        .and_then(|id| queue.iter().position(|track| track.id == id))
        .map_or(-1, |index| index as i32);

    Ok(BridgePlayerSnapshot {
        current_track,
        status: to_contract_status(state.status),
        position_ms: state.position_ms,
        duration_ms: state.duration_ms,
        volume: state.volume,
        is_shuffle: state.is_shuffle,
        repeat_mode: to_contract_repeat(state.repeat_mode),
        queue,
        current_index,
        updated_at_ms: state.updated_at_ms,
    })
}

fn placeholder(id: &str) -> BridgeTrack {
    BridgeTrack {
        id: id.to_owned(),
        title: id.to_owned(),
        artist: String::new(),
        album: String::new(),
        cover_url: None,
        duration_ms: 0,
        source: crate::api::bridge_models::BridgeTrackSource::Unknown,
    }
}

fn to_contract_status(status: PlaybackStatus) -> BridgePlaybackStatus {
    match status {
        PlaybackStatus::Idle => BridgePlaybackStatus::Idle,
        PlaybackStatus::Loading => BridgePlaybackStatus::Loading,
        PlaybackStatus::Playing => BridgePlaybackStatus::Playing,
        PlaybackStatus::Paused => BridgePlaybackStatus::Paused,
        PlaybackStatus::Buffering => BridgePlaybackStatus::Buffering,
        PlaybackStatus::Error => BridgePlaybackStatus::Error,
    }
}

fn to_contract_repeat(mode: RepeatMode) -> BridgeRepeatMode {
    match mode {
        RepeatMode::Off => BridgeRepeatMode::Off,
        RepeatMode::All => BridgeRepeatMode::All,
        RepeatMode::One => BridgeRepeatMode::One,
    }
}

fn from_contract_repeat(mode: BridgeRepeatMode) -> RepeatMode {
    match mode {
        BridgeRepeatMode::Off => RepeatMode::Off,
        BridgeRepeatMode::All => RepeatMode::All,
        BridgeRepeatMode::One => RepeatMode::One,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Arc;

    use crate::api::bridge_models::BridgeTrackSource;
    use crate::audio::ClockEngine;
    use crate::library::Library;

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

    #[test]
    fn online_queue_entries_project_to_real_tracks() {
        let library = Arc::new(Library::seeded("http://127.0.0.1:8080"));
        library.register_online_file(
            online_track(),
            std::path::PathBuf::from("/cache/bili_BV1.m4a"),
        );
        let hub = crate::player::PlayerHub::new(library.clone(), Arc::new(ClockEngine::new()));

        let state = hub
            .apply(PlayerCommand::Play {
                song_id: "bili_BV1".into(),
            })
            .expect("the cached track loads");

        let snapshot = to_snapshot(&library, state).expect("snapshot");
        let current = snapshot.current_track.expect("a track is loaded");
        assert_eq!(current.id, "bili_BV1");
        assert_eq!(current.title, "在线曲目");
        assert_eq!(current.source, BridgeTrackSource::Remote);
        assert_eq!(snapshot.current_index, 0);

        // Queue entries resolve through the overlay rather than collapsing into
        // the id-only placeholder.
        assert_eq!(snapshot.queue.len(), 1);
        assert_eq!(snapshot.queue[0].title, "在线曲目");
    }

    #[test]
    fn an_unknown_queue_id_still_projects_to_a_placeholder() {
        let library = Arc::new(Library::seeded("http://127.0.0.1:8080"));
        let mut state = PlayerState {
            song_id: Some("gone".to_owned()),
            status: PlaybackStatus::Playing,
            position_ms: 0,
            duration_ms: 0,
            queue: vec!["gone".to_owned()],
            volume: 0.7,
            is_shuffle: false,
            repeat_mode: RepeatMode::Off,
            updated_at_ms: 0,
        };

        let snapshot = to_snapshot(&library, state.clone()).expect("snapshot");
        assert_eq!(snapshot.queue[0].title, "gone");
        assert_eq!(snapshot.queue[0].source, BridgeTrackSource::Unknown);

        state.queue.clear();
        state.song_id = None;
        let snapshot = to_snapshot(&library, state).expect("snapshot");
        assert_eq!(snapshot.current_index, -1);
        assert!(snapshot.current_track.is_none());
    }
}

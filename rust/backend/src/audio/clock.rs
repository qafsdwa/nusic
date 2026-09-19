//! Device-less engine: a virtual playhead for headless runs and tests.

use std::sync::Mutex;
use std::time::{Duration, Instant};

use super::{AudioEngine, AudioError, AudioSource};

/// Everything the virtual playhead needs.
///
/// `origin + elapsed` is the position; keeping the elapsed part in an
/// [`Instant`] instead of accumulating tick deltas means a stalled or delayed
/// poll cannot lose time.
#[derive(Default)]
struct State {
    duration: Duration,
    /// Playhead at the moment the current run started.
    origin: Duration,
    /// `Some` exactly while playing.
    started_at: Option<Instant>,
    loaded: bool,
}

impl State {
    fn position(&self) -> Duration {
        let played = self.started_at.map(|at| at.elapsed()).unwrap_or_default();
        (self.origin + played).min(self.duration)
    }
}

/// Playback without a sound card.
///
/// Used when no output device can be opened, and by tests that must not depend
/// on audio hardware. Position, seeking and end-of-track behave exactly like the
/// real engine — there is simply no audio.
#[derive(Default)]
pub struct ClockEngine {
    state: Mutex<State>,
}

impl ClockEngine {
    /// Creates an engine with nothing loaded.
    pub fn new() -> Self {
        Self::default()
    }
}

impl AudioEngine for ClockEngine {
    fn load(&self, source: &AudioSource, position: Duration) -> Result<(), AudioError> {
        let duration = source.duration();
        let mut state = self.lock();
        state.duration = duration;
        state.origin = position.min(duration);
        state.started_at = None;
        state.loaded = true;
        Ok(())
    }

    fn play(&self) -> Result<(), AudioError> {
        let mut state = self.lock();
        let finished = state.position() >= state.duration;
        if state.loaded && state.started_at.is_none() && !finished {
            state.started_at = Some(Instant::now());
        }
        Ok(())
    }

    fn pause(&self) -> Result<(), AudioError> {
        let mut state = self.lock();
        let position = state.position();
        state.origin = position;
        state.started_at = None;
        Ok(())
    }

    fn stop(&self) -> Result<(), AudioError> {
        let mut state = self.lock();
        state.duration = Duration::ZERO;
        state.origin = Duration::ZERO;
        state.started_at = None;
        state.loaded = false;
        Ok(())
    }

    fn seek(&self, position: Duration) -> Result<(), AudioError> {
        let mut state = self.lock();
        let playing = state.started_at.is_some();
        state.origin = position.min(state.duration);
        state.started_at = if playing { Some(Instant::now()) } else { None };
        Ok(())
    }

    fn set_volume(&self, _volume: f32) {
        // No audio, so nothing to attenuate. The player still tracks the value
        // for the protocol.
    }

    fn position(&self) -> Duration {
        self.lock().position()
    }

    fn is_finished(&self) -> bool {
        let state = self.lock();
        state.loaded && state.position() >= state.duration
    }

    fn name(&self) -> &'static str {
        "clock"
    }
}

impl ClockEngine {
    /// The state lock is only ever held for a few instructions, so a poisoned
    /// mutex cannot leave the engine inconsistent; recover rather than panic.
    fn lock(&self) -> std::sync::MutexGuard<'_, State> {
        self.state
            .lock()
            .unwrap_or_else(std::sync::PoisonError::into_inner)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn source(duration_ms: u64) -> AudioSource {
        AudioSource::Silence {
            duration: Duration::from_millis(duration_ms),
        }
    }

    #[test]
    fn load_leaves_the_engine_paused() {
        let engine = ClockEngine::new();
        engine.load(&source(1_000), Duration::ZERO).unwrap();

        assert_eq!(engine.position(), Duration::ZERO);
        assert!(!engine.is_finished());
        assert_eq!(engine.name(), "clock");
    }

    #[test]
    fn loading_at_a_position_starts_there() {
        let engine = ClockEngine::new();
        engine
            .load(&source(10_000), Duration::from_millis(2_500))
            .unwrap();

        assert_eq!(engine.position(), Duration::from_millis(2_500));
    }

    #[test]
    fn play_advances_and_pause_freezes() {
        let engine = ClockEngine::new();
        engine.load(&source(10_000), Duration::ZERO).unwrap();
        engine.play().unwrap();
        std::thread::sleep(Duration::from_millis(25));

        let playing = engine.position();
        assert!(
            playing >= Duration::from_millis(15),
            "the playhead should have moved, got {playing:?}"
        );

        engine.pause().unwrap();
        // Read *after* pausing: the handful of microseconds between the read
        // above and `pause` may legitimately be included.
        let frozen = engine.position();
        assert!(
            frozen >= playing,
            "the playhead must not jump backwards when pausing"
        );

        std::thread::sleep(Duration::from_millis(25));
        assert_eq!(engine.position(), frozen, "a paused playhead must not move");
    }

    #[test]
    fn reaching_the_end_marks_the_track_finished() {
        let engine = ClockEngine::new();
        engine.load(&source(30), Duration::ZERO).unwrap();
        engine.play().unwrap();
        std::thread::sleep(Duration::from_millis(80));

        assert!(engine.is_finished());
        assert_eq!(
            engine.position(),
            Duration::from_millis(30),
            "the reported position is clamped to the duration"
        );
    }

    #[test]
    fn seek_clamps_to_the_duration_and_can_restart_a_finished_track() {
        let engine = ClockEngine::new();
        engine.load(&source(1_000), Duration::ZERO).unwrap();
        engine.play().unwrap();

        engine.seek(Duration::from_millis(5_000)).unwrap();
        assert_eq!(engine.position(), Duration::from_millis(1_000));

        engine.seek(Duration::ZERO).unwrap();
        assert!(!engine.is_finished());
    }

    #[test]
    fn stop_unloads_the_track() {
        let engine = ClockEngine::new();
        engine.load(&source(1_000), Duration::ZERO).unwrap();
        engine.play().unwrap();
        engine.stop().unwrap();

        assert_eq!(engine.position(), Duration::ZERO);
        assert!(!engine.is_finished());
    }
}

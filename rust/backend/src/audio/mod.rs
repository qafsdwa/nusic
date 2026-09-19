//! Audio playback abstraction.
//!
//! The control surface and the sound output are deliberately separate:
//!
//! - [`crate::player::PlayerHub`] owns the *control* state machine — queue,
//!   repeat, shuffle, playhead, and the REST/WebSocket protocol — and never
//!   touches a sound card;
//! - an [`AudioEngine`] turns "load this source, play, pause, seek" into sound.
//!
//! That seam is what lets the controller protocol be developed and unit-tested
//! on machines without audio hardware, and lets the playback backend be
//! replaced later without touching the protocol.
//!
//! Two engines ship here:
//!
//! - [`RodioEngine`] — real output through `rodio`/`cpal`;
//! - [`ClockEngine`] — no device; keeps a virtual playhead so the API still
//!   behaves correctly (and tests stay deterministic) where audio is
//!   unavailable.

mod clock;
mod rodio;

pub use clock::ClockEngine;
pub use rodio::RodioEngine;

use std::path::PathBuf;
use std::sync::Arc;
use std::time::Duration;

/// What an [`AudioEngine`] should play.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AudioSource {
    /// A file on disk, decoded with the engine's format support.
    File {
        /// Location of the file.
        path: PathBuf,
        /// Nominal duration, from catalog metadata.
        duration: Duration,
    },
    /// A silent placeholder of `duration`.
    ///
    /// The built-in seed catalog carries no audio files, but the protocol still
    /// needs a real, advancing timeline; a bounded silence source provides that
    /// without pretending a file exists.
    Silence {
        /// How long the placeholder lasts.
        duration: Duration,
    },
}

impl AudioSource {
    /// Nominal duration, taken from catalog metadata.
    pub fn duration(&self) -> Duration {
        match self {
            Self::File { duration, .. } | Self::Silence { duration } => *duration,
        }
    }
}

/// Why an engine could not carry out a request.
#[derive(Debug, thiserror::Error)]
pub enum AudioError {
    /// No output device could be opened.
    #[error("no audio output device is available: {0}")]
    DeviceUnavailable(String),
    /// The source file could not be opened.
    #[error("cannot open {path}: {message}")]
    Open {
        /// Path that failed.
        path: String,
        /// Underlying error.
        message: String,
    },
    /// The source could not be decoded.
    #[error("cannot decode {path}: {message}")]
    Decode {
        /// Path that failed.
        path: String,
        /// Underlying error.
        message: String,
    },
    /// The current source does not support seeking.
    #[error("the current source does not support seeking")]
    SeekUnsupported,
}

/// Playback backend.
///
/// Implementations are shared behind an `Arc` and are called while the player's
/// state mutex is held, so every method must return promptly.
///
/// [`AudioEngine::load`] is atomic with respect to the previous source: if the
/// new source cannot be prepared, the previously loaded source must keep
/// playing — the caller relies on that to reject a bad command without changing
/// playback.
pub trait AudioEngine: Send + Sync {
    /// Replaces the current source, positioned at `position`.
    ///
    /// Leaves the engine paused; callers start playback with
    /// [`AudioEngine::play`].
    fn load(&self, source: &AudioSource, position: Duration) -> Result<(), AudioError>;

    /// Resumes playback.
    fn play(&self) -> Result<(), AudioError>;

    /// Pauses playback, keeping the playhead.
    ///
    /// Not instantaneous on real hardware: the output callback may deliver a
    /// little more audio before it observes the pause, so the playhead can
    /// advance by up to one callback period (~5ms with `rodio`).
    fn pause(&self) -> Result<(), AudioError>;

    /// Stops playback and unloads the current source.
    fn stop(&self) -> Result<(), AudioError>;

    /// Moves the playhead.
    fn seek(&self, position: Duration) -> Result<(), AudioError>;

    /// Sets the output volume, in `0.0..=1.0`.
    fn set_volume(&self, volume: f32);

    /// Current playhead.
    fn position(&self) -> Duration;

    /// Whether the loaded source has been played to its end.
    fn is_finished(&self) -> bool;

    /// Short name for logs and diagnostics.
    fn name(&self) -> &'static str;
}

/// Opens the best available engine, falling back to [`ClockEngine`].
///
/// A headless machine (CI, a server without a sound card) must still serve the
/// REST/WebSocket API, so a missing device degrades to a virtual playhead
/// instead of failing startup.
pub fn open_default_engine() -> Arc<dyn AudioEngine> {
    match RodioEngine::open() {
        Ok(engine) => {
            tracing::info!(engine = engine.name(), "audio output ready");
            Arc::new(engine)
        }
        Err(error) => {
            tracing::warn!(
                %error,
                "no audio output available; using the silent clock engine \
                 (the API keeps working, but nothing is audible)"
            );
            Arc::new(ClockEngine::new())
        }
    }
}

//! Shared Rust <-> Dart data contract for the Muse Player bridge.
//!
//! Design rules:
//! - durations/positions use `i64` milliseconds, never `std::time::Duration`
//!   (FRB maps `Duration` to opaque/handle types, which is heavier than a value);
//! - nullable fields use `Option<T>`;
//! - commands and events are field-bearing enums so they map to Dart sealed
//!   classes instead of brittle stringly typed payloads;
//! - queues use `Vec<T>`; `HashMap` is avoided to keep generated Dart code
//!   simple and deterministic.
//!
//! These types are intentionally independent from the audio engine. The Rust
//! player implementation can translate them to/from rodio, symphonia, or a
//! future native engine while Flutter keeps talking to one stable contract.

use serde::{Deserialize, Serialize};

/// A track copied across the bridge.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct BridgeTrack {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub album: String,
    pub cover_url: Option<String>,
    /// Total duration in milliseconds.
    pub duration_ms: i64,
    pub source: BridgeTrackSource,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BridgeTrackSource {
    Local,
    Remote,
    Mock,
    Unknown,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BridgePlaybackStatus {
    Idle,
    Loading,
    Playing,
    Paused,
    Buffering,
    Error,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BridgeRepeatMode {
    Off,
    All,
    One,
}

/// Complete player snapshot.
///
/// This is the only "full state" payload. Position-only updates should use
/// `BridgePlayerEvent::PositionChanged` to avoid copying the whole queue at
/// every tick.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct BridgePlayerSnapshot {
    pub current_track: Option<BridgeTrack>,
    pub status: BridgePlaybackStatus,
    pub position_ms: i64,
    pub duration_ms: i64,
    pub volume: f64,
    pub is_shuffle: bool,
    pub repeat_mode: BridgeRepeatMode,
    pub queue: Vec<BridgeTrack>,
    pub current_index: i32,
    /// Unix epoch milliseconds when the Rust side produced this snapshot.
    pub updated_at_ms: i64,
}

/// Commands sent from Flutter to Rust.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum BridgePlayerCommand {
    Play {
        track_id: String,
    },
    PlayTrack {
        track: BridgeTrack,
    },
    PlayQueue {
        tracks: Vec<BridgeTrack>,
        start_index: i32,
    },
    Pause,
    Resume,
    Toggle,
    Next,
    Previous,
    Seek {
        position_ms: i64,
    },
    SetVolume {
        volume: f64,
    },
    SetShuffle {
        enabled: bool,
    },
    SetRepeat {
        mode: BridgeRepeatMode,
    },
    ClearQueue,
    RequestSnapshot,
}

/// Events streamed from Rust back to Flutter.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum BridgePlayerEvent {
    Snapshot {
        snapshot: BridgePlayerSnapshot,
    },
    PositionChanged {
        position_ms: i64,
        duration_ms: i64,
    },
    StatusChanged {
        status: BridgePlaybackStatus,
    },
    TrackChanged {
        track: BridgeTrack,
        index: i32,
    },
    QueueChanged {
        tracks: Vec<BridgeTrack>,
        current_index: i32,
    },
    VolumeChanged {
        volume: f64,
    },
    Error {
        error: BridgeError,
    },
}

/// Structured bridge error.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct BridgeError {
    pub code: BridgeErrorCode,
    pub message: String,
    pub details: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BridgeErrorCode {
    Unknown,
    NotInitialized,
    InvalidTrack,
    AudioOutput,
    Network,
    Decode,
    Unsupported,
    Cancelled,
}

/// Initialization config passed from Flutter.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct BridgeInitConfig {
    pub enable_network: bool,
    pub backend_base_url: Option<String>,
    pub cache_dir: Option<String>,
    pub default_volume: f64,
}

/// Generic result for commands that do not return a snapshot directly.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum BridgeResult {
    Ok,
    Error { error: BridgeError },
}

/// Lyric line reserved for Phase 2/3.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct BridgeLyricLine {
    pub start_ms: i64,
    pub text: String,
}

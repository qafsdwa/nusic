//! Wire types for the REST + WebSocket contract defined in `docs/backend-api.md`.
//!
//! These are deliberately flat projections of the richer FFI contract in
//! `rust/src/api/bridge_models.rs`. The FFI types cross an in-process boundary
//! and can afford to carry whole track objects on every event; the HTTP/WS
//! surface is tuned for small, cacheable JSON payloads, so it sends song ids in
//! the queue and only the fields the documented responses actually need.

use crate::api::bridge_models::BridgeTrack;
use serde::{Deserialize, Serialize};

use crate::error::ErrorBody;

/// A song as returned by `GET /songs/search`, `GET /songs/{id}` and
/// `GET /playlist`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Song {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub album: String,
    /// Absolute URL of the cover art served by `GET /covers/{id}.jpg`.
    pub cover: String,
    pub duration_ms: i64,
}

impl From<&BridgeTrack> for Song {
    fn from(track: &BridgeTrack) -> Self {
        Self {
            id: track.id.clone(),
            title: track.title.clone(),
            artist: track.artist.clone(),
            album: track.album.clone(),
            cover: track.cover_url.clone().unwrap_or_default(),
            duration_ms: track.duration_ms,
        }
    }
}

/// `GET /songs/search` response body.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SongListResponse {
    pub songs: Vec<Song>,
}

/// `GET /playlist` response body.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PlaylistResponse {
    pub id: String,
    pub title: String,
    pub songs: Vec<Song>,
}

/// `GET /health` response body.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct HealthResponse {
    pub status: &'static str,
    /// Active playback backend (`"rodio"` or `"clock"`).
    ///
    /// Reported here because "the API works but there is no sound" is the
    /// failure mode that is hardest to diagnose from the outside.
    pub engine: String,
}

/// Playback status, serialized lowercase (`"playing"`) as documented.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PlaybackStatus {
    Idle,
    Loading,
    Playing,
    Paused,
    Buffering,
    Error,
}

/// Repeat mode, serialized lowercase (`"off"` / `"all"` / `"one"`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum RepeatMode {
    Off,
    All,
    One,
}

/// The `state` payload pushed over `/ws/player`.
///
/// `song_id` / `status` / `position_ms` / `duration_ms` / `queue` are the fields
/// documented in `docs/backend-api.md`; `volume`, `is_shuffle`, `repeat_mode`
/// and `updated_at_ms` are additive so a client can restore the full player
/// without a second round trip.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PlayerState {
    pub song_id: Option<String>,
    pub status: PlaybackStatus,
    pub position_ms: i64,
    pub duration_ms: i64,
    /// Song ids in play order.
    pub queue: Vec<String>,
    pub volume: f64,
    pub is_shuffle: bool,
    pub repeat_mode: RepeatMode,
    /// Unix epoch milliseconds when the backend produced this state.
    pub updated_at_ms: i64,
}

/// Commands accepted over `/ws/player`.
///
/// `play` / `pause` / `next` / `seek` are the documented commands; the rest are
/// additive so the WebSocket can drive the whole player the way the Flutter UI
/// does.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum PlayerCommand {
    Play {
        song_id: String,
    },
    PlayQueue {
        song_ids: Vec<String>,
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
        mode: RepeatMode,
    },
    ClearQueue,
    RequestState,
}

/// Messages the server pushes to a `/ws/player` client.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ServerMessage {
    State(PlayerState),
    Error(ErrorBody),
}

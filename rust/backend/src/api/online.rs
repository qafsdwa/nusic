//! Bilibili online search and audio preparation, callable directly from Dart.
//!
//! The online layer is optional: [`status`] reports whether it could be built,
//! and both commands return a plain error message when it could not, so the app
//! can keep using the local library.

use crate::api::bridge_models::BridgeTrack;
use crate::runtime;

/// Health of the online layer, so the UI can explain what is missing.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BridgeOnlineStatus {
    /// Whether the Bilibili client and its runtime could be created.
    pub available: bool,
    /// Whether a cookie was supplied through the environment.
    ///
    /// Anonymous access still reaches the standard audio tracks; a cookie only
    /// unlocks the higher tiers.
    pub authenticated: bool,
    /// Where resolved audio is cached, once the layer is available.
    pub cache_dir: Option<String>,
    /// Why the layer is unavailable, when it is.
    pub error: Option<String>,
}

/// Reports whether online search can be used.
///
/// Building the layer here is what makes the first search fast, and it is cheap:
/// it only constructs an HTTP client and a small runtime.
pub fn status() -> BridgeOnlineStatus {
    let Ok(runtime) = runtime::current() else {
        return BridgeOnlineStatus {
            available: false,
            authenticated: false,
            cache_dir: None,
            error: Some("rust runtime is not initialised; call init() first".to_owned()),
        };
    };

    match runtime.online() {
        Ok(online) => BridgeOnlineStatus {
            available: true,
            authenticated: online.is_authenticated(),
            cache_dir: Some(online.cache_dir().display().to_string()),
            error: None,
        },
        Err(error) => BridgeOnlineStatus {
            available: false,
            authenticated: false,
            cache_dir: None,
            error: Some(error),
        },
    }
}

/// Searches Bilibili videos and registers the hits with the catalog.
///
/// Registering is what lets the player resolve a search result by id, so the
/// two calls cannot be split without breaking playback.
pub fn search_videos(query: String, page: u32) -> Result<Vec<BridgeTrack>, String> {
    let runtime = runtime::current()?;
    let tracks = runtime.online()?.search_videos(&query, page)?;
    runtime.library.register_online(tracks.clone());
    Ok(tracks)
}

/// Resolves a search result to a playable file, downloading it if needed.
///
/// The returned track carries the authoritative duration, title and cover from
/// the video detail endpoint, which can differ from the search hit. Call it
/// before sending `Play` for an online track.
pub fn prepare_track(track_id: String) -> Result<BridgeTrack, String> {
    let runtime = runtime::current()?;
    let (track, file) = runtime.online()?.prepare(&track_id)?;
    runtime.library.register_online_file(track.clone(), file);
    Ok(track)
}

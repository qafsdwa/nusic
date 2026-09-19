//! Library queries, callable directly from Dart.

use crate::api::bridge_models::BridgeTrack;
use crate::runtime;

/// Case-insensitive search over title, artist and album.
///
/// An empty query returns the whole catalog, which is how the search page
/// populates itself before the user types.
pub fn search_songs(query: String) -> Result<Vec<BridgeTrack>, String> {
    Ok(runtime::current()?.library.search_tracks(&query))
}

/// Every track in the catalog, in playlist order.
pub fn playlist() -> Result<Vec<BridgeTrack>, String> {
    Ok(runtime::current()?.library.tracks().to_vec())
}

/// Name of the active playback backend (`rodio` or `clock`).
pub fn engine_name() -> Result<String, String> {
    Ok(runtime::current()?.player.engine_name().to_owned())
}

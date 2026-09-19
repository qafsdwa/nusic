//! HTTP and WebSocket surface.
//!
//! Route handlers stay thin: they translate between the wire types in
//! [`crate::models`] and the domain types ([`crate::library::Library`],
//! [`crate::player::PlayerHub`]) without holding state of their own.

pub mod health;
pub mod player_ws;
pub mod songs;

use std::sync::Arc;

use axum::routing::get;
use axum::Router;
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;

use crate::config::Config;
use crate::cover::CoverCache;
use crate::library::Library;
use crate::player::PlayerHub;

/// Everything a handler needs, cloned per request.
///
/// The inner values are all `Arc`s or cheap handles, so cloning the state is a
/// handful of refcount bumps rather than a deep copy.
#[derive(Clone)]
pub struct AppState {
    pub library: Arc<Library>,
    pub player: Arc<PlayerHub>,
    pub covers: Arc<CoverCache>,
    /// Base URL used to build absolute cover links.
    pub public_base_url: Arc<String>,
}

impl AppState {
    pub fn new(config: &Config, library: Arc<Library>, player: Arc<PlayerHub>) -> Self {
        Self {
            library,
            player,
            covers: Arc::new(CoverCache::default()),
            public_base_url: Arc::new(config.public_base_url.clone()),
        }
    }
}

/// Builds the router described in `docs/backend-api.md`.
pub fn router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(health::health))
        .route("/songs/search", get(songs::search))
        // Registered after `/songs/search` on purpose: axum matches static
        // segments before `{id}` parameters, so "search" is never read as an id.
        .route("/songs/{id}", get(songs::detail))
        .route("/playlist", get(songs::playlist))
        .route("/covers/{name}", get(songs::cover))
        .route("/ws/player", get(player_ws::upgrade))
        // The Flutter client runs on desktop, mobile and web; during local
        // development its origin varies (or is absent for native builds), so
        // permissive CORS is the pragmatic default for a loopback-only server.
        .layer(CorsLayer::permissive())
        .layer(TraceLayer::new_for_http())
        .with_state(state)
}

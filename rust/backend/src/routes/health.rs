//! `GET /health` — liveness probe.

use axum::extract::State;
use axum::Json;

use crate::models::HealthResponse;
use crate::routes::AppState;

/// Returns `{"status":"ok"}`.
///
/// Exists so the Flutter side (and any launcher script) can wait for the server
/// to accept connections before opening the WebSocket.
pub async fn health(State(state): State<AppState>) -> Json<HealthResponse> {
    // Touching the library proves the state is wired without exposing it.
    tracing::trace!(songs = state.library.tracks().len(), "health check");
    Json(HealthResponse {
        status: "ok",
        engine: state.player.engine_name().to_owned(),
    })
}

//! REST endpoints: search, single-song detail, playlist and cover art.

use axum::body::Bytes;
use axum::extract::{Path, Query, State};
use axum::http::{header, HeaderValue};
use axum::response::{IntoResponse, Response};
use axum::Json;
use serde::Deserialize;

use crate::error::ApiError;
use crate::models::{PlaylistResponse, Song, SongListResponse};
use crate::routes::AppState;

/// Query string of `GET /songs/search`.
#[derive(Debug, Deserialize)]
pub struct SearchQuery {
    /// Search keyword matched against title, artist and album.
    #[serde(default)]
    pub q: String,
}

/// `GET /songs/search?q={keyword}`.
///
/// A missing `q` is treated as an empty query, which returns the whole catalog
/// rather than an error: the client can then browse without a separate route.
pub async fn search(
    State(state): State<AppState>,
    Query(query): Query<SearchQuery>,
) -> Json<SongListResponse> {
    let songs = state.library.search(&query.q);
    tracing::debug!(query = %query.q, matches = songs.len(), "song search");
    Json(SongListResponse { songs })
}

/// `GET /songs/{id}`.
///
/// Returns `404` with an [`crate::error::ErrorBody`] when the id is unknown.
pub async fn detail(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<Song>, ApiError> {
    state
        .library
        .song(&id)
        .map(Json)
        .ok_or_else(|| ApiError::not_found(format!("song not found: {id}")))
}

/// `GET /playlist`.
pub async fn playlist(State(state): State<AppState>) -> Json<PlaylistResponse> {
    Json(state.library.playlist())
}

/// `GET /covers/{name}` — generated cover art for a song.
///
/// `name` is documented as `{id}.jpg`, but the suffix is optional so a client
/// that stores the raw id still resolves.
pub async fn cover(State(state): State<AppState>, Path(name): Path<String>) -> Response {
    let Some(track) = state.library.track_by_cover_name(&name) else {
        return ApiError::not_found(format!("cover not found: {name}")).into_response();
    };

    let bytes = state.covers.get_or_render(&track.id);
    if bytes.is_empty() {
        return ApiError::new(
            axum::http::StatusCode::INTERNAL_SERVER_ERROR,
            "cover_render_failed",
            "failed to encode the generated cover",
        )
        .into_response();
    }

    // `Bytes` needs an owned buffer, and the cache hands out a shared slice;
    // copying one cover is cheaper than re-encoding it.
    let mut response = Response::new(Bytes::copy_from_slice(&bytes).into());
    response
        .headers_mut()
        .insert(header::CONTENT_TYPE, HeaderValue::from_static("image/jpeg"));
    // Covers are pure functions of the song id, so they can be cached
    // aggressively; `immutable` tells the client not to revalidate.
    response.headers_mut().insert(
        header::CACHE_CONTROL,
        HeaderValue::from_static("public, max-age=31536000, immutable"),
    );
    response
}

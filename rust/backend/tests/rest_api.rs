//! Integration tests for the REST endpoints in `docs/backend-api.md`.

mod common;

use common::TestServer;
use serde_json::json;

#[tokio::test]
async fn health_reports_ok() {
    let server = TestServer::seeded().await;
    let response = server.get("/health").await;

    assert_eq!(response.status, 200);
    let body = response.json();
    assert_eq!(body["status"], "ok");
    // The tests run on the silent engine; the field exists to make a missing
    // sound card diagnosable over HTTP.
    assert_eq!(body["engine"], "clock");
}

#[tokio::test]
async fn search_returns_the_documented_shape() {
    let server = TestServer::seeded().await;
    let response = server.get("/songs/search?q=midnight").await;

    assert_eq!(response.status, 200);
    let body = response.json();
    let songs = body["songs"].as_array().expect("songs array");
    assert_eq!(songs.len(), 1);
    assert_eq!(
        songs[0],
        json!({
            "id": "song_001",
            "title": "Midnight Drive",
            "artist": "Google Material Orchestra",
            "album": "Synthetic Waves",
            "cover": format!("{}/covers/song_001.jpg", server.base_url),
            "duration_ms": 252000,
        })
    );
}

#[tokio::test]
async fn search_matches_artist_and_album_too() {
    let server = TestServer::seeded().await;

    let by_artist = server.get("/songs/search?q=周杰伦").await.json();
    assert_eq!(by_artist["songs"][0]["id"], "song_004");

    let by_album = server.get("/songs/search?q=X%26Y").await.json();
    assert_eq!(by_album["songs"][0]["id"], "song_006");
}

#[tokio::test]
async fn search_without_a_query_returns_everything() {
    let server = TestServer::seeded().await;
    let response = server.get("/songs/search").await;

    assert_eq!(response.status, 200);
    assert_eq!(response.json()["songs"].as_array().unwrap().len(), 6);
}

#[tokio::test]
async fn search_with_no_matches_returns_an_empty_list() {
    let server = TestServer::seeded().await;
    let response = server.get("/songs/search?q=definitely-not-a-song").await;

    assert_eq!(response.status, 200);
    assert_eq!(response.json(), json!({ "songs": [] }));
}

#[tokio::test]
async fn song_detail_returns_the_same_shape_as_search() {
    let server = TestServer::seeded().await;
    let detail = server.get("/songs/song_002").await;
    let search = server.get("/songs/search?q=%E5%86%AC%E6%97%A5").await;

    assert_eq!(detail.status, 200);
    assert_eq!(detail.json(), search.json()["songs"][0]);
    assert_eq!(detail.json()["title"], "冬日挽歌");
}

#[tokio::test]
async fn song_detail_returns_404_for_an_unknown_id() {
    let server = TestServer::seeded().await;
    let response = server.get("/songs/does_not_exist").await;

    assert_eq!(response.status, 404);
    let body = response.json();
    assert_eq!(body["code"], "not_found");
    assert!(body["message"].as_str().unwrap().contains("does_not_exist"));
}

#[tokio::test]
async fn search_route_is_not_shadowed_by_the_id_route() {
    // `/songs/search` and `/songs/{id}` overlap; axum must prefer the static
    // segment, otherwise search would 404 as an unknown song id.
    let server = TestServer::seeded().await;
    let response = server.get("/songs/search?q=lemon").await;

    assert_eq!(response.status, 200);
    assert_eq!(response.json()["songs"][0]["id"], "song_003");
}

#[tokio::test]
async fn playlist_returns_id_title_and_songs() {
    let server = TestServer::seeded().await;
    let response = server.get("/playlist").await;

    assert_eq!(response.status, 200);
    let body = response.json();
    assert_eq!(body["id"], "playlist_default");
    assert_eq!(body["title"], "默认列表");
    assert_eq!(body["songs"].as_array().unwrap().len(), 6);
    assert_eq!(body["songs"][0]["id"], "song_001");
}

#[tokio::test]
async fn cover_returns_a_cacheable_jpeg() {
    let server = TestServer::seeded().await;
    let response = server.get("/covers/song_001.jpg").await;

    assert_eq!(response.status, 200);
    assert_eq!(response.header("content-type"), Some("image/jpeg"));
    assert!(response
        .header("cache-control")
        .unwrap()
        .contains("immutable"));
    // JPEG magic number.
    assert_eq!(&response.body[..2], &[0xFF, 0xD8]);
}

#[tokio::test]
async fn covers_are_stable_across_requests() {
    let server = TestServer::seeded().await;
    let first = server.get("/covers/song_003.jpg").await;
    let second = server.get("/covers/song_003.jpg").await;

    assert_eq!(first.body, second.body, "cover bytes must be deterministic");
}

#[tokio::test]
async fn different_songs_get_different_covers() {
    let server = TestServer::seeded().await;
    let first = server.get("/covers/song_001.jpg").await;
    let second = server.get("/covers/song_002.jpg").await;

    assert_ne!(first.body, second.body);
}

#[tokio::test]
async fn unknown_cover_returns_404() {
    let server = TestServer::seeded().await;
    let response = server.get("/covers/not_a_song.jpg").await;

    assert_eq!(response.status, 404);
    assert_eq!(response.json()["code"], "not_found");
}

#[tokio::test]
async fn unknown_route_returns_404() {
    let server = TestServer::seeded().await;
    assert_eq!(server.get("/nope").await.status, 404);
}

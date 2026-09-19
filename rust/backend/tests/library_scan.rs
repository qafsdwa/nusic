//! Integration tests for scanning a real music directory.
//!
//! Fixtures are generated WAV files rather than checked-in binaries: the scan
//! path is what matters, and a generated file keeps the repository free of
//! audio assets that would otherwise need a license.

mod common;

use std::fs;
use std::path::Path;

use common::TestServer;
use serde_json::json;

/// Writes a silent WAV of `seconds` length, with a `lofty`-readable title tag.
///
/// `hound` writes plain PCM WAV, which has no tag chunk support, so the title
/// comes from the file name instead — exactly the fallback the scanner is
/// documented to use.
fn write_wav(path: &Path, seconds: u32) {
    let spec = hound::WavSpec {
        channels: 1,
        sample_rate: 44_100,
        bits_per_sample: 16,
        sample_format: hound::SampleFormat::Int,
    };

    let mut writer = hound::WavWriter::create(path, spec).expect("create wav");
    for _ in 0..(44_100 * seconds) {
        writer.write_sample(0i16).expect("write sample");
    }
    writer.finalize().expect("finalize wav");
}

#[tokio::test]
async fn scans_audio_files_from_a_directory() {
    let dir = tempfile::tempdir().expect("temp dir");
    write_wav(&dir.path().join("Alpha.wav"), 1);
    write_wav(&dir.path().join("Beta.wav"), 2);
    // Non-audio files must be ignored rather than read as tracks.
    fs::write(dir.path().join("notes.txt"), "not audio").expect("write txt");
    fs::create_dir(dir.path().join("nested")).expect("nested dir");
    write_wav(&dir.path().join("nested/Gamma.wav"), 1);

    let server = TestServer::with_music_dir(dir.path()).await;
    let response = server.get("/songs/search").await;

    assert_eq!(response.status, 200);
    let songs = response.json()["songs"].as_array().unwrap().clone();
    assert_eq!(songs.len(), 3, "txt and directories must be skipped");

    // Titles fall back to file names, and nested files are found too.
    let mut titles: Vec<&str> = songs
        .iter()
        .map(|song| song["title"].as_str().unwrap())
        .collect();
    titles.sort();
    assert_eq!(titles, vec!["Alpha", "Beta", "Gamma"]);
}

#[tokio::test]
async fn scanned_duration_reflects_the_file() {
    let dir = tempfile::tempdir().expect("temp dir");
    write_wav(&dir.path().join("TwoSeconds.wav"), 2);

    let server = TestServer::with_music_dir(dir.path()).await;
    let response = server.get("/songs/search").await;
    let song = &response.json()["songs"][0];

    // 2 seconds of audio; allow a little slack for frame-exact duration.
    let duration_ms = song["duration_ms"].as_i64().unwrap();
    assert!(
        (1900..=2100).contains(&duration_ms),
        "expected ~2000ms, got {duration_ms}"
    );
}

#[tokio::test]
async fn scanned_songs_get_stable_ids_and_cover_urls() {
    let dir = tempfile::tempdir().expect("temp dir");
    write_wav(&dir.path().join("Stable.wav"), 1);

    let first = TestServer::with_music_dir(dir.path()).await;
    let first_song = first.get("/songs/search").await.json()["songs"][0].clone();

    // A second scan of the same directory must produce the same id, otherwise
    // the id could not be used as a stable URL path segment.
    let second = TestServer::with_music_dir(dir.path()).await;
    let second_song = second.get("/songs/search").await.json()["songs"][0].clone();

    assert_eq!(first_song["id"], second_song["id"]);
    assert!(first_song["id"].as_str().unwrap().starts_with("local_"));

    let id = first_song["id"].as_str().unwrap();
    assert_eq!(
        first_song["cover"],
        format!("{}/covers/{id}.jpg", first.base_url)
    );

    // The cover advertised in the payload must actually resolve.
    let cover = first.get(&format!("/covers/{id}.jpg")).await;
    assert_eq!(cover.status, 200);
    assert_eq!(&cover.body[..2], &[0xFF, 0xD8]);
}

#[tokio::test]
async fn scanned_song_detail_is_reachable_by_its_id() {
    let dir = tempfile::tempdir().expect("temp dir");
    write_wav(&dir.path().join("Reachable.wav"), 1);

    let server = TestServer::with_music_dir(dir.path()).await;
    let id = server.get("/songs/search").await.json()["songs"][0]["id"]
        .as_str()
        .unwrap()
        .to_owned();

    let detail = server.get(&format!("/songs/{id}")).await;
    assert_eq!(detail.status, 200);
    assert_eq!(detail.json()["title"], "Reachable");
}

#[tokio::test]
async fn empty_directory_falls_back_to_the_seed_catalog() {
    let dir = tempfile::tempdir().expect("temp dir");
    fs::write(dir.path().join("readme.txt"), "no audio here").expect("write txt");

    let server = TestServer::with_music_dir(dir.path()).await;
    let response = server.get("/songs/search").await;

    assert_eq!(response.status, 200);
    // A directory with nothing playable should not leave the client with an
    // empty app, so the documented seed catalog takes over.
    assert_eq!(response.json()["songs"].as_array().unwrap().len(), 6);
}

#[tokio::test]
async fn missing_directory_falls_back_to_the_seed_catalog() {
    let server = TestServer::with_music_dir(Path::new("/definitely/not/here")).await;
    let response = server.get("/songs/search").await;

    assert_eq!(response.status, 200);
    assert_eq!(response.json()["songs"].as_array().unwrap().len(), 6);
}

#[tokio::test]
async fn playlist_reflects_the_scanned_catalog() {
    let dir = tempfile::tempdir().expect("temp dir");
    write_wav(&dir.path().join("Only.wav"), 1);

    let server = TestServer::with_music_dir(dir.path()).await;
    let response = server.get("/playlist").await;

    assert_eq!(response.status, 200);
    assert_eq!(response.json()["songs"].as_array().unwrap().len(), 1);
    assert_eq!(response.json()["id"], "playlist_default");
}

#[tokio::test]
async fn player_queue_is_seeded_from_the_scanned_catalog() {
    let dir = tempfile::tempdir().expect("temp dir");
    write_wav(&dir.path().join("One.wav"), 1);
    write_wav(&dir.path().join("Two.wav"), 1);

    let server = TestServer::with_music_dir(dir.path()).await;
    let ids = server.library.ids();
    assert_eq!(ids.len(), 2);

    // The queue the WebSocket reports must match the scanned catalog.
    assert_eq!(
        server.get("/playlist").await.json()["songs"]
            .as_array()
            .unwrap()
            .len(),
        2
    );
}

#[tokio::test]
async fn scan_is_sorted_by_id_for_a_deterministic_order() {
    let dir = tempfile::tempdir().expect("temp dir");
    for name in ["Zeta", "Alpha", "Mu"] {
        write_wav(&dir.path().join(format!("{name}.wav")), 1);
    }

    let server = TestServer::with_music_dir(dir.path()).await;
    let ids = server.library.ids();

    let mut sorted = ids.clone();
    sorted.sort();
    assert_eq!(ids, sorted, "catalog order must be deterministic");

    // `/playlist` uses the same order as the queue.
    let playlist_ids: Vec<String> = server.get("/playlist").await.json()["songs"]
        .as_array()
        .unwrap()
        .iter()
        .map(|song| song["id"].as_str().unwrap().to_owned())
        .collect();
    assert_eq!(playlist_ids, ids);
}

#[tokio::test]
async fn cover_and_song_payload_agree_on_ids() {
    let dir = tempfile::tempdir().expect("temp dir");
    write_wav(&dir.path().join("Agree.wav"), 1);

    let server = TestServer::with_music_dir(dir.path()).await;
    let body = server.get("/songs/search").await.json();
    let song = &body["songs"][0];

    assert_eq!(song["artist"], json!(""));
    assert_eq!(song["album"], json!(""));
    let id = song["id"].as_str().unwrap();
    assert!(song["cover"]
        .as_str()
        .unwrap()
        .ends_with(&format!("{id}.jpg")));
}

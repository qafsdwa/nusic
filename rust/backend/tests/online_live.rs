//! Live smoke test for the Bilibili online layer.
//!
//! Ignored by default because it needs the network and downloads a real audio
//! track, which makes it unsuitable for the normal `cargo test` run. Run it
//! explicitly after touching `online.rs`:
//!
//! ```bash
//! MUSE_CACHE_DIR=/tmp/muse-online-test \
//!   cargo test --test online_live -- --ignored --nocapture
//! ```
//!
//! It asserts the things a unit test cannot: that Bilibili answers, that the
//! DASH audio track resolves for a real video, that the downloaded bytes are an
//! actual MP4/AAC stream, and that the cached and freshly resolved paths agree on
//! the duration.

use muse_backend::api::bridge_models::BridgeTrackSource;
use muse_backend::online::OnlineService;

#[test]
#[ignore = "hits the live Bilibili API and downloads an audio track"]
fn search_resolves_and_downloads_a_real_audio_track() {
    let service = OnlineService::open().expect("the online layer builds");

    let tracks = service
        .search_videos("rust 教程", 1)
        .expect("search should answer");
    assert!(!tracks.is_empty(), "the search should return hits");

    let first = tracks.first().expect("a first hit");
    assert!(first.id.starts_with("bili_"), "id was {}", first.id);
    assert!(!first.title.trim().is_empty());
    assert_eq!(first.source, BridgeTrackSource::Remote);
    println!(
        "hit: {} | {} | search says {}ms",
        first.id, first.title, first.duration_ms
    );

    let (track, file) = service
        .prepare(&first.id)
        .expect("the DASH audio track should resolve and download");

    assert!(file.is_file(), "{} should exist", file.display());
    assert!(track.duration_ms > 0, "the stream knows its length");
    assert_eq!(track.id, first.id);
    println!("resolved: {}ms -> {}", track.duration_ms, file.display());

    let bytes = std::fs::read(&file).expect("the cached file is readable");
    assert!(
        bytes.len() > 16 * 1024,
        "a real audio track is not {} bytes",
        bytes.len()
    );
    // MP4 containers open with a `ftyp` box; the DASH audio track is MP4/AAC.
    assert_eq!(&bytes[4..8], b"ftyp", "the download is not an MP4 container");

    // A second call is served from the cache: same path, and the same length.
    // This is the case that used to leak the search hit's duration through, which
    // for a multi-part course describes the whole series rather than this part.
    let (cached, again) = service.prepare(&first.id).expect("cached prepare");
    assert_eq!(again, file);
    assert_eq!(
        cached.duration_ms, track.duration_ms,
        "the cached path must agree with the resolved one"
    );
}

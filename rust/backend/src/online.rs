//! Bilibili online layer built on [`bpi_rs`].
//!
//! The app plays *audio*, so the online path is deliberately narrow:
//!
//! 1. [`OnlineService::search_videos`] runs a keyword search and projects the
//!    results onto [`BridgeTrack`], which is the same type the local catalog and
//!    the Dart side already use;
//! 2. [`OnlineService::prepare`] reads the video's `cid`, asks for the DASH
//!    playback info, picks the best audio track and downloads it into the cache;
//! 3. the cached file is then handed to the existing player exactly like a local
//!    file, so the state machine, the engine and the bridge need no new source
//!    kind.
//!
//! Everything here is anonymous-first: without a cookie Bilibili still serves
//! the standard audio tracks. A cookie only unlocks the higher tiers, and is
//! read from the environment rather than stored by the app.
//!
//! Network calls are driven by a private tokio runtime and exposed as blocking
//! methods, because the FFI surface that calls them is synchronous. Callers are
//! `flutter_rust_bridge` worker threads, never the Dart UI isolate.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, RwLock};

use bpi_rs::ids::Bvid;
use bpi_rs::search::{SearchVideoParams, Video};
use bpi_rs::video::videostream_url::{DashInfo, DashStream};
use bpi_rs::video::{VideoPlayUrlParams, VideoViewParams};
use bpi_rs::BpiClient;
use lofty::prelude::AudioFile;
use tokio::io::AsyncWriteExt;

use crate::api::bridge_models::{BridgeTrack, BridgeTrackSource};

/// Marks a track id as coming from the online catalog.
const ONLINE_ID_PREFIX: &str = "bili_";
/// Cookie environment variables, in priority order.
const COOKIE_ENV: &[&str] = &["MUSE_BILI_COOKIE", "BPI_COOKIE"];
/// Overrides the cache directory.
const CACHE_ENV: &str = "MUSE_CACHE_DIR";
/// Container of the cached audio. Bilibili's DASH audio is MP4/AAC.
const CACHE_EXTENSION: &str = "m4a";
/// `fnval` bit 16 is DASH, which is what makes the response carry `dash`.
/// 64/128 additionally ask for the 720P/1080P video renditions; they are free
/// to include and do not change the audio tracks that come back.
const FNVAL_DASH: u64 = 16 | 64 | 128;
/// Requested video quality. Audio quality does not depend on it, so this only
/// has to be a value the endpoint accepts.
const REQUESTED_QN: u64 = 80;

/// Bilibili search and stream resolution.
pub struct OnlineService {
    client: Arc<BpiClient>,
    /// Private runtime: the FFI surface is synchronous, and `block_on` is only
    /// legal outside a runtime context, which FRB worker threads provide.
    runtime: tokio::runtime::Runtime,
    cache_dir: PathBuf,
    /// Metadata for every track seen this session, so `prepare` can return the
    /// catalog fields (cover, album) alongside the resolved audio.
    known: RwLock<HashMap<String, BridgeTrack>>,
    /// One lock per track being prepared.
    ///
    /// Two callers racing on the same track would otherwise stream into the same
    /// part file and corrupt it, and the Dart side cannot be the only guard: the
    /// FFI surface is callable from anywhere.
    locks: Mutex<HashMap<String, Arc<Mutex<()>>>>,
    /// Whether a cookie was configured. Surfaces in the UI as "logged in".
    authenticated: bool,
}

impl OnlineService {
    /// Builds the client and the runtime.
    ///
    /// Fails only when the HTTP client or the runtime cannot be created, which
    /// the caller reports instead of taking down the whole app: online search is
    /// an addition to the local library, not a prerequisite for it.
    pub fn open() -> Result<Self, String> {
        let cookie = cookie_from_env();
        let authenticated = cookie.is_some();

        let mut builder = BpiClient::builder();
        if let Some(cookie) = cookie {
            builder = builder.cookie(cookie);
        }
        let client = builder.build().map_err(|error| error.to_string())?;

        let runtime = tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .enable_all()
            .thread_name("muse-online")
            .build()
            .map_err(|error| format!("cannot start the online runtime: {error}"))?;

        let cache_dir = cache_dir();
        std::fs::create_dir_all(&cache_dir)
            .map_err(|error| format!("cannot create {}: {error}", cache_dir.display()))?;

        Ok(Self {
            client: Arc::new(client),
            runtime,
            cache_dir,
            known: RwLock::new(HashMap::new()),
            locks: Mutex::new(HashMap::new()),
            authenticated,
        })
    }

    /// Whether a cookie was supplied through the environment.
    pub fn is_authenticated(&self) -> bool {
        self.authenticated
    }

    /// Where resolved audio is cached.
    pub fn cache_dir(&self) -> &Path {
        &self.cache_dir
    }

    /// Searches videos and projects the hits onto the shared track contract.
    ///
    /// Hits without a `bvid` (paid courses and similar entries) are dropped:
    /// they cannot be resolved into a stream, so showing them would only produce
    /// a dead row in the UI.
    pub fn search_videos(&self, query: &str, page: u32) -> Result<Vec<BridgeTrack>, String> {
        let params = SearchVideoParams::new(query)
            .map_err(|error| error.to_string())?
            .with_page(page.max(1))
            .map_err(|error| error.to_string())?;

        let data = self
            .runtime
            .block_on(self.client.search().video(params))
            .map_err(|error| error.to_string())?;

        let tracks: Vec<BridgeTrack> = data
            .result
            .unwrap_or_default()
            .iter()
            .filter_map(video_to_track)
            .collect();

        // Remember the metadata now so `prepare` does not have to search again.
        let mut known = self.known.write().unwrap();
        for track in &tracks {
            known.insert(track.id.clone(), track.clone());
        }

        Ok(tracks)
    }

    /// Resolves `track_id` to a playable audio file, downloading it if needed.
    ///
    /// The returned path is stable per track, so a second call is served from
    /// the cache without touching the network. Concurrent calls for the same
    /// track wait for the first one instead of streaming into the same file.
    ///
    /// For a multi-part video this resolves the default part (`view.cid`), which
    /// is what Bilibili treats as "the" video.
    pub fn prepare(&self, track_id: &str) -> Result<(BridgeTrack, PathBuf), String> {
        let raw_bvid = bvid_from_track_id(track_id)
            .ok_or_else(|| format!("not an online track id: {track_id}"))?;
        let bvid = Bvid::new(raw_bvid).map_err(|error| error.to_string())?;

        let destination = self
            .cache_dir
            .join(format!("{track_id}.{CACHE_EXTENSION}"));

        let lock = self.track_lock(track_id);
        let _guard = lock.lock().unwrap_or_else(|poisoned| poisoned.into_inner());

        let resolved = match destination.is_file() {
            // Already downloaded in an earlier run.
            true => None,
            false => Some(self.resolve(bvid)?),
        };

        if let Some(resolved) = &resolved {
            self.download(&resolved.url, &destination)?;
        }

        let mut track = self.known_track(track_id);
        match &resolved {
            Some(resolved) => {
                if !resolved.title.is_empty() {
                    track.title = resolved.title.clone();
                }
                if !resolved.author.is_empty() {
                    track.artist = resolved.author.clone();
                }
                if let Some(cover) = &resolved.cover {
                    track.cover_url = Some(cover.clone());
                }
                if resolved.duration_ms > 0 {
                    track.duration_ms = resolved.duration_ms;
                }
            }
            // Served from the cache, so this process may never have seen the
            // video: the file itself is the only trustworthy length. A
            // multi-part course reports the whole series in search, while the
            // download is a single part.
            None => {
                if let Some(duration_ms) = cached_duration_ms(&destination) {
                    track.duration_ms = duration_ms;
                }
            }
        }
        track.source = BridgeTrackSource::Remote;
        self.known
            .write()
            .unwrap()
            .insert(track_id.to_owned(), track.clone());

        Ok((track, destination))
    }

    /// Reads the video detail and picks the best available audio stream.
    fn resolve(&self, bvid: Bvid) -> Result<ResolvedAudio, String> {
        self.runtime.block_on(async {
            let view = self
                .client
                .video()
                .view(VideoViewParams::from_bvid(bvid.clone()))
                .await
                .map_err(|error| error.to_string())?;

            let play = self
                .client
                .video()
                .play_url(
                    VideoPlayUrlParams::from_bvid(bvid, view.cid)
                        .quality(REQUESTED_QN)
                        .format_flags(FNVAL_DASH)
                        .fourk(true),
                )
                .await
                .map_err(|error| error.to_string())?;

            let stream = pick_audio_stream(play.dash.as_ref())
                .ok_or_else(|| "this video exposes no DASH audio stream".to_owned())?;

            Ok(ResolvedAudio {
                url: stream.base_url.clone(),
                // `timelength` is the length of the stream that was requested,
                // in milliseconds. `dash.duration` repeats it in seconds and is
                // only a fallback for the (unseen) case where it is missing.
                duration_ms: match play.timelength {
                    0 => play.dash.as_ref().map_or(0, |dash| dash.duration * 1_000) as i64,
                    value => value as i64,
                },
                title: view.title,
                author: view.owner.name,
                cover: normalize_cover(&view.pic),
            })
        })
    }

    /// Streams `url` into `destination`, replacing it atomically.
    ///
    /// The body is written chunk by chunk rather than buffered whole: a long
    /// video's audio track can be well over a hundred megabytes.
    fn download(&self, url: &str, destination: &Path) -> Result<(), String> {
        self.runtime.block_on(async {
            let mut response = self
                .client
                .get(url)
                .send()
                .await
                .map_err(|error| format!("stream request failed: {error}"))?;

            let status = response.status();
            if !status.is_success() {
                return Err(format!("stream request failed: HTTP {status}"));
            }

            // Downloading into a sibling file keeps `destination` from ever
            // holding a truncated stream if the process dies mid-transfer.
            let temporary = destination.with_extension(format!("{CACHE_EXTENSION}.part"));
            let mut file = tokio::fs::File::create(&temporary)
                .await
                .map_err(|error| format!("cannot create {}: {error}", temporary.display()))?;

            let mut written: u64 = 0;
            while let Some(chunk) = response
                .chunk()
                .await
                .map_err(|error| format!("stream read failed: {error}"))?
            {
                file.write_all(&chunk)
                    .await
                    .map_err(|error| format!("cannot write {}: {error}", temporary.display()))?;
                written += chunk.len() as u64;
            }
            file.flush()
                .await
                .map_err(|error| format!("cannot flush {}: {error}", temporary.display()))?;
            drop(file);

            if written == 0 {
                let _ = tokio::fs::remove_file(&temporary).await;
                return Err("stream returned no data".to_owned());
            }

            tokio::fs::rename(&temporary, destination)
                .await
                .map_err(|error| format!("cannot finalise {}: {error}", destination.display()))
        })
    }

    /// The lock guarding `track_id`'s download, created on first use.
    fn track_lock(&self, track_id: &str) -> Arc<Mutex<()>> {
        Arc::clone(
            self.locks
                .lock()
                .unwrap()
                .entry(track_id.to_owned())
                .or_default(),
        )
    }

    /// Metadata for `track_id`, or a placeholder when it was never searched.
    fn known_track(&self, track_id: &str) -> BridgeTrack {
        self.known
            .read()
            .unwrap()
            .get(track_id)
            .cloned()
            .unwrap_or_else(|| BridgeTrack {
                id: track_id.to_owned(),
                title: track_id.to_owned(),
                artist: String::new(),
                album: String::new(),
                cover_url: None,
                duration_ms: 0,
                source: BridgeTrackSource::Remote,
            })
    }
}

/// What [`OnlineService::resolve`] learned about a video.
struct ResolvedAudio {
    url: String,
    duration_ms: i64,
    title: String,
    author: String,
    cover: Option<String>,
}

/// Reads a cached file's own duration, in milliseconds.
///
/// Used when a download is served from the cache in a process that never
/// resolved it, because the search hit may describe a different thing (the whole
/// multi-part series) than the part that was actually downloaded.
fn cached_duration_ms(path: &Path) -> Option<i64> {
    let tagged = lofty::probe::Probe::open(path).ok()?.read().ok()?;
    let duration = tagged.properties().duration();

    (!duration.is_zero()).then(|| duration.as_millis().min(i64::MAX as u128) as i64)
}

/// The cookie the client should use, if the environment supplies one.
fn cookie_from_env() -> Option<String> {
    COOKIE_ENV
        .iter()
        .find_map(|name| std::env::var(name).ok())
        .map(|value| value.trim().to_owned())
        .filter(|value| !value.is_empty())
}

/// Where downloaded audio lives.
///
/// Follows the platform's cache convention but never fails: a machine without a
/// home directory still gets a working cache under the system temporary
/// directory.
fn cache_dir() -> PathBuf {
    for (variable, suffix) in [
        (CACHE_ENV, ""),
        ("LOCALAPPDATA", "muse-player"),
        ("XDG_CACHE_HOME", "muse-player"),
        ("HOME", ".cache/muse-player"),
    ] {
        let Ok(base) = std::env::var(variable) else {
            continue;
        };
        let base = base.trim();
        if base.is_empty() {
            continue;
        }
        return match suffix.is_empty() {
            true => PathBuf::from(base).join("bilibili"),
            false => PathBuf::from(base).join(suffix).join("bilibili"),
        };
    }

    std::env::temp_dir().join("muse-player").join("bilibili")
}

/// Id the online catalog uses for `bvid`.
fn online_track_id(bvid: &str) -> String {
    format!("{ONLINE_ID_PREFIX}{bvid}")
}

/// Inverse of [`online_track_id`].
fn bvid_from_track_id(track_id: &str) -> Option<&str> {
    track_id
        .strip_prefix(ONLINE_ID_PREFIX)
        .filter(|bvid| !bvid.is_empty())
}

/// Projects a search hit onto the shared track contract.
fn video_to_track(video: &Video) -> Option<BridgeTrack> {
    let bvid = video.bvid.trim();
    if bvid.is_empty() {
        return None;
    }

    Some(BridgeTrack {
        id: online_track_id(bvid),
        // Search titles are wrapped in `<em class="keyword">` highlight tags.
        title: strip_highlight(&video.title),
        artist: video.author.trim().to_owned(),
        album: video.typename.trim().to_owned(),
        cover_url: normalize_cover(&video.pic),
        duration_ms: parse_duration_ms(&video.duration).unwrap_or(0),
        source: BridgeTrackSource::Remote,
    })
}

/// Picks the richest audio track the response offers.
///
/// Dolby and Hi-Res entries only appear for accounts entitled to them, so they
/// are fallbacks rather than the primary choice.
fn pick_audio_stream(dash: Option<&DashInfo>) -> Option<&DashStream> {
    let dash = dash?;

    if let Some(stream) = dash.audio.iter().max_by_key(|stream| stream.bandwidth) {
        return Some(stream);
    }
    if let Some(stream) = dash.flac.as_ref().and_then(|flac| flac.audio.as_ref()) {
        return Some(stream);
    }
    dash.dolby
        .as_ref()
        .and_then(|dolby| dolby.audio.as_ref())
        .and_then(|streams| streams.first())
}

/// Turns `mm:ss` / `hh:mm:ss` into milliseconds.
///
/// Returns `None` for anything unparsable, which the caller surfaces as an
/// unknown duration rather than a wrong one.
fn parse_duration_ms(raw: &str) -> Option<i64> {
    let mut total: i64 = 0;
    let mut parts = 0;

    for part in raw.trim().split(':') {
        let value: i64 = part.trim().parse().ok()?;
        if value < 0 {
            return None;
        }
        total = total.checked_mul(60)?.checked_add(value)?;
        parts += 1;
    }

    match parts {
        0 => None,
        _ => Some(total * 1_000),
    }
}

/// Removes the `<em class="keyword">` highlight tags search titles carry.
fn strip_highlight(title: &str) -> String {
    let mut output = String::with_capacity(title.len());
    let mut inside_tag = false;

    for character in title.chars() {
        match character {
            '<' => inside_tag = true,
            '>' => inside_tag = false,
            _ if !inside_tag => output.push(character),
            _ => {}
        }
    }

    output
}

/// Normalises a cover URL, which Bilibili returns protocol-relative.
fn normalize_cover(raw: &str) -> Option<String> {
    let raw = raw.trim();
    if raw.is_empty() {
        return None;
    }

    Some(match raw.starts_with("//") {
        true => format!("https:{raw}"),
        false => raw.to_owned(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use bpi_rs::video::videostream_url::{DashDolby, DashFlac};

    fn stream(id: u64, bandwidth: u64) -> DashStream {
        DashStream {
            id,
            base_url: format!("https://example.invalid/{id}.m4s"),
            backup_url: Vec::new(),
            bandwidth,
            mime_type: "audio/mp4".to_owned(),
            codecs: "mp4a.40.2".to_owned(),
            width: None,
            height: None,
            frame_rate: None,
            sar: None,
            start_with_sap: None,
            segment_base: None,
            md5: None,
            size: None,
            db_type: None,
            r#type: None,
            stream_name: None,
            orientation: None,
        }
    }

    fn dash(audio: Vec<DashStream>) -> DashInfo {
        DashInfo {
            video: Vec::new(),
            audio,
            dolby: None,
            flac: None,
            duration: 0,
        }
    }

    #[test]
    fn track_ids_round_trip() {
        let id = online_track_id("BV1xx411c7mD");
        assert_eq!(id, "bili_BV1xx411c7mD");
        assert_eq!(bvid_from_track_id(&id), Some("BV1xx411c7mD"));

        // Local ids and malformed online ids are rejected.
        assert_eq!(bvid_from_track_id("local_0123"), None);
        assert_eq!(bvid_from_track_id("bili_"), None);
        assert_eq!(bvid_from_track_id("song_001"), None);
    }

    #[test]
    fn durations_parse_from_search_hits() {
        assert_eq!(parse_duration_ms("3:25"), Some(205_000));
        assert_eq!(parse_duration_ms("0:07"), Some(7_000));
        assert_eq!(parse_duration_ms("1:02:03"), Some(3_723_000));
        assert_eq!(parse_duration_ms("  4:00 "), Some(240_000));

        assert_eq!(parse_duration_ms(""), None);
        assert_eq!(parse_duration_ms("not a duration"), None);
        assert_eq!(parse_duration_ms("12:ab"), None);
        assert_eq!(parse_duration_ms("-1:00"), None);
    }

    #[test]
    fn highlight_tags_are_stripped_from_titles() {
        assert_eq!(
            strip_highlight(r#"<em class="keyword">Rust</em> 教程"#),
            "Rust 教程"
        );
        assert_eq!(strip_highlight("no tags"), "no tags");
        assert_eq!(strip_highlight(""), "");
    }

    #[test]
    fn covers_are_normalised_to_https() {
        assert_eq!(
            normalize_cover("//i0.hdslb.com/bfs/archive/a.jpg"),
            Some("https://i0.hdslb.com/bfs/archive/a.jpg".to_owned())
        );
        assert_eq!(
            normalize_cover("https://i0.hdslb.com/a.jpg"),
            Some("https://i0.hdslb.com/a.jpg".to_owned())
        );
        assert_eq!(normalize_cover("   "), None);
    }

    #[test]
    fn search_hits_without_a_bvid_are_dropped() {
        let video = |bvid: &str| Video {
            r#type: "video".to_owned(),
            id: 1,
            author: "up".to_owned(),
            mid: 2,
            typeid: "171".to_owned(),
            typename: "电子音乐".to_owned(),
            arcurl: String::new(),
            aid: 1,
            bvid: bvid.to_owned(),
            title: r#"<em class="keyword">曲</em>名"#.to_owned(),
            pic: "//i0.hdslb.com/a.jpg".to_owned(),
            play: 10,
            danmaku: 0,
            favorites: 0,
            like: 0,
            tag: String::new(),
            review: 0,
            pubdate: 0,
            duration: "3:25".to_owned(),
        };

        let track = video_to_track(&video("BV1xx411c7mD")).expect("track");
        assert_eq!(track.id, "bili_BV1xx411c7mD");
        assert_eq!(track.title, "曲名");
        assert_eq!(track.artist, "up");
        assert_eq!(track.album, "电子音乐");
        assert_eq!(track.duration_ms, 205_000);
        assert_eq!(
            track.cover_url.as_deref(),
            Some("https://i0.hdslb.com/a.jpg")
        );
        assert_eq!(track.source, BridgeTrackSource::Remote);

        assert!(video_to_track(&video("  ")).is_none());
    }

    #[test]
    fn the_highest_bitrate_audio_track_wins() {
        let response = dash(vec![stream(30216, 64_000), stream(30280, 192_000)]);
        let best = pick_audio_stream(Some(&response)).expect("a stream");
        assert_eq!(best.id, 30280);
    }

    #[test]
    fn flac_and_dolby_are_fallbacks() {
        let mut flac_only = dash(Vec::new());
        flac_only.flac = Some(DashFlac {
            display: Some(true),
            audio: Some(stream(30251, 1_400_000)),
        });
        assert_eq!(
            pick_audio_stream(Some(&flac_only)).map(|stream| stream.id),
            Some(30251)
        );

        let mut dolby_only = dash(Vec::new());
        dolby_only.dolby = Some(DashDolby {
            r#type: 1,
            audio: Some(vec![stream(30250, 448_000)]),
        });
        assert_eq!(
            pick_audio_stream(Some(&dolby_only)).map(|stream| stream.id),
            Some(30250)
        );

        // A `dolby` object with no inner audio is not a Dolby track.
        let mut empty_dolby = dash(Vec::new());
        empty_dolby.dolby = Some(DashDolby {
            r#type: 1,
            audio: None,
        });
        assert!(pick_audio_stream(Some(&empty_dolby)).is_none());

        assert!(pick_audio_stream(None).is_none());
    }

    #[test]
    fn the_cache_directory_can_be_overridden() {
        // The helper reads process environment; only the override branch is
        // asserted here so the test does not depend on the host layout.
        let variable = CACHE_ENV;
        assert!(variable.starts_with("MUSE_"));
    }

    #[test]
    fn each_track_gets_its_own_download_lock() {
        let directory = std::env::temp_dir().join(format!("muse-online-{}", std::process::id()));
        let service = OnlineService {
            client: Arc::new(BpiClient::new().expect("client")),
            runtime: tokio::runtime::Builder::new_current_thread()
                .enable_all()
                .build()
                .expect("runtime"),
            cache_dir: directory,
            known: RwLock::new(HashMap::new()),
            locks: Mutex::new(HashMap::new()),
            authenticated: false,
        };

        // The same track shares one lock, so its two prepares serialise...
        assert!(Arc::ptr_eq(
            &service.track_lock("bili_BV1"),
            &service.track_lock("bili_BV1")
        ));
        // ...while different tracks never block each other.
        assert!(!Arc::ptr_eq(
            &service.track_lock("bili_BV1"),
            &service.track_lock("bili_BV2")
        ));
    }

    #[test]
    fn a_cached_files_own_duration_is_readable() {
        let directory = std::env::temp_dir().join(format!("muse-online-{}", std::process::id()));
        std::fs::create_dir_all(&directory).expect("temp directory");
        let path = directory.join("probe.wav");

        // One second of silence: the cheapest fixture `lofty` can measure.
        let spec = hound::WavSpec {
            channels: 1,
            sample_rate: 8_000,
            bits_per_sample: 16,
            sample_format: hound::SampleFormat::Int,
        };
        let mut writer = hound::WavWriter::create(&path, spec).expect("create fixture");
        for _ in 0..8_000 {
            writer.write_sample(0i16).expect("write sample");
        }
        writer.finalize().expect("finalize fixture");

        let duration = cached_duration_ms(&path).expect("lofty reads the header");
        assert!(
            (900..=1_100).contains(&duration),
            "expected about one second, got {duration}ms"
        );

        let _ = std::fs::remove_file(&path);
        let _ = std::fs::remove_dir(&directory);
    }
}

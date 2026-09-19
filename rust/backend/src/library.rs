//! Song catalog backing the REST endpoints.
//!
//! Two sources are supported:
//!
//! - a music directory scanned with `walkdir` + `lofty`, used when
//!   `MUSE_MUSIC_DIR` points at real files;
//! - a built-in seed catalog, so the documented endpoints return the songs from
//!   `docs/backend-api.md` before any files are configured.
//!
//! Entries are stored as [`BridgeTrack`] — the same type the Flutter side
//! receives over `flutter_rust_bridge` — so the HTTP JSON and the FFI contract
//! cannot drift apart.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::{Arc, RwLock};

use lofty::file::TaggedFileExt;
use lofty::prelude::{Accessor, AudioFile};
use lofty::probe::Probe;
use crate::api::bridge_models::{BridgeTrack, BridgeTrackSource};
use walkdir::WalkDir;

use crate::cover::fnv1a;
use crate::models::{PlaylistResponse, Song};

/// Audio extensions the directory scan will attempt to read.
const AUDIO_EXTENSIONS: &[&str] = &[
    "mp3", "flac", "m4a", "mp4", "aac", "ogg", "oga", "opus", "wav", "wv", "aiff", "aif",
];

/// Id of the single playlist served by `GET /playlist`.
pub const DEFAULT_PLAYLIST_ID: &str = "playlist_default";
/// Title of the single playlist served by `GET /playlist`.
pub const DEFAULT_PLAYLIST_TITLE: &str = "默认列表";

/// A track that came from the online (Bilibili) catalog.
#[derive(Debug, Clone)]
struct OnlineEntry {
    track: BridgeTrack,
    /// Cached audio file, once the track has been prepared for playback.
    file: Option<PathBuf>,
}

/// Song catalog: the on-disk (or seed) library plus an online overlay.
///
/// The overlay is keyed by track id and stays out of [`Library::tracks`] and
/// [`Library::ids`] on purpose: online results must be resolvable by the player
/// without silently joining the default queue or the local search results.
pub struct Library {
    tracks: Vec<BridgeTrack>,
    by_id: HashMap<String, usize>,
    /// Local file backing each track, keyed by track id.
    ///
    /// Seed/mock entries have no file, so they are simply absent here; that is
    /// what tells the player to fall back to a silent placeholder instead of
    /// pretending a file exists.
    files: HashMap<String, PathBuf>,
    /// Online tracks seen this session, keyed by track id.
    online: RwLock<HashMap<String, OnlineEntry>>,
}

impl Library {
    /// Builds the built-in catalog.
    ///
    /// The entries mirror `lib/mock/mock_music.dart` so a client that has been
    /// running on Phase 1 mock data keeps the same ids once it switches to the
    /// backend.
    pub fn seeded(public_base_url: &str) -> Self {
        let seed: &[(&str, &str, &str, &str, i64)] = &[
            (
                "song_001",
                "Midnight Drive",
                "Google Material Orchestra",
                "Synthetic Waves",
                252_000,
            ),
            (
                "song_002",
                "冬日挽歌",
                "Cytus II",
                "Cytus II Original Soundtrack",
                308_000,
            ),
            ("song_003", "Lemon", "米津玄師", "Lemon", 256_000),
            ("song_004", "晴天", "周杰伦", "叶惠美", 269_000),
            (
                "song_005",
                "The Nights",
                "Avicii",
                "The Days / Nights",
                176_000,
            ),
            ("song_006", "Fix You", "Coldplay", "X&Y", 294_000),
        ];

        let tracks = seed
            .iter()
            .map(|(id, title, artist, album, duration_ms)| BridgeTrack {
                id: (*id).to_owned(),
                title: (*title).to_owned(),
                artist: (*artist).to_owned(),
                album: (*album).to_owned(),
                cover_url: Some(cover_url(public_base_url, id)),
                duration_ms: *duration_ms,
                source: BridgeTrackSource::Mock,
            })
            .collect();

        Self::from_tracks(tracks, HashMap::new())
    }

    /// Scans `dir` for audio files and reads their tags.
    ///
    /// Files that cannot be parsed are skipped rather than failing the whole
    /// scan: one corrupt file should not make the library unusable. A file
    /// whose tags are empty still appears, using its file name as the title.
    pub fn from_music_dir(dir: &Path, public_base_url: &str) -> Self {
        let mut tracks = Vec::new();
        let mut files = HashMap::new();

        for entry in WalkDir::new(dir)
            .follow_links(true)
            .into_iter()
            .filter_map(Result::ok)
        {
            if !entry.file_type().is_file() || !has_audio_extension(entry.path()) {
                continue;
            }

            let path = entry.path();
            match read_track(path, public_base_url) {
                Some(track) => {
                    // The path is not part of the shared `BridgeTrack`
                    // contract, so it lives beside the catalog instead. The id
                    // is derived from this path, which is what makes the
                    // lookup stable across restarts.
                    files.insert(track.id.clone(), path.to_path_buf());
                    tracks.push(track);
                }
                None => tracing::debug!(path = %path.display(), "skipping unreadable audio file"),
            }
        }

        // A stable order keeps ids, `/songs/{id}` lookups and the playlist
        // consistent between runs; `walkdir`'s traversal order is not sorted.
        tracks.sort_by(|a, b| a.id.cmp(&b.id));
        Self::from_tracks(tracks, files)
    }

    fn from_tracks(tracks: Vec<BridgeTrack>, files: HashMap<String, PathBuf>) -> Self {
        let by_id = tracks
            .iter()
            .enumerate()
            .map(|(index, track)| (track.id.clone(), index))
            .collect();

        Self {
            tracks,
            by_id,
            files,
            online: RwLock::new(HashMap::new()),
        }
    }

    /// Registers online tracks so the player can resolve them by id.
    ///
    /// Existing entries keep their cached file: a re-search must not evict an
    /// already downloaded track, or the next play would hit the network again.
    pub fn register_online(&self, tracks: impl IntoIterator<Item = BridgeTrack>) {
        let mut online = self.online.write().unwrap();

        for track in tracks {
            match online.get_mut(&track.id) {
                Some(entry) => entry.track = track,
                None => {
                    online.insert(
                        track.id.clone(),
                        OnlineEntry {
                            track,
                            file: None,
                        },
                    );
                }
            }
        }
    }

    /// Registers an online track together with its cached audio file.
    pub fn register_online_file(&self, track: BridgeTrack, file: PathBuf) {
        self.online
            .write()
            .unwrap()
            .insert(track.id.clone(), OnlineEntry { track, file: Some(file) });
    }

    /// Audio file backing `id`, if one has been resolved.
    ///
    /// `None` means the entry is metadata-only — a seed track or an online track
    /// that has not been prepared yet — and the player should not pretend a file
    /// exists.
    pub fn file(&self, id: &str) -> Option<PathBuf> {
        if let Some(path) = self.files.get(id) {
            return Some(path.clone());
        }

        self.online
            .read()
            .unwrap()
            .get(id)
            .and_then(|entry| entry.file.clone())
    }

    /// Every track, in catalog order.
    ///
    /// Online tracks are deliberately absent: this is the on-disk catalog that
    /// seeds the queue and backs `GET /playlist`.
    pub fn tracks(&self) -> &[BridgeTrack] {
        &self.tracks
    }

    /// Song ids in catalog order, used to seed the player queue.
    pub fn ids(&self) -> Vec<String> {
        self.tracks.iter().map(|track| track.id.clone()).collect()
    }

    pub fn is_empty(&self) -> bool {
        self.tracks.is_empty()
    }

    /// Looks up a track by id, online overlay included.
    ///
    /// Returns an owned value because online entries live behind a lock; the
    /// clone is a handful of strings, and it keeps callers from holding a read
    /// guard across the player's state transition.
    pub fn track(&self, id: &str) -> Option<BridgeTrack> {
        if let Some(index) = self.by_id.get(id) {
            return Some(self.tracks[*index].clone());
        }

        self.online
            .read()
            .unwrap()
            .get(id)
            .map(|entry| entry.track.clone())
    }

    /// Looks up a song by id, in wire form.
    pub fn song(&self, id: &str) -> Option<Song> {
        self.track(id).map(|track| Song::from(&track))
    }

    /// Case-insensitive substring search over title, artist and album.
    ///
    /// An empty query returns the whole catalog, which makes the endpoint
    /// usable as a "browse all" call without a second route.
    pub fn search(&self, query: &str) -> Vec<Song> {
        self.search_tracks(query).iter().map(Song::from).collect()
    }

    /// Same search, but returning the shared contract type.
    ///
    /// This is what the FFI path uses: the app wants `BridgeTrack`, not the
    /// HTTP DTO, and mapping through it would be a pointless round trip.
    pub fn search_tracks(&self, query: &str) -> Vec<BridgeTrack> {
        let needle = query.trim().to_lowercase();

        self.tracks
            .iter()
            .filter(|track| {
                needle.is_empty()
                    || track.title.to_lowercase().contains(&needle)
                    || track.artist.to_lowercase().contains(&needle)
                    || track.album.to_lowercase().contains(&needle)
            })
            .cloned()
            .collect()
    }

    /// The single playlist served by `GET /playlist`.
    pub fn playlist(&self) -> PlaylistResponse {
        PlaylistResponse {
            id: DEFAULT_PLAYLIST_ID.to_owned(),
            title: DEFAULT_PLAYLIST_TITLE.to_owned(),
            songs: self.tracks.iter().map(Song::from).collect(),
        }
    }

    /// Looks up the track whose cover is requested, tolerating a missing or
    /// unexpected file extension in the URL.
    pub fn track_by_cover_name(&self, name: &str) -> Option<BridgeTrack> {
        let id = name.strip_suffix(".jpg").unwrap_or(name);
        self.track(id)
    }
}

/// Absolute URL of a song's cover.
pub fn cover_url(public_base_url: &str, id: &str) -> String {
    format!("{}/covers/{id}.jpg", public_base_url.trim_end_matches('/'))
}

fn has_audio_extension(path: &Path) -> bool {
    path.extension()
        .and_then(|extension| extension.to_str())
        .map(|extension| {
            let lower = extension.to_lowercase();
            AUDIO_EXTENSIONS.contains(&lower.as_str())
        })
        .unwrap_or(false)
}

/// Reads one audio file into a [`BridgeTrack`].
///
/// Returns `None` when the file cannot be parsed at all; missing tags fall back
/// to the file name so a plain folder of files still produces a usable list.
fn read_track(path: &Path, public_base_url: &str) -> Option<BridgeTrack> {
    let tagged = Probe::open(path).ok()?.read().ok()?;

    let tag = tagged.primary_tag().or_else(|| tagged.first_tag());
    let title = tag
        .and_then(|tag| tag.title().map(|value| value.to_string()))
        .filter(|value| !value.trim().is_empty())
        .unwrap_or_else(|| file_stem(path));
    let artist = tag
        .and_then(|tag| tag.artist().map(|value| value.to_string()))
        .unwrap_or_default();
    let album = tag
        .and_then(|tag| tag.album().map(|value| value.to_string()))
        .unwrap_or_default();

    // `lofty` reports duration on the file properties, not the tag.
    let duration_ms = tagged
        .properties()
        .duration()
        .as_millis()
        .min(i64::MAX as u128) as i64;

    let id = local_track_id(path);
    Some(BridgeTrack {
        id: id.clone(),
        title,
        artist,
        album,
        cover_url: Some(cover_url(public_base_url, &id)),
        duration_ms,
        source: BridgeTrackSource::Local,
    })
}

/// Stable id for a local file.
///
/// Hashing the absolute path keeps the id stable across restarts while staying
/// filesystem-safe, which matters because the id is used as a URL path segment
/// in `/songs/{id}` and `/covers/{id}.jpg`.
fn local_track_id(path: &Path) -> String {
    let absolute: PathBuf = path.canonicalize().unwrap_or_else(|_| path.to_path_buf());
    let hash = fnv1a(&absolute.to_string_lossy());
    format!("local_{hash:016x}")
}

fn file_stem(path: &Path) -> String {
    path.file_stem()
        .and_then(|stem| stem.to_str())
        .unwrap_or("Untitled")
        .to_owned()
}

/// Convenience wrapper so callers do not have to know whether a directory
/// should be scanned or the seed catalog used.
pub fn load(music_dir: Option<&Path>, public_base_url: &str) -> Arc<Library> {
    match music_dir {
        Some(dir) if dir.is_dir() => {
            let library = Library::from_music_dir(dir, public_base_url);
            if library.is_empty() {
                tracing::warn!(
                    dir = %dir.display(),
                    "music directory contained no readable audio files; falling back to the seed catalog"
                );
                Arc::new(Library::seeded(public_base_url))
            } else {
                tracing::info!(dir = %dir.display(), songs = library.tracks().len(), "scanned music directory");
                Arc::new(library)
            }
        }
        Some(dir) => {
            tracing::warn!(dir = %dir.display(), "music directory does not exist; using the seed catalog");
            Arc::new(Library::seeded(public_base_url))
        }
        None => Arc::new(Library::seeded(public_base_url)),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn library() -> Library {
        Library::seeded("http://127.0.0.1:8080")
    }

    #[test]
    fn seed_catalog_matches_the_documented_example() {
        let library = library();
        let song = library.song("song_001").expect("song_001 exists");
        assert_eq!(song.title, "Midnight Drive");
        assert_eq!(song.artist, "Google Material Orchestra");
        assert_eq!(song.album, "Synthetic Waves");
        assert_eq!(song.duration_ms, 252_000);
        assert_eq!(song.cover, "http://127.0.0.1:8080/covers/song_001.jpg");
    }

    #[test]
    fn search_matches_title_artist_and_album_case_insensitively() {
        let library = library();

        assert_eq!(library.search("midnight").len(), 1);
        assert_eq!(library.search("MIDNIGHT")[0].id, "song_001");
        assert_eq!(library.search("coldplay")[0].id, "song_006");
        assert_eq!(library.search("叶惠美")[0].id, "song_004");
        // "Lemon" is both a title and an album, so the song matches once.
        assert_eq!(library.search("lemon").len(), 1);
        assert!(library.search("no-such-song").is_empty());
    }

    #[test]
    fn empty_query_returns_the_whole_catalog() {
        assert_eq!(library().search("   ").len(), 6);
    }

    #[test]
    fn playlist_wraps_every_song() {
        let playlist = library().playlist();
        assert_eq!(playlist.id, DEFAULT_PLAYLIST_ID);
        assert_eq!(playlist.songs.len(), 6);
    }

    #[test]
    fn cover_lookup_accepts_the_jpg_suffix() {
        let library = library();
        assert!(library.track_by_cover_name("song_001.jpg").is_some());
        assert!(library.track_by_cover_name("song_001").is_some());
        assert!(library.track_by_cover_name("nope.jpg").is_none());
    }

    #[test]
    fn local_ids_are_stable_and_path_safe() {
        let path = Path::new("/music/a b/song.flac");
        let id = local_track_id(path);
        assert_eq!(id, local_track_id(path));
        assert!(id.starts_with("local_"));
        assert!(id.chars().all(|c| c.is_ascii_alphanumeric() || c == '_'));
    }

    fn online_track(id: &str) -> BridgeTrack {
        BridgeTrack {
            id: id.to_owned(),
            title: "在线曲目".to_owned(),
            artist: "UP".to_owned(),
            album: "分区".to_owned(),
            cover_url: Some("https://i0.hdslb.com/a.jpg".to_owned()),
            duration_ms: 205_000,
            source: BridgeTrackSource::Remote,
        }
    }

    #[test]
    fn online_tracks_resolve_without_joining_the_catalog() {
        let library = library();
        library.register_online(vec![online_track("bili_BV1")]);

        // Resolvable by id, for the player and the bridge snapshot.
        let track = library.track("bili_BV1").expect("online track resolves");
        assert_eq!(track.title, "在线曲目");
        assert_eq!(library.song("bili_BV1").expect("wire form").duration_ms, 205_000);

        // But invisible to the queue seed, the playlist and the local search.
        assert_eq!(library.ids().len(), 6);
        assert!(!library.ids().contains(&"bili_BV1".to_owned()));
        assert_eq!(library.tracks().len(), 6);
        assert!(library.search_tracks("在线曲目").is_empty());
        assert_eq!(library.playlist().songs.len(), 6);
    }

    #[test]
    fn an_online_track_has_no_file_until_it_is_prepared() {
        let library = library();
        library.register_online(vec![online_track("bili_BV1")]);
        assert_eq!(library.file("bili_BV1"), None);

        library.register_online_file(
            online_track("bili_BV1"),
            PathBuf::from("/cache/bili_BV1.m4a"),
        );
        assert_eq!(
            library.file("bili_BV1"),
            Some(PathBuf::from("/cache/bili_BV1.m4a"))
        );
    }

    #[test]
    fn re_registering_a_track_keeps_its_cached_file() {
        let library = library();
        library.register_online_file(
            online_track("bili_BV1"),
            PathBuf::from("/cache/bili_BV1.m4a"),
        );

        // A later search returns the same video with fresh metadata; that must
        // not drop the download, or the next play would hit the network again.
        let mut refreshed = online_track("bili_BV1");
        refreshed.title = "新标题".to_owned();
        library.register_online(vec![refreshed]);

        assert_eq!(
            library.track("bili_BV1").expect("track").title,
            "新标题"
        );
        assert_eq!(
            library.file("bili_BV1"),
            Some(PathBuf::from("/cache/bili_BV1.m4a"))
        );
    }

    #[test]
    fn covers_and_songs_can_come_from_the_online_overlay() {
        let library = library();
        library.register_online(vec![online_track("bili_BV1")]);

        let track = library
            .track_by_cover_name("bili_BV1.jpg")
            .expect("cover lookup resolves online ids");
        assert_eq!(track.id, "bili_BV1");
    }
}

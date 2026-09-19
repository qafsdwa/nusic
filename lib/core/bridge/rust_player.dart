import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/song.dart';
import 'generated/api/bridge_models.dart';
import 'generated/api/library.dart' as ffi_library;
import 'generated/api/online.dart' as ffi_online;
import 'generated/api/player.dart' as ffi_player;
import 'generated/frb_generated.dart';

/// In-process bridge to the Rust music engine.
///
/// This replaces the earlier REST/WebSocket client: every call here crosses
/// `flutter_rust_bridge` directly, so there is no socket, no JSON, and no
/// serialization round trip. The Rust side owns the audio device, the library
/// scan and the player state machine; Dart only renders what it reports.
class RustPlayer {
  const RustPlayer();

  /// Serializes the one-time bootstrap so concurrent callers share it.
  static Future<void>? _bootstrap;

  /// Loads the native library and starts the Rust engine.
  ///
  /// Idempotent: repeated calls return the same future, which matters because
  /// Riverpod may rebuild the player provider without the process restarting.
  static Future<void> bootstrap({String? musicDir, double volume = 0.7}) {
    return _bootstrap ??= _run(musicDir: musicDir, volume: volume);
  }

  static Future<void> _run({String? musicDir, required double volume}) async {
    await RustLib.init();
    await ffi_player.init(musicDir: musicDir, volume: volume);
  }

  /// Case-insensitive search over title, artist and album.
  ///
  /// An empty query returns the whole catalog.
  Future<List<Song>> searchSongs(String query) async {
    final List<BridgeTrack> tracks = await ffi_library.searchSongs(
      query: query,
    );
    return tracks.map(songFromTrack).toList(growable: false);
  }

  /// Every track in the catalog, in playlist order.
  Future<List<Song>> playlist() async {
    final List<BridgeTrack> tracks = await ffi_library.playlist();
    return tracks.map(songFromTrack).toList(growable: false);
  }

  /// `rodio` when a device is available, `clock` for the silent fallback.
  Future<String> engineName() => ffi_library.engineName();

  /// Whether online search is usable, and whether a cookie was configured.
  Future<ffi_online.BridgeOnlineStatus> onlineStatus() => ffi_online.status();

  /// Searches Bilibili videos.
  ///
  /// The results are registered with the Rust catalog, which is what lets
  /// [prepareTrack] and the player resolve them by id afterwards.
  Future<List<Song>> searchVideos(String query, {int page = 1}) async {
    final List<BridgeTrack> tracks = await ffi_online.searchVideos(
      query: query,
      page: page,
    );
    return tracks.map(songFromTrack).toList(growable: false);
  }

  /// Resolves a video's DASH audio track, downloading it into the cache.
  ///
  /// Cheap after the first call: the cache is keyed by track, so replaying a
  /// track never hits the network again. Must run before the player is asked to
  /// play an online track.
  Future<Song> prepareTrack(String trackId) async {
    final BridgeTrack track = await ffi_online.prepareTrack(trackId: trackId);
    return songFromTrack(track);
  }

  /// Current state, without subscribing.
  Future<BridgePlayerSnapshot> snapshot() => ffi_player.snapshot();

  /// Applies one command and returns the resulting state.
  Future<BridgePlayerSnapshot> send(BridgePlayerCommand command) =>
      ffi_player.command(command: command);

  /// State pushes from Rust.
  ///
  /// The first frame is the current state, sent as soon as the stream is
  /// listened to, so callers never need to poll for an initial snapshot.
  Stream<BridgePlayerSnapshot> get states => ffi_player.subscribe();
}

/// The app-wide bridge handle.
final rustPlayerProvider = Provider<RustPlayer>(
  (Ref ref) => const RustPlayer(),
);

/// Projects the shared contract track onto the UI model.
Song songFromTrack(BridgeTrack track) {
  return Song(
    id: track.id,
    title: track.title,
    artist: track.artist,
    album: track.album,
    // Rust reports `None` for tracks without artwork; the UI falls back to
    // generated cover art for an empty string.
    cover: track.coverUrl ?? '',
    duration: Duration(milliseconds: track.durationMs.toInt()),
    source: songSourceFromTrack(track.source),
  );
}

/// Maps the contract's track source onto the UI enum.
SongSource songSourceFromTrack(BridgeTrackSource source) {
  return switch (source) {
    BridgeTrackSource.local => SongSource.local,
    BridgeTrackSource.remote => SongSource.remote,
    BridgeTrackSource.mock => SongSource.mock,
    BridgeTrackSource.unknown => SongSource.unknown,
  };
}

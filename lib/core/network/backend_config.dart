/// Future Rust backend contract.
///
/// Phase 1 intentionally does NOT make any network calls. This file only keeps
/// endpoint names in one place so the transition to a real Rust service can be
/// done without touching UI code.
abstract final class BackendConfig {
  static const String baseUrl = 'http://127.0.0.1:8080';

  /// GET /songs/search?q=...
  static const String songsSearchPath = '/songs/search';

  /// GET /songs/{id}
  static const String songPath = '/songs';

  /// GET /playlist
  static const String playlistPath = '/playlist';

  /// WebSocket endpoint for player state sync.
  static const String playerWebSocketPath = '/ws/player';
}

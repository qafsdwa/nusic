/// Backend endpoint configuration.
///
/// In Phase 1 these values are loaded from `assets/config/app_config.json`
/// during app startup and exposed through `appConfigProvider`. No network
/// requests are made yet; the model exists so the future Rust REST and
/// WebSocket clients have a clean place to read their base URL and paths.
class BackendConfig {
  const BackendConfig({
    required this.baseUrl,
    required this.songsSearchPath,
    required this.songPath,
    required this.playlistPath,
    required this.playerWebSocketPath,
  });

  final String baseUrl;
  final String songsSearchPath;
  final String songPath;
  final String playlistPath;
  final String playerWebSocketPath;

  static const BackendConfig fallback = BackendConfig(
    baseUrl: 'http://127.0.0.1:8080',
    songsSearchPath: '/songs/search',
    songPath: '/songs',
    playlistPath: '/playlist',
    playerWebSocketPath: '/ws/player',
  );

  factory BackendConfig.fromJson(Map<String, dynamic> json) {
    return BackendConfig(
      baseUrl: json['baseUrl'] as String? ?? fallback.baseUrl,
      songsSearchPath:
          json['songsSearchPath'] as String? ?? fallback.songsSearchPath,
      songPath: json['songPath'] as String? ?? fallback.songPath,
      playlistPath: json['playlistPath'] as String? ?? fallback.playlistPath,
      playerWebSocketPath:
          json['playerWebSocketPath'] as String? ??
          fallback.playerWebSocketPath,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'baseUrl': baseUrl,
      'songsSearchPath': songsSearchPath,
      'songPath': songPath,
      'playlistPath': playlistPath,
      'playerWebSocketPath': playerWebSocketPath,
    };
  }
}

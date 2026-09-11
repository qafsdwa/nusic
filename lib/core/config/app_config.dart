import '../network/backend_config.dart';
import 'theme_config.dart';

/// Immutable application configuration loaded from
/// `assets/config/app_config.json` at startup.
///
/// Keeping configuration in a model instead of scattered constants makes it
/// possible to add build flavors or a Rust-provided remote config later
/// without changing UI code.
class AppConfig {
  const AppConfig({
    required this.appName,
    required this.environment,
    required this.enableMockData,
    required this.enableNetwork,
    required this.backend,
    required this.player,
    required this.theme,
  });

  final String appName;
  final String environment;
  final bool enableMockData;
  final bool enableNetwork;
  final BackendConfig backend;
  final PlayerConfig player;
  final ThemeConfig theme;

  static const AppConfig fallback = AppConfig(
    appName: 'Muse Player',
    environment: 'development',
    enableMockData: true,
    enableNetwork: false,
    backend: BackendConfig.fallback,
    player: PlayerConfig.fallback,
    theme: ThemeConfig.fallback,
  );

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final Object? backendJson = json['backend'];
    final Object? playerJson = json['player'];
    final Object? themeJson = json['theme'];

    return AppConfig(
      appName: json['appName'] as String? ?? fallback.appName,
      environment: json['environment'] as String? ?? fallback.environment,
      enableMockData:
          json['enableMockData'] as bool? ?? fallback.enableMockData,
      enableNetwork: json['enableNetwork'] as bool? ?? fallback.enableNetwork,
      backend: backendJson is Map<String, dynamic>
          ? BackendConfig.fromJson(backendJson)
          : fallback.backend,
      player: playerJson is Map<String, dynamic>
          ? PlayerConfig.fromJson(playerJson)
          : fallback.player,
      theme: themeJson is Map<String, dynamic>
          ? ThemeConfig.fromJson(themeJson)
          : fallback.theme,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'appName': appName,
      'environment': environment,
      'enableMockData': enableMockData,
      'enableNetwork': enableNetwork,
      'backend': backend.toJson(),
      'player': player.toJson(),
      'theme': theme.toJson(),
    };
  }
}

/// Player defaults that can be tuned without rebuilding UI widgets.
class PlayerConfig {
  const PlayerConfig({
    required this.initialVolume,
    required this.defaultShuffle,
    required this.defaultRepeatMode,
  });

  final double initialVolume;
  final bool defaultShuffle;

  /// One of `off`, `all`, `one`.
  final String defaultRepeatMode;

  static const PlayerConfig fallback = PlayerConfig(
    initialVolume: 0.7,
    defaultShuffle: false,
    defaultRepeatMode: 'off',
  );

  factory PlayerConfig.fromJson(Map<String, dynamic> json) {
    final Object? rawVolume = json['initialVolume'];
    return PlayerConfig(
      initialVolume: rawVolume is num
          ? rawVolume.toDouble().clamp(0.0, 1.0)
          : fallback.initialVolume,
      defaultShuffle:
          json['defaultShuffle'] as bool? ?? fallback.defaultShuffle,
      defaultRepeatMode:
          json['defaultRepeatMode'] as String? ?? fallback.defaultRepeatMode,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'initialVolume': initialVolume,
      'defaultShuffle': defaultShuffle,
      'defaultRepeatMode': defaultRepeatMode,
    };
  }
}

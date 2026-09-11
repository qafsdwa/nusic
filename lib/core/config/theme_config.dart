import 'dart:ui' show Color;

/// Theme configuration loaded from `assets/config/app_config.json`.
///
/// Keeping the palette in JSON lets the Material 3 theme be adjusted without
/// editing Dart source. [AppConfig.fallback] still contains the Phase 1 default
/// values so tests and cold starts are deterministic.
class ThemeConfig {
  const ThemeConfig({
    required this.mode,
    required this.light,
    required this.dark,
  });

  /// One of `system`, `light`, `dark`.
  final String mode;

  final ThemePalette light;
  final ThemePalette dark;

  static const ThemeConfig fallback = ThemeConfig(
    mode: 'system',
    light: ThemePalette.lightFallback,
    dark: ThemePalette.darkFallback,
  );

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    final Object? lightJson = json['light'];
    final Object? darkJson = json['dark'];

    return ThemeConfig(
      mode: json['mode'] as String? ?? fallback.mode,
      light: lightJson is Map<String, dynamic>
          ? ThemePalette.fromJson(
              lightJson,
              fallback: ThemePalette.lightFallback,
            )
          : fallback.light,
      dark: darkJson is Map<String, dynamic>
          ? ThemePalette.fromJson(darkJson, fallback: ThemePalette.darkFallback)
          : fallback.dark,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mode': mode,
      'light': light.toJson(),
      'dark': dark.toJson(),
    };
  }
}

/// A Material 3 color palette used to build a [ThemeData].
class ThemePalette {
  const ThemePalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;

  static const ThemePalette lightFallback = ThemePalette(
    primary: Color(0xFF1A73E8),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD2E3FC),
    onPrimaryContainer: Color(0xFF202124),
    background: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF1F3F4),
    textPrimary: Color(0xFF202124),
    textSecondary: Color(0xFF5F6368),
    divider: Color(0xFFDADCE0),
  );

  static const ThemePalette darkFallback = ThemePalette(
    primary: Color(0xFF8AB4F8),
    onPrimary: Color(0xFF202124),
    primaryContainer: Color(0xFF174EA6),
    onPrimaryContainer: Color(0xFFE8EAED),
    background: Color(0xFF202124),
    surface: Color(0xFF292A2D),
    surfaceVariant: Color(0xFF303134),
    textPrimary: Color(0xFFE8EAED),
    textSecondary: Color(0xFFBDC1C6),
    divider: Color(0xFF3C4043),
  );

  factory ThemePalette.fromJson(
    Map<String, dynamic> json, {
    required ThemePalette fallback,
  }) {
    return ThemePalette(
      primary: _parseColor(json['primary'], fallback.primary),
      onPrimary: _parseColor(json['onPrimary'], fallback.onPrimary),
      primaryContainer: _parseColor(
        json['primaryContainer'],
        fallback.primaryContainer,
      ),
      onPrimaryContainer: _parseColor(
        json['onPrimaryContainer'],
        fallback.onPrimaryContainer,
      ),
      background: _parseColor(json['background'], fallback.background),
      surface: _parseColor(json['surface'], fallback.surface),
      surfaceVariant: _parseColor(
        json['surfaceVariant'],
        fallback.surfaceVariant,
      ),
      textPrimary: _parseColor(json['textPrimary'], fallback.textPrimary),
      textSecondary: _parseColor(json['textSecondary'], fallback.textSecondary),
      divider: _parseColor(json['divider'], fallback.divider),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'primary': _colorToHex(primary),
      'onPrimary': _colorToHex(onPrimary),
      'primaryContainer': _colorToHex(primaryContainer),
      'onPrimaryContainer': _colorToHex(onPrimaryContainer),
      'background': _colorToHex(background),
      'surface': _colorToHex(surface),
      'surfaceVariant': _colorToHex(surfaceVariant),
      'textPrimary': _colorToHex(textPrimary),
      'textSecondary': _colorToHex(textSecondary),
      'divider': _colorToHex(divider),
    };
  }

  static Color _parseColor(Object? value, Color fallback) {
    if (value is! String) {
      return fallback;
    }

    String hex = value.trim().replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) {
      return fallback;
    }

    final int? parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  static String _colorToHex(Color color) {
    final String hex = color
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase();
    return '#$hex';
  }
}

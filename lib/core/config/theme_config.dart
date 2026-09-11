import 'dart:ui' show Color;

import 'config_color.dart';
import 'glass_config.dart';

/// Theme configuration loaded from `assets/config/app_config.json`.
///
/// Keeping the palette in JSON lets the Material 3 theme and the floating
/// player bar glass be adjusted without editing Dart source.
/// [ThemeConfig.fallback] still contains the Phase 1 defaults so tests and
/// cold starts are deterministic.
class ThemeConfig {
  const ThemeConfig({
    required this.mode,
    required this.light,
    required this.dark,
    required this.glass,
  });

  /// One of `system`, `light`, `dark`.
  final String mode;

  final ThemePalette light;
  final ThemePalette dark;
  final GlassConfig glass;

  static const ThemeConfig fallback = ThemeConfig(
    mode: 'system',
    light: ThemePalette.lightFallback,
    dark: ThemePalette.darkFallback,
    glass: GlassConfig.fallback,
  );

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    final Object? lightJson = json['light'];
    final Object? darkJson = json['dark'];
    final Object? glassJson = json['glass'];

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
      glass: glassJson is Map<String, dynamic>
          ? GlassConfig.fromJson(glassJson)
          : fallback.glass,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mode': mode,
      'light': light.toJson(),
      'dark': dark.toJson(),
      'glass': glass.toJson(),
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
      primary: parseConfigColor(json['primary'], fallback.primary),
      onPrimary: parseConfigColor(json['onPrimary'], fallback.onPrimary),
      primaryContainer: parseConfigColor(
        json['primaryContainer'],
        fallback.primaryContainer,
      ),
      onPrimaryContainer: parseConfigColor(
        json['onPrimaryContainer'],
        fallback.onPrimaryContainer,
      ),
      background: parseConfigColor(json['background'], fallback.background),
      surface: parseConfigColor(json['surface'], fallback.surface),
      surfaceVariant: parseConfigColor(
        json['surfaceVariant'],
        fallback.surfaceVariant,
      ),
      textPrimary: parseConfigColor(json['textPrimary'], fallback.textPrimary),
      textSecondary: parseConfigColor(
        json['textSecondary'],
        fallback.textSecondary,
      ),
      divider: parseConfigColor(json['divider'], fallback.divider),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'primary': configColorToHex(primary),
      'onPrimary': configColorToHex(onPrimary),
      'primaryContainer': configColorToHex(primaryContainer),
      'onPrimaryContainer': configColorToHex(onPrimaryContainer),
      'background': configColorToHex(background),
      'surface': configColorToHex(surface),
      'surfaceVariant': configColorToHex(surfaceVariant),
      'textPrimary': configColorToHex(textPrimary),
      'textSecondary': configColorToHex(textSecondary),
      'divider': configColorToHex(divider),
    };
  }
}

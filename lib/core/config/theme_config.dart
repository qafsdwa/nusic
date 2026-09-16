import 'dart:ui' show Color;

import 'config_color.dart';
import 'glass_config.dart';
import 'hero_gradient_config.dart';

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
    required this.heroGradient,
  });

  /// One of `system`, `light`, `dark`.
  final String mode;

  final ThemePalette light;
  final ThemePalette dark;
  final GlassConfig glass;

  /// Decorative gradient for the home hero card.
  final HeroGradientConfig heroGradient;

  static const ThemeConfig fallback = ThemeConfig(
    mode: 'system',
    light: ThemePalette.lightFallback,
    dark: ThemePalette.darkFallback,
    glass: GlassConfig.fallback,
    heroGradient: HeroGradientConfig.fallback,
  );

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    final Object? lightJson = json['light'];
    final Object? darkJson = json['dark'];
    final Object? glassJson = json['glass'];
    final Object? heroGradientJson = json['heroGradient'];

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
      heroGradient: heroGradientJson is Map<String, dynamic>
          ? HeroGradientConfig.fromJson(
              heroGradientJson,
              fallback: HeroGradientConfig.fallback,
            )
          : fallback.heroGradient,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mode': mode,
      'light': light.toJson(),
      'dark': dark.toJson(),
      'glass': glass.toJson(),
      'heroGradient': heroGradient.toJson(),
    };
  }
}

/// A Material 3 color palette used to build a [ThemeData].
///
/// Field names follow the `md.sys.color.*` roles so a palette entry can be
/// traced back to the M3 spec without translation. Two things are deliberate:
///
/// - [outline] and [outlineVariant] are **separate** roles. `outline` marks
///   important boundaries (text field borders, focus rings); `outlineVariant`
///   is the decorative divider tone. Collapsing them removes the ability to
///   tune one without moving the other.
/// - The five `surfaceContainer*` steps form a tonal ramp. M3 communicates
///   elevation through tonal surface colour rather than shadows, so these
///   levels must stay distinguishable for nested surfaces to read as layered.
class ThemePalette {
  const ThemePalette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.outlineVariant,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;

  /// Page background behind the app shell.
  final Color background;

  /// Default surface — the base for cards and navigation chrome.
  final Color surface;

  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;

  /// Maps to `onSurface`.
  final Color textPrimary;

  /// Maps to `onSurfaceVariant`.
  final Color textSecondary;

  /// Important boundaries: text field borders, focus rings.
  final Color outline;

  /// Decorative separation: dividers, list separators.
  final Color outlineVariant;

  static const ThemePalette lightFallback = ThemePalette(
    primary: Color(0xFF1A73E8),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD2E3FC),
    onPrimaryContainer: Color(0xFF202124),
    background: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFBFBFC),
    surfaceContainer: Color(0xFFF5F6F7),
    surfaceContainerHigh: Color(0xFFF1F3F4),
    surfaceContainerHighest: Color(0xFFEBEDEF),
    textPrimary: Color(0xFF202124),
    textSecondary: Color(0xFF5F6368),
    outline: Color(0xFF9AA0A6),
    outlineVariant: Color(0xFFDADCE0),
  );

  static const ThemePalette darkFallback = ThemePalette(
    primary: Color(0xFF8AB4F8),
    onPrimary: Color(0xFF202124),
    primaryContainer: Color(0xFF174EA6),
    onPrimaryContainer: Color(0xFFE8EAED),
    background: Color(0xFF202124),
    surface: Color(0xFF292A2D),
    surfaceContainerLowest: Color(0xFF1B1C1E),
    surfaceContainerLow: Color(0xFF242528),
    surfaceContainer: Color(0xFF292A2D),
    surfaceContainerHigh: Color(0xFF303134),
    surfaceContainerHighest: Color(0xFF37383B),
    textPrimary: Color(0xFFE8EAED),
    textSecondary: Color(0xFFBDC1C6),
    outline: Color(0xFF6E7378),
    outlineVariant: Color(0xFF3C4043),
  );

  factory ThemePalette.fromJson(
    Map<String, dynamic> json, {
    required ThemePalette fallback,
  }) {
    Color read(String key, Color fallbackColor) =>
        parseConfigColor(json[key], fallbackColor);

    return ThemePalette(
      primary: read('primary', fallback.primary),
      onPrimary: read('onPrimary', fallback.onPrimary),
      primaryContainer: read('primaryContainer', fallback.primaryContainer),
      onPrimaryContainer: read(
        'onPrimaryContainer',
        fallback.onPrimaryContainer,
      ),
      background: read('background', fallback.background),
      surface: read('surface', fallback.surface),
      surfaceContainerLowest: read(
        'surfaceContainerLowest',
        fallback.surfaceContainerLowest,
      ),
      surfaceContainerLow: read(
        'surfaceContainerLow',
        fallback.surfaceContainerLow,
      ),
      surfaceContainer: read('surfaceContainer', fallback.surfaceContainer),
      surfaceContainerHigh: read(
        'surfaceContainerHigh',
        fallback.surfaceContainerHigh,
      ),
      surfaceContainerHighest: read(
        'surfaceContainerHighest',
        fallback.surfaceContainerHighest,
      ),
      textPrimary: read('textPrimary', fallback.textPrimary),
      textSecondary: read('textSecondary', fallback.textSecondary),
      outline: read('outline', fallback.outline),
      outlineVariant: read('outlineVariant', fallback.outlineVariant),
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
      'surfaceContainerLowest': configColorToHex(surfaceContainerLowest),
      'surfaceContainerLow': configColorToHex(surfaceContainerLow),
      'surfaceContainer': configColorToHex(surfaceContainer),
      'surfaceContainerHigh': configColorToHex(surfaceContainerHigh),
      'surfaceContainerHighest': configColorToHex(surfaceContainerHighest),
      'textPrimary': configColorToHex(textPrimary),
      'textSecondary': configColorToHex(textSecondary),
      'outline': configColorToHex(outline),
      'outlineVariant': configColorToHex(outlineVariant),
    };
  }
}

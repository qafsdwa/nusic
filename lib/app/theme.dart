import 'package:flutter/material.dart';

import '../core/config/theme_config.dart';
import '../core/constants/app_sizes.dart';

/// Builds Material 3 light / dark [ThemeData] from a [ThemePalette].
///
/// No colors are hardcoded here. Phase 1 defaults live in
/// [ThemePalette.lightFallback] / [ThemePalette.darkFallback] and are only used
/// when the JSON asset is missing or malformed.
abstract final class AppTheme {
  /// Light theme built from the configured light palette.
  static ThemeData light(ThemePalette palette) {
    return _build(brightness: Brightness.light, palette: palette);
  }

  /// Dark theme built from the configured dark palette.
  static ThemeData dark(ThemePalette palette) {
    return _build(brightness: Brightness.dark, palette: palette);
  }

  /// Maps the JSON `theme.mode` string to a Flutter [ThemeMode].
  static ThemeMode resolveThemeMode(String mode) {
    return switch (mode.toLowerCase()) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static ThemeData _build({
    required Brightness brightness,
    required ThemePalette palette,
  }) {
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: brightness,
        ).copyWith(
          primary: palette.primary,
          onPrimary: palette.onPrimary,
          primaryContainer: palette.primaryContainer,
          onPrimaryContainer: palette.onPrimaryContainer,
          surface: palette.surface,
          onSurface: palette.textPrimary,
          surfaceContainerHighest: palette.surfaceVariant,
          surfaceContainerHigh: palette.surfaceVariant,
          onSurfaceVariant: palette.textSecondary,
          outline: palette.divider,
          outlineVariant: palette.divider,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: palette.primaryContainer,
        selectedIconTheme: IconThemeData(color: palette.primary),
        selectedLabelTextStyle: TextStyle(
          color: palette.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme: IconThemeData(color: palette.textSecondary),
        unselectedLabelTextStyle: TextStyle(color: palette.textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.primaryContainer,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceVariant,
        hintStyle: TextStyle(color: palette.textSecondary),
        prefixIconColor: palette.textSecondary,
        suffixIconColor: palette.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingMd,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 2,
        activeTrackColor: palette.primary,
        inactiveTrackColor: palette.divider,
        thumbColor: palette.primary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        overlayColor: palette.primary.withValues(alpha: 0.12),
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/constants/app_sizes.dart';

/// Theme colors matching the requested Material You palette.
abstract final class AppColors {
  static const Color lightPrimary = Color(0xFF1A73E8);
  static const Color lightPrimaryContainer = Color(0xFFD2E3FC);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F3F4);
  static const Color lightTextPrimary = Color(0xFF202124);
  static const Color lightTextSecondary = Color(0xFF5F6368);
  static const Color lightDivider = Color(0xFFDADCE0);

  static const Color darkPrimary = Color(0xFF8AB4F8);
  static const Color darkPrimaryContainer = Color(0xFF174EA6);
  static const Color darkBackground = Color(0xFF202124);
  static const Color darkSurface = Color(0xFF292A2D);
  static const Color darkSurfaceVariant = Color(0xFF303134);
  static const Color darkTextPrimary = Color(0xFFE8EAED);
  static const Color darkTextSecondary = Color(0xFFBDC1C6);
  static const Color darkDivider = Color(0xFF3C4043);
}

/// Builds the light and dark [ThemeData] used by [MaterialApp].
///
/// Both themes are generated from a Material 3 seed color and then overridden
/// with the exact [AppColors] values so the UI matches the requested Material
/// You palette regardless of seed-derived tones.
abstract final class AppTheme {
  static ThemeData light() {
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.lightPrimary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.lightPrimary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.lightPrimaryContainer,
          onPrimaryContainer: AppColors.lightTextPrimary,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          surfaceContainerHighest: AppColors.lightSurfaceVariant,
          surfaceContainerHigh: AppColors.lightSurfaceVariant,
          onSurfaceVariant: AppColors.lightTextSecondary,
          outline: AppColors.lightDivider,
          outlineVariant: AppColors.lightDivider,
        );

    return _base(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
    );
  }

  static ThemeData dark() {
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.darkPrimary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.darkPrimary,
          onPrimary: AppColors.darkBackground,
          primaryContainer: AppColors.darkPrimaryContainer,
          onPrimaryContainer: AppColors.darkTextPrimary,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          surfaceContainerHighest: AppColors.darkSurfaceVariant,
          surfaceContainerHigh: AppColors.darkSurfaceVariant,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkDivider,
          outlineVariant: AppColors.darkDivider,
        );

    return _base(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
    );
  }

  static ThemeData _base({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
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
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.outlineVariant,
        thumbColor: colorScheme.primary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

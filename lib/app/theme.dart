import 'package:flutter/material.dart';

/// Theme colors matching the requested Material You palette.
abstract final class AppColors {
  static const Color lightPrimary = Color(0xFF1A73E8);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF202124);

  static const Color darkPrimary = Color(0xFF8AB4F8);
  static const Color darkBackground = Color(0xFF202124);
  static const Color darkSurface = Color(0xFF292A2D);
  static const Color darkText = Color(0xFFE8EAED);
}

/// Builds the light and dark [ThemeData] used by [MaterialApp].
///
/// Both themes are generated from a Material 3 seed color ([ColorScheme.fromSeed])
/// and then overridden with the exact [AppColors] values so the UI matches the
/// requested Material You palette regardless of the seed-derived tones.
abstract final class AppTheme {
  /// Light Material 3 theme.
  static ThemeData light() {
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.lightPrimary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.lightPrimary,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightText,
        );

    return _base(Brightness.light).copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: colorScheme,
    );
  }

  /// Dark Material 3 theme.
  static ThemeData dark() {
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.darkPrimary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.darkPrimary,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
        );

    return _base(Brightness.dark).copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: colorScheme,
    );
  }

  static ThemeData _base(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}

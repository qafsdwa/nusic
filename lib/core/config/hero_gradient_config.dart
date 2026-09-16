import 'dart:ui' show Color;

import 'config_color.dart';

/// Gradient stops for the home hero card.
///
/// The hero is the app's one large decorative surface. Its wash spans several
/// hues and does not map onto a single Material 3 colour role, so rather than
/// being hardcoded in the widget it gets its own config entry — which is what
/// lets the palette be retuned without touching Dart.
///
/// Stops are ordered from top-left to bottom-right, matching the widget's
/// `LinearGradient`.
class HeroGradientConfig {
  const HeroGradientConfig({required this.light, required this.dark});

  /// Stops used when the active theme is light.
  final List<Color> light;

  /// Stops used when the active theme is dark.
  final List<Color> dark;

  static const HeroGradientConfig fallback = HeroGradientConfig(
    light: <Color>[Color(0xFFDCE7FB), Color(0xFFE8E0FB), Color(0xFFFBE3EE)],
    dark: <Color>[Color(0xFF1F2A44), Color(0xFF2E2344), Color(0xFF3E2135)],
  );

  factory HeroGradientConfig.fromJson(
    Map<String, dynamic> json, {
    required HeroGradientConfig fallback,
  }) {
    return HeroGradientConfig(
      light: parseConfigColorList(json['light'], fallback.light),
      dark: parseConfigColorList(json['dark'], fallback.dark),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'light': configColorListToHex(light),
      'dark': configColorListToHex(dark),
    };
  }
}

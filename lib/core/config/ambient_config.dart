import 'dart:ui' show Color;

import 'config_color.dart';

/// Colours for the ambient shell wash.
///
/// The shell paints a few very large, heavily blurred blobs behind the app
/// surface. Like the hero gradient this wash spans several hues and maps onto no
/// single Material 3 colour role, so it lives in config rather than hardcoded in
/// a widget.
///
/// Entries are **not** gradient stops. They are used in order as the fills of
/// fixed-position blobs, so the list length sets how many blobs there are.
class AmbientConfig {
  const AmbientConfig({required this.light, required this.dark});

  /// Blob colours used when the active theme is light.
  final List<Color> light;

  /// Blob colours used when the active theme is dark.
  final List<Color> dark;

  static const AmbientConfig fallback = AmbientConfig(
    light: <Color>[
      Color(0xFFD5E2FC),
      Color(0xFFF0DCF8),
      Color(0xFFFDE0E6),
      Color(0xFFD9EEF8),
    ],
    dark: <Color>[
      Color(0xFF1B2233),
      Color(0xFF2A2036),
      Color(0xFF33202C),
      Color(0xFF16202E),
    ],
  );

  factory AmbientConfig.fromJson(
    Map<String, dynamic> json, {
    required AmbientConfig fallback,
  }) {
    return AmbientConfig(
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

import 'dart:ui' show Color;

import 'config_color.dart';

/// Configuration for the floating player bar's liquid glass surface.
///
/// Colors are stored separately from their opacities so the JSON file stays
/// readable and each layer (surface, border, highlight, shadow) can be tuned
/// independently.
class GlassConfig {
  const GlassConfig({
    required this.blur,
    required this.borderWidth,
    required this.shadowBlurRadius,
    required this.shadowSpreadRadius,
    required this.shadowOffsetY,
    required this.light,
    required this.dark,
  });

  final double blur;
  final double borderWidth;
  final double shadowBlurRadius;
  final double shadowSpreadRadius;
  final double shadowOffsetY;
  final GlassPalette light;
  final GlassPalette dark;

  static const GlassConfig fallback = GlassConfig(
    blur: 24,
    borderWidth: 1,
    shadowBlurRadius: 28,
    shadowSpreadRadius: 1,
    shadowOffsetY: 8,
    light: GlassPalette.lightFallback,
    dark: GlassPalette.darkFallback,
  );

  factory GlassConfig.fromJson(Map<String, dynamic> json) {
    final Object? lightJson = json['light'];
    final Object? darkJson = json['dark'];

    return GlassConfig(
      blur: parseConfigDouble(json['blur'], fallback.blur),
      borderWidth: parseConfigDouble(json['borderWidth'], fallback.borderWidth),
      shadowBlurRadius: parseConfigDouble(
        json['shadowBlurRadius'],
        fallback.shadowBlurRadius,
      ),
      shadowSpreadRadius: parseConfigDouble(
        json['shadowSpreadRadius'],
        fallback.shadowSpreadRadius,
      ),
      shadowOffsetY: parseConfigDouble(
        json['shadowOffsetY'],
        fallback.shadowOffsetY,
      ),
      light: lightJson is Map<String, dynamic>
          ? GlassPalette.fromJson(
              lightJson,
              fallback: GlassPalette.lightFallback,
            )
          : fallback.light,
      dark: darkJson is Map<String, dynamic>
          ? GlassPalette.fromJson(darkJson, fallback: GlassPalette.darkFallback)
          : fallback.dark,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'blur': blur,
      'borderWidth': borderWidth,
      'shadowBlurRadius': shadowBlurRadius,
      'shadowSpreadRadius': shadowSpreadRadius,
      'shadowOffsetY': shadowOffsetY,
      'light': light.toJson(),
      'dark': dark.toJson(),
    };
  }
}

/// Light or dark glass layer values.
class GlassPalette {
  const GlassPalette({
    required this.surfaceStart,
    required this.surfaceStartOpacity,
    required this.surfaceEnd,
    required this.surfaceEndOpacity,
    required this.borderStart,
    required this.borderStartOpacity,
    required this.borderMiddle,
    required this.borderMiddleOpacity,
    required this.borderEnd,
    required this.borderEndOpacity,
    required this.highlight,
    required this.highlightOpacity,
    required this.shadow,
    required this.shadowOpacity,
  });

  final Color surfaceStart;
  final double surfaceStartOpacity;
  final Color surfaceEnd;
  final double surfaceEndOpacity;
  final Color borderStart;
  final double borderStartOpacity;
  final Color borderMiddle;
  final double borderMiddleOpacity;
  final Color borderEnd;
  final double borderEndOpacity;
  final Color highlight;
  final double highlightOpacity;
  final Color shadow;
  final double shadowOpacity;

  static const GlassPalette lightFallback = GlassPalette(
    surfaceStart: Color(0xFFFFFFFF),
    surfaceStartOpacity: 0.76,
    surfaceEnd: Color(0xFFFFFFFF),
    surfaceEndOpacity: 0.56,
    borderStart: Color(0xFFFFFFFF),
    borderStartOpacity: 0.92,
    borderMiddle: Color(0xFFFFFFFF),
    borderMiddleOpacity: 0.30,
    borderEnd: Color(0xFFFFFFFF),
    borderEndOpacity: 0.70,
    highlight: Color(0xFFFFFFFF),
    highlightOpacity: 0.32,
    shadow: Color(0xFF000000),
    shadowOpacity: 0.08,
  );

  static const GlassPalette darkFallback = GlassPalette(
    surfaceStart: Color(0xFF2A2B2F),
    surfaceStartOpacity: 0.78,
    surfaceEnd: Color(0xFF1F2023),
    surfaceEndOpacity: 0.66,
    borderStart: Color(0xFFFFFFFF),
    borderStartOpacity: 0.22,
    borderMiddle: Color(0xFFFFFFFF),
    borderMiddleOpacity: 0.04,
    borderEnd: Color(0xFFFFFFFF),
    borderEndOpacity: 0.10,
    highlight: Color(0xFFFFFFFF),
    highlightOpacity: 0.10,
    shadow: Color(0xFF000000),
    shadowOpacity: 0.25,
  );

  Color get surfaceStartColor =>
      surfaceStart.withValues(alpha: surfaceStartOpacity);
  Color get surfaceEndColor => surfaceEnd.withValues(alpha: surfaceEndOpacity);
  Color get borderStartColor =>
      borderStart.withValues(alpha: borderStartOpacity);
  Color get borderMiddleColor =>
      borderMiddle.withValues(alpha: borderMiddleOpacity);
  Color get borderEndColor => borderEnd.withValues(alpha: borderEndOpacity);
  Color get highlightColor => highlight.withValues(alpha: highlightOpacity);
  Color get shadowColor => shadow.withValues(alpha: shadowOpacity);

  factory GlassPalette.fromJson(
    Map<String, dynamic> json, {
    required GlassPalette fallback,
  }) {
    return GlassPalette(
      surfaceStart: parseConfigColor(
        json['surfaceStart'],
        fallback.surfaceStart,
      ),
      surfaceStartOpacity: parseConfigOpacity(
        json['surfaceStartOpacity'],
        fallback.surfaceStartOpacity,
      ),
      surfaceEnd: parseConfigColor(json['surfaceEnd'], fallback.surfaceEnd),
      surfaceEndOpacity: parseConfigOpacity(
        json['surfaceEndOpacity'],
        fallback.surfaceEndOpacity,
      ),
      borderStart: parseConfigColor(json['borderStart'], fallback.borderStart),
      borderStartOpacity: parseConfigOpacity(
        json['borderStartOpacity'],
        fallback.borderStartOpacity,
      ),
      borderMiddle: parseConfigColor(
        json['borderMiddle'],
        fallback.borderMiddle,
      ),
      borderMiddleOpacity: parseConfigOpacity(
        json['borderMiddleOpacity'],
        fallback.borderMiddleOpacity,
      ),
      borderEnd: parseConfigColor(json['borderEnd'], fallback.borderEnd),
      borderEndOpacity: parseConfigOpacity(
        json['borderEndOpacity'],
        fallback.borderEndOpacity,
      ),
      highlight: parseConfigColor(json['highlight'], fallback.highlight),
      highlightOpacity: parseConfigOpacity(
        json['highlightOpacity'],
        fallback.highlightOpacity,
      ),
      shadow: parseConfigColor(json['shadow'], fallback.shadow),
      shadowOpacity: parseConfigOpacity(
        json['shadowOpacity'],
        fallback.shadowOpacity,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'surfaceStart': configColorToHex(surfaceStart),
      'surfaceStartOpacity': surfaceStartOpacity,
      'surfaceEnd': configColorToHex(surfaceEnd),
      'surfaceEndOpacity': surfaceEndOpacity,
      'borderStart': configColorToHex(borderStart),
      'borderStartOpacity': borderStartOpacity,
      'borderMiddle': configColorToHex(borderMiddle),
      'borderMiddleOpacity': borderMiddleOpacity,
      'borderEnd': configColorToHex(borderEnd),
      'borderEndOpacity': borderEndOpacity,
      'highlight': configColorToHex(highlight),
      'highlightOpacity': highlightOpacity,
      'shadow': configColorToHex(shadow),
      'shadowOpacity': shadowOpacity,
    };
  }
}

import 'dart:ui' show Color;

/// Parses a `#RRGGBB` or `#AARRGGBB` config value.
Color parseConfigColor(Object? value, Color fallback) {
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

/// Converts a [Color] to an `#AARRGGBB` config value.
String configColorToHex(Color color) {
  final String hex = color
      .toARGB32()
      .toRadixString(16)
      .padLeft(8, '0')
      .toUpperCase();
  return '#$hex';
}

/// Parses an opacity value and clamps it to `0.0..1.0`.
double parseConfigOpacity(Object? value, double fallback) {
  if (value is num) {
    return value.toDouble().clamp(0.0, 1.0);
  }
  return fallback;
}

/// Parses a non-negative double config value.
double parseConfigDouble(Object? value, double fallback) {
  if (value is num) {
    final double parsed = value.toDouble();
    return parsed < 0 ? 0 : parsed;
  }
  return fallback;
}

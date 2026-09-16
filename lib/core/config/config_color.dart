import 'dart:ui' show Color;

/// Parses a `#RRGGBB` or `#AARRGGBB` config value, or `null` when the value is
/// not a valid colour string.
Color? tryParseConfigColor(Object? value) {
  if (value is! String) {
    return null;
  }

  String hex = value.trim().replaceFirst('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length != 8) {
    return null;
  }

  final int? parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? null : Color(parsed);
}

/// Parses a `#RRGGBB` or `#AARRGGBB` config value.
Color parseConfigColor(Object? value, Color fallback) {
  return tryParseConfigColor(value) ?? fallback;
}

/// Parses a JSON array of colour strings.
///
/// All-or-nothing on purpose: a partially parsed gradient would render as
/// neither the configured value nor the fallback, which is worse than either.
/// Returns [fallback] when the value is not a non-empty list or when any entry
/// is invalid.
List<Color> parseConfigColorList(Object? value, List<Color> fallback) {
  if (value is! List || value.isEmpty) {
    return fallback;
  }

  final List<Color> colors = <Color>[];
  for (final Object? entry in value) {
    final Color? color = tryParseConfigColor(entry);
    if (color == null) {
      return fallback;
    }
    colors.add(color);
  }
  return List<Color>.unmodifiable(colors);
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

/// Converts a list of [Color]s to `#AARRGGBB` config values.
List<String> configColorListToHex(List<Color> colors) {
  return <String>[for (final Color color in colors) configColorToHex(color)];
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

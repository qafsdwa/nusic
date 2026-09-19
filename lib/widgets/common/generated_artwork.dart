import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Generated illustrative cover scenes.
///
/// Phase 1 ships no binary image assets: every cover is drawn procedurally, so
/// the UI is complete offline and nothing has to be licensed. A scene is picked
/// from a stable hash of the cover key, which keeps a given song's artwork
/// identical across runs and platforms.
///
/// The enum order is load-bearing. It is tuned so the mock library lays out the
/// way the design does — `Midnight Drive` gets the sunset, `冬日挽歌` the winter
/// night, `Lemon` the warm abstract, `晴天` the daylight, `The Nights` the
/// nebula. Reordering the values reshuffles every cover in the app.
enum GeneratedScene {
  /// Lemon — warm yellow, soft cream shapes.
  warmAbstract,

  /// Spare scene; no mock cover lands here, but the hash space needs the extra
  /// bucket to keep the five designed covers from colliding.
  auroraSky,

  /// 晴天 — bright sky, low sun, a lone figure.
  daylight,

  /// The Nights — deep violet, ringed planet, stars.
  nebula,

  /// Fix You — layered teal ridges in mist.
  forestMist,

  /// 冬日挽歌 — cold blue, low moon, snow.
  winterNight,

  /// Midnight Drive — sun setting into the sea.
  sunsetSea;

  /// The scene a given [key] maps to.
  ///
  /// FNV-1a over the key's UTF-16 code units plus a final `>> 13` avalanche.
  /// Deliberately not `String.hashCode`: Dart randomises that per process, which
  /// would give a song different artwork on every launch.
  static GeneratedScene forKey(String key) {
    final int mixed = _fnv1a(key);
    return values[(mixed ^ (mixed >> 13)) % values.length];
  }
}

/// 32-bit FNV-1a over [key], exact on web as well as native.
///
/// The multiply is split into 16-bit halves because a plain
/// `hash * 0x01000193` reaches ~2^56, past the 2^53 integer range of a JS
/// number. Without the split the hash would silently differ on Flutter web.
int _fnv1a(String key) {
  int hash = 0x811C9DC5;
  for (final int unit in key.codeUnits) {
    final int value = hash ^ unit;
    final int low = value & 0xFFFF;
    final int high = (value >> 16) & 0xFFFF;
    hash =
        (low * 0x01000193 + ((high * 0x01000193 & 0xFFFF) << 16)) & 0xFFFFFFFF;
  }
  return hash;
}

/// Stable 32-bit hash of [key].
///
/// Exposed so other generated artwork (the monogram fallback) can pick colours
/// from the same stable sequence instead of `String.hashCode`, which Dart
/// randomises per process.
int stableArtworkHash(String key) => _fnv1a(key);

/// Decorative artwork that fills whatever box it is given.
///
/// Use this directly for non-square surfaces such as the home hero banner;
/// [CoverArtwork] wraps it for the square cover case.
class GeneratedArtwork extends StatelessWidget {
  const GeneratedArtwork({super.key, required this.seedKey, this.scene});

  /// Key the scene is derived from when [scene] is null.
  final String seedKey;

  /// Forces a specific scene. `null` derives one from [seedKey].
  final GeneratedScene? scene;

  @override
  Widget build(BuildContext context) {
    final String key = seedKey;
    // Decorative only: the song or playlist title is always rendered next to
    // the artwork, so announcing the image too would just duplicate it.
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _ScenePainter(
          scene: scene ?? GeneratedScene.forKey(key),
          seed: _fnv1a(key),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter({required this.scene, required this.seed});

  final GeneratedScene scene;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    canvas.clipRect(Offset.zero & size);

    switch (scene) {
      case GeneratedScene.sunsetSea:
        _paintSunsetSea(canvas, size);
      case GeneratedScene.winterNight:
        _paintWinterNight(canvas, size);
      case GeneratedScene.warmAbstract:
        _paintWarmAbstract(canvas, size);
      case GeneratedScene.daylight:
        _paintDaylight(canvas, size);
      case GeneratedScene.nebula:
        _paintNebula(canvas, size);
      case GeneratedScene.forestMist:
        _paintForestMist(canvas, size);
      case GeneratedScene.auroraSky:
        _paintAuroraSky(canvas, size);
    }
  }

  /// Fills [rect] with a vertical gradient.
  void _fill(
    Canvas canvas,
    Rect rect,
    List<Color> colors, [
    List<double>? stops,
  ]) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(rect),
    );
  }

  /// A soft luminous blob, used for suns, moons and nebulae.
  void _glow(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.55),
    );
  }

  void _stars(Canvas canvas, Size size, int count, Color color) {
    final double unit = size.shortestSide;
    final math.Random random = math.Random(seed);
    final Paint paint = Paint()..color = color;
    for (int i = 0; i < count; i++) {
      final Offset center = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height * 0.7,
      );
      canvas.drawCircle(
        center,
        unit * 0.008 * (0.5 + random.nextDouble()),
        paint,
      );
    }
  }

  /// Sun setting into the sea.
  ///
  /// Feature sizes are driven by the **shortest side**, not the width. The hero
  /// banner is roughly 4:1, and width-scaled features turn the sun into a disc
  /// wider than the horizon is tall.
  void _paintSunsetSea(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double s = size.shortestSide;
    final double horizon = h * 0.60;

    _fill(
      canvas,
      Rect.fromLTWH(0, 0, w, horizon),
      const <Color>[
        Color(0xFF1B2A5B),
        Color(0xFF5B4A8A),
        Color(0xFFE8836B),
        Color(0xFFF7C08A),
      ],
      const <double>[0.0, 0.42, 0.80, 1.0],
    );

    final Offset sun = Offset(w * 0.52, horizon - h * 0.02);
    _glow(canvas, sun, s * 0.34, const Color(0x77FFD9A0));
    canvas.drawCircle(sun, s * 0.10, Paint()..color = const Color(0xFFFFF2D0));

    final Rect sea = Rect.fromLTWH(0, horizon, w, h - horizon);
    _fill(
      canvas,
      sea,
      const <Color>[Color(0xFF6B5A92), Color(0xFF2C3260), Color(0xFF131933)],
      const <double>[0.0, 0.5, 1.0],
    );

    // Light column reflected straight down from the sun. Blurred, because a hard
    // edged rectangle reads as a grey box pasted onto the water rather than as
    // a reflection.
    final Rect column = Rect.fromLTWH(
      sun.dx - s * 0.13,
      horizon,
      s * 0.26,
      h - horizon,
    );
    canvas.drawRect(
      column,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x99FFD9A0), Color(0x00FFD9A0)],
        ).createShader(column)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.07),
    );

    // Ripples, bunched toward the horizon where the water is compressed.
    final math.Random random = math.Random(seed);
    for (int i = 0; i < 10; i++) {
      final double t = i / 10;
      final double y = horizon + (h - horizon) * t * t;
      final double rippleWidth = w * (0.08 + random.nextDouble() * 0.18);
      final double x =
          w * 0.5 - rippleWidth / 2 + (random.nextDouble() - 0.5) * w * 0.3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, rippleWidth, math.max(1, s * 0.010)),
          Radius.circular(s),
        ),
        Paint()..color = const Color(0x44FFE6BC),
      );
    }

    final Path headland = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.79)
      ..quadraticBezierTo(w * 0.17, h * 0.70, w * 0.35, h * 0.85)
      ..quadraticBezierTo(w * 0.44, h * 0.94, w * 0.52, h)
      ..close();
    canvas.drawPath(headland, Paint()..color = const Color(0xFF0D1124));
  }

  void _paintWinterNight(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double s = size.shortestSide;

    _fill(
      canvas,
      Offset.zero & size,
      const <Color>[Color(0xFF0B1226), Color(0xFF1E2A4E), Color(0xFF3A3568)],
      const <double>[0.0, 0.55, 1.0],
    );

    _stars(canvas, size, 40, const Color(0xCCFFFFFF));

    final Offset moon = Offset(w * 0.70, h * 0.26);
    _glow(canvas, moon, s * 0.26, const Color(0x55AFC8FF));
    canvas.drawCircle(
      moon,
      s * 0.105,
      Paint()..color = const Color(0xFFEAF1FF),
    );

    // Two ridges of snow, the far one lighter so the depth reads.
    final Path far = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.80)
      ..quadraticBezierTo(w * 0.28, h * 0.66, w * 0.58, h * 0.80)
      ..quadraticBezierTo(w * 0.82, h * 0.90, w, h * 0.82)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFF6E7BA8));

    final Path near = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.90)
      ..quadraticBezierTo(w * 0.34, h * 0.80, w * 0.68, h * 0.92)
      ..quadraticBezierTo(w * 0.86, h * 0.97, w, h * 0.93)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(near, Paint()..color = const Color(0xFFDDE6FA));

    final math.Random random = math.Random(seed);
    final Paint snow = Paint()..color = const Color(0x99FFFFFF);
    for (int i = 0; i < 28; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * w, random.nextDouble() * h * 0.85),
        s * 0.010 * (0.4 + random.nextDouble()),
        snow,
      );
    }
  }

  void _paintWarmAbstract(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double s = size.shortestSide;

    _fill(
      canvas,
      Offset.zero & size,
      const <Color>[Color(0xFFFFE9A3), Color(0xFFFFD24D), Color(0xFFF5B417)],
      const <double>[0.0, 0.55, 1.0],
    );

    // A large cream mass behind the subject, off-centre so the square does not
    // read as a symmetrical logo.
    canvas.save();
    canvas.translate(w * 0.52, h * 0.46);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 0.92, height: s * 0.66),
      Paint()..color = const Color(0xE6FFF8E1),
    );
    canvas.restore();

    canvas.drawCircle(
      Offset(w * 0.30, h * 0.72),
      s * 0.22,
      Paint()..color = const Color(0xCCFFFFFF),
    );
    canvas.drawCircle(
      Offset(w * 0.74, h * 0.26),
      s * 0.14,
      Paint()..color = const Color(0x99FF9F1C),
    );

    final Paint stroke = Paint()
      ..color = const Color(0x55B07D00)
      ..strokeWidth = math.max(1, s * 0.014)
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final double y = h * (0.30 + i * 0.16);
      canvas.drawLine(
        Offset(w * 0.16, y),
        Offset(w * 0.40, y - h * 0.05),
        stroke,
      );
    }
  }

  void _paintDaylight(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double s = size.shortestSide;

    _fill(
      canvas,
      Offset.zero & size,
      const <Color>[Color(0xFF5FB6E8), Color(0xFFA9DCF5), Color(0xFFF3E2C4)],
      const <double>[0.0, 0.52, 1.0],
    );

    final Offset sun = Offset(w * 0.80, h * 0.18);
    _glow(canvas, sun, s * 0.34, const Color(0x88FFF3C4));
    canvas.drawCircle(sun, s * 0.090, Paint()..color = const Color(0xFFFFFBE8));

    final Path ground = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.5, h * 0.78, w, h * 0.88)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(ground, Paint()..color = const Color(0xFF8FA36B));

    // A lone figure: head plus a tapered body. Enough to read as a person at
    // cover size without pretending to be a portrait.
    final double cx = w * 0.44;
    final Paint figure = Paint()..color = const Color(0xFF3B3A46);
    final Path body = Path()
      ..moveTo(cx - s * 0.070, h * 0.90)
      ..quadraticBezierTo(cx - s * 0.058, h * 0.72, cx - s * 0.032, h * 0.66)
      ..lineTo(cx + s * 0.032, h * 0.66)
      ..quadraticBezierTo(cx + s * 0.058, h * 0.72, cx + s * 0.070, h * 0.90)
      ..close();
    canvas.drawPath(body, figure);
    canvas.drawCircle(Offset(cx, h * 0.605), s * 0.050, figure);
  }

  void _paintNebula(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double s = size.shortestSide;

    _fill(
      canvas,
      Offset.zero & size,
      const <Color>[Color(0xFF140B2E), Color(0xFF2A1A5E), Color(0xFF3D1F5C)],
      const <double>[0.0, 0.6, 1.0],
    );

    _stars(canvas, size, 55, const Color(0xCCE8D9FF));

    final Offset planet = Offset(w * 0.62, h * 0.42);
    _glow(canvas, planet, s * 0.40, const Color(0x66A56BFF));
    canvas.drawCircle(
      planet,
      s * 0.20,
      Paint()..color = const Color(0xFF7A4BD6),
    );

    // Terminator: the lit crescent, drawn as a lighter circle offset toward the
    // light source and clipped to the planet.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: planet, radius: s * 0.20)),
    );
    canvas.drawCircle(
      Offset(planet.dx - s * 0.07, planet.dy - s * 0.05),
      s * 0.19,
      Paint()..color = const Color(0xFFB98CFF),
    );
    canvas.restore();

    // Ring, seen almost edge-on.
    canvas.save();
    canvas.translate(planet.dx, planet.dy);
    canvas.rotate(-0.42);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * 0.68, height: s * 0.16),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, s * 0.022)
        ..color = const Color(0x99D9C2FF),
    );
    canvas.restore();
  }

  void _paintForestMist(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double s = size.shortestSide;

    _fill(
      canvas,
      Offset.zero & size,
      const <Color>[Color(0xFFCDEBE4), Color(0xFF8FC9BC), Color(0xFF5E9E93)],
      const <double>[0.0, 0.55, 1.0],
    );

    _glow(
      canvas,
      Offset(w * 0.24, h * 0.20),
      s * 0.30,
      const Color(0x66FFFFFF),
    );

    // Four ridges, each darker and lower than the last, which is what sells the
    // depth without any real lighting model.
    const List<Color> ridgeColors = <Color>[
      Color(0x668FB3AC),
      Color(0x9982ABA3),
      Color(0xCC4F7F78),
      Color(0xFF2F5B56),
    ];
    const List<double> ridgeTops = <double>[0.46, 0.56, 0.68, 0.80];
    const List<double> ridgePeaks = <double>[0.30, 0.19, 0.12, 0.06];

    for (int i = 0; i < ridgeColors.length; i++) {
      final double top = h * ridgeTops[i];
      final double peak = h * ridgePeaks[i];
      final double crest = w * (0.24 + i * 0.18);
      final Path ridge = Path()
        ..moveTo(0, h)
        ..lineTo(0, top)
        ..quadraticBezierTo(crest, top - peak, w, top + h * 0.04)
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(ridge, Paint()..color = ridgeColors[i]);
    }

    // Mist bands, one per ridge line.
    for (int i = 0; i < 3; i++) {
      final double y = h * (0.52 + i * 0.12);
      final Rect band = Rect.fromLTWH(0, y, w, h * 0.05);
      canvas.drawRect(
        band,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              Color(0x00FFFFFF),
              Color(0x66FFFFFF),
              Color(0x00FFFFFF),
            ],
          ).createShader(band),
      );
    }
  }

  void _paintAuroraSky(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double s = size.shortestSide;

    _fill(
      canvas,
      Offset.zero & size,
      const <Color>[Color(0xFF070D1F), Color(0xFF102046), Color(0xFF16305A)],
      const <double>[0.0, 0.5, 1.0],
    );

    _stars(canvas, size, 50, const Color(0xBBFFFFFF));

    const List<Color> ribbons = <Color>[
      Color(0x8841E0A0),
      Color(0x777F6BFF),
      Color(0x6634D3C8),
    ];
    for (int i = 0; i < ribbons.length; i++) {
      final double y = h * (0.28 + i * 0.13);
      final Path ribbon = Path()
        ..moveTo(-w * 0.1, y)
        ..quadraticBezierTo(w * 0.35, y - h * 0.22, w * 0.65, y - h * 0.04)
        ..quadraticBezierTo(w * 0.85, y + h * 0.10, w * 1.1, y - h * 0.10);
      canvas.drawPath(
        ribbon,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * (0.10 - i * 0.02)
          ..strokeCap = StrokeCap.round
          ..color = ribbons[i]
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.035),
      );
    }

    final Path ground = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.90)
      ..quadraticBezierTo(w * 0.5, h * 0.84, w, h * 0.91)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(ground, Paint()..color = const Color(0xFF05080F));
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) {
    return oldDelegate.scene != scene || oldDelegate.seed != seed;
  }
}

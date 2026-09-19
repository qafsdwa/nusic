import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/ambient_config.dart';
import '../../core/config/app_config_provider.dart';

/// Full-window decorative wash painted behind the app shell.
///
/// Draws one soft radial blob per `theme.ambient` colour. The blobs use a
/// radial gradient fading to transparent rather than a blurred circle: it is
/// the same soft look for none of [MaskFilter.blur]'s per-frame cost, and this
/// surface is repainted on every window resize.
///
/// Blob positions are fixed fractions of the box so the composition is stable at
/// any window size. A size-dependent or randomised layout would make the
/// background crawl while the user drags the window edge.
class AmbientBackground extends ConsumerWidget {
  const AmbientBackground({super.key});

  /// Blob centres as fractions of width/height.
  static const List<Offset> _centers = <Offset>[
    Offset(0.06, 0.00),
    Offset(0.94, 0.08),
    Offset(0.78, 0.96),
    Offset(0.14, 0.86),
  ];

  /// Blob radii as a fraction of the shorter side.
  static const List<double> _radiusScales = <double>[0.62, 0.54, 0.66, 0.50];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AmbientConfig ambient = ref.watch(appConfigProvider).theme.ambient;
    final List<Color> colors = theme.brightness == Brightness.dark
        ? ambient.dark
        : ambient.light;

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AmbientPainter(colors: colors),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || colors.isEmpty) {
      return;
    }

    final double shortest = size.shortestSide;
    final List<Offset> centers = AmbientBackground._centers;
    final List<double> scales = AmbientBackground._radiusScales;

    for (int i = 0; i < colors.length; i++) {
      final Offset unit = centers[i % centers.length];
      final Offset center = Offset(unit.dx * size.width, unit.dy * size.height);
      final double radius = shortest * scales[i % scales.length];
      final Rect bounds = Rect.fromCircle(center: center, radius: radius);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[colors[i], colors[i].withValues(alpha: 0)],
          ).createShader(bounds),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) {
    return !listEquals(oldDelegate.colors, colors);
  }
}

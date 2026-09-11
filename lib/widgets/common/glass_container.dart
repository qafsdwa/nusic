import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

/// A single-purpose frosted glass surface.
///
/// Keep usage rare. In Muse Player the floating player bar is the primary
/// glass element; ordinary cards and lists should stay opaque so
/// [BackdropFilter] cost stays low.
///
/// The optional [gradient], [borderGradient] and [highlight] parameters add the
/// subtle "liquid glass" treatment used by the floating player bar:
/// - a soft diagonal glass body gradient;
/// - a specular gradient border;
/// - a faint diagonal highlight across the top-left.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppSizes.floatingPlayerBarRadius,
    this.blur = 22,
    this.borderWidth = 1,
    this.opacity = 0.68,
    this.padding,
    this.color,
    this.border,
    this.shadow,
    this.gradient,
    this.borderGradient,
    this.highlight = false,
    this.highlightColor,
    this.highlightOpacity,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final double borderWidth;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? shadow;
  final Gradient? gradient;
  final Gradient? borderGradient;
  final bool highlight;
  final Color? highlightColor;
  final double? highlightOpacity;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;

    final Color resolvedColor =
        color ?? (isDark ? const Color(0xFF252629) : Colors.white);
    final Border resolvedBorder =
        border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.65),
          width: borderWidth,
        );
    final BorderRadius radius = BorderRadius.circular(borderRadius);
    final Color sheenColor = highlightColor ?? Colors.white;
    final double resolvedHighlightOpacity =
        highlightOpacity ?? (isDark ? 0.10 : 0.32);

    return Container(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: gradient == null
                  ? resolvedColor.withValues(alpha: opacity)
                  : null,
              gradient: gradient,
              borderRadius: radius,
              border: borderGradient == null ? resolvedBorder : null,
            ),
            child: Stack(
              children: <Widget>[
                if (highlight)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              sheenColor.withValues(
                                alpha: resolvedHighlightOpacity,
                              ),
                              sheenColor.withValues(
                                alpha: resolvedHighlightOpacity * 0.06,
                              ),
                              Colors.transparent,
                            ],
                            stops: const <double>[0.0, 0.28, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(padding: padding ?? EdgeInsets.zero, child: child),
                if (borderGradient != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _GradientBorderPainter(
                          borderRadius: radius,
                          gradient: borderGradient!,
                          borderWidth: borderWidth,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a 1px gradient stroke around a rounded rectangle.
class _GradientBorderPainter extends CustomPainter {
  const _GradientBorderPainter({
    required this.borderRadius,
    required this.gradient,
    required this.borderWidth,
  });

  final BorderRadius borderRadius;
  final Gradient gradient;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(borderRadius.toRRect(rect).deflate(0.5), paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth;
  }
}

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

/// A single-purpose frosted glass surface.
///
/// Keep usage rare. In Muse Player the floating player bar is the primary
/// glass element; ordinary cards and lists should stay opaque so
/// [BackdropFilter] cost stays low.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppSizes.floatingPlayerBarRadius,
    this.blur = 22,
    this.opacity = 0.68,
    this.padding,
    this.color,
    this.border,
    this.shadow,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? shadow;

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
          width: 1,
        );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: resolvedColor.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: resolvedBorder,
            ),
            child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ),
        ),
      ),
    );
  }
}

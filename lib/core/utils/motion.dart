import 'package:flutter/material.dart';

/// Motion durations for the app, with reduced-motion handling in one place.
///
/// Every animation goes through [AppMotion.of] so a system-level "reduce
/// motion" preference collapses all of them at once. State changes still
/// happen — they just stop being animated. Feedback survives, spectacle goes.
///
/// Platform switches that feed [MediaQueryData.disableAnimations]:
/// Android "Remove animations", iOS "Reduce Motion", and the desktop
/// equivalents.
abstract final class AppMotion {
  /// Quick feedback for hover and press responses.
  static const Duration fast = Duration(milliseconds: 170);

  /// Default state-change duration.
  static const Duration standard = Duration(milliseconds: 180);

  /// Slightly slower emphasis, used on the larger Now Playing surface.
  static const Duration emphasized = Duration(milliseconds: 200);

  /// Returns [duration], or [Duration.zero] when the platform asks for
  /// reduced motion.
  static Duration of(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}

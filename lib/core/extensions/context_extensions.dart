import 'package:flutter/material.dart';

import '../../app/breakpoints.dart';

/// Responsive helpers scoped to the current [BuildContext].
extension MuseBreakpointContext on BuildContext {
  AppBreakpoint get appBreakpoint =>
      AppBreakpoints.fromWidth(MediaQuery.sizeOf(this).width);

  bool get isMobile => appBreakpoint == AppBreakpoint.mobile;
  bool get isTablet => appBreakpoint == AppBreakpoint.tablet;
  bool get isDesktop => appBreakpoint == AppBreakpoint.desktop;
}

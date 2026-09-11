import 'package:flutter/material.dart';

import '../../app/breakpoints.dart';

/// Minimal responsive slot widget.
///
/// Most pages are responsive by construction (scrolling content that adapts
/// to available width). This widget is used where a compact/tablet/desktop
/// layout branch is clearer than a single `LayoutBuilder`.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return switch (AppBreakpoints.fromWidth(constraints.maxWidth)) {
          AppBreakpoint.mobile => mobile,
          AppBreakpoint.tablet => tablet,
          AppBreakpoint.desktop => desktop,
        };
      },
    );
  }
}

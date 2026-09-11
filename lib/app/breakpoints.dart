/// Responsive breakpoints for Muse Player.
///
/// The floating player bar exists on every breakpoint; only the surrounding
/// navigation chrome and content density change.
enum AppBreakpoint { mobile, tablet, desktop }

/// Width thresholds shared by the shell and responsive widgets.
abstract final class AppBreakpoints {
  static const double mobileMax = 699.99;
  static const double tabletMin = 700;
  static const double tabletMax = 1100;

  static AppBreakpoint fromWidth(double width) {
    if (width < tabletMin) {
      return AppBreakpoint.mobile;
    }
    if (width <= tabletMax) {
      return AppBreakpoint.tablet;
    }
    return AppBreakpoint.desktop;
  }

  static bool isMobile(double width) =>
      fromWidth(width) == AppBreakpoint.mobile;
  static bool isTablet(double width) =>
      fromWidth(width) == AppBreakpoint.tablet;
  static bool isDesktop(double width) =>
      fromWidth(width) == AppBreakpoint.desktop;
}

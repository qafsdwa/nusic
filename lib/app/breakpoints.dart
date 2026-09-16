/// Responsive breakpoints for Muse Player.
///
/// The floating player bar exists on every breakpoint; only the surrounding
/// navigation chrome and content density change.
enum AppBreakpoint { mobile, tablet, desktop }

/// Width thresholds shared by the shell and responsive widgets.
///
/// The three shells map onto Material 3 window size classes rather than onto
/// device names:
///
/// | Shell   | M3 window size class   | Width (dp)  |
/// |---------|------------------------|-------------|
/// | mobile  | compact                | < 600       |
/// | tablet  | medium + expanded      | 600 – 1199  |
/// | desktop | large + extra-large    | >= 1200     |
///
/// The M3 boundaries are 600 / 840 / 1200 / 1600. `medium` and `expanded` share
/// the rail shell, and `large` and `extra-large` share the permanent panel, so
/// only two thresholds are needed here — but they are the M3 ones, not
/// arbitrary device widths. Anything that needs a raw M3 boundary (rather than
/// a shell decision) should use [compactMax] / [mediumMax] / [expandedMax].
abstract final class AppBreakpoints {
  /// M3 `compact` / `medium` boundary.
  static const double compactMax = 599.99;

  /// M3 `medium` / `expanded` boundary.
  static const double mediumMax = 839;

  /// M3 `expanded` / `large` boundary.
  static const double expandedMax = 1199;

  /// Below this width the shell uses bottom navigation (`compact`).
  static const double tabletMin = 600;

  /// At or above this width the shell uses the permanent side panel
  /// (`large` and `extra-large`).
  static const double desktopMin = 1200;

  /// Component-level threshold, not a window size class.
  ///
  /// The home hero card reacts to its *own* width, which is narrower than the
  /// viewport on desktop because page content is centred at
  /// `AppSizes.pageMaxWidth`. Kept here so there is still exactly one place in
  /// the app that defines a width threshold.
  static const double heroCompactMax = 480;

  static AppBreakpoint fromWidth(double width) {
    if (width < tabletMin) {
      return AppBreakpoint.mobile;
    }
    if (width < desktopMin) {
      return AppBreakpoint.tablet;
    }
    return AppBreakpoint.desktop;
  }
}

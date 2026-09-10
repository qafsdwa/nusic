/// Shared spacing and sizing constants for the Muse Player UI.
abstract final class AppSizes {
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  static const double pageMaxWidth = 1200;

  /// Desktop navigation panel width.
  static const double navigationPanelWidth = 220;

  /// Collapsed Material navigation rail width for tablet layouts.
  static const double navigationRailWidth = 80;

  /// Floating player bar metrics.
  static const double floatingPlayerBarHeight = 92;
  static const double floatingPlayerBarRadius = 30;
  static const double floatingPlayerBarHorizontalMargin = 24;
  static const double floatingPlayerBarBottom = 20;

  /// Mobile floating player sits above the Material NavigationBar.
  static const double floatingPlayerBarMobileBottom = 88;

  /// Scroll views must reserve space so the floating player never covers
  /// content or action buttons.
  static const double scrollBottomPadding = 150;

  static const double albumCardRadius = 16;
  static const double searchFieldWidth = 520;
  static const double searchFieldHeight = 46;
}

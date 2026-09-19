/// Shared spacing and sizing constants for the Muse Player UI.
abstract final class AppSizes {
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  /// Content max width for grid and cover-art pages on large windows.
  static const double pageMaxWidth = 1200;

  /// Content max width for text-dense pages (search, settings).
  ///
  /// M3 recommends constraining reading-width content to 840–1040dp on large
  /// and extra-large windows. At 1200dp the text lines get long enough that the
  /// eye loses its place returning to the next line.
  static const double pageMaxWidthText = 1040;

  /// Desktop navigation panel width.
  static const double navigationPanelWidth = 220;

  /// Collapsed Material navigation rail width for tablet layouts.
  static const double navigationRailWidth = 80;

  /// Height of the custom desktop title bar.
  ///
  /// The title bar sits on the ambient wash rather than on the shell surface,
  /// so this is also the band of wash visible above the app pane.
  ///
  /// Tall enough to hold [searchFieldHeight] with clearance; a shorter bar
  /// forces the search field to be squeezed and its icon would clip.
  static const double titleBarHeight = 52;

  /// Gap between the window edge and the app shell surface.
  ///
  /// The ambient wash shows through this gap. It is what makes the shell read
  /// as a floating pane instead of a full-bleed window, so collapsing it to 0
  /// removes the entire background treatment.
  static const double shellMargin = 10;

  /// Corner radius of the app shell surface. On the M3 shape scale rather than
  /// a one-off, unlike [floatingPlayerBarRadius].
  static const double shellRadius = shapeLgIncreased;

  /// Material 3 [NavigationBar] default height.
  static const double navigationBarHeight = 80;

  /// Floating player bar metrics.
  ///
  /// [floatingPlayerBarRadius] is a deliberate departure from the M3 shape
  /// scale: the bar reads as a floating glass slab rather than a sheet, so it
  /// sits between `shapeXl` (28) and `shapeXxl` (48). Documented in
  /// `docs/architecture.md` — keep it documented rather than silently rounded.
  static const double floatingPlayerBarHeight = 92;
  static const double floatingPlayerBarRadius = 30;
  static const double floatingPlayerBarHorizontalMargin = 24;
  static const double floatingPlayerBarBottom = 20;

  /// Scroll views must reserve space so the floating player never covers
  /// content or action buttons.
  static const double scrollBottomPadding = 150;

  static const double searchFieldWidth = 520;
  static const double searchFieldHeight = 46;

  /// Material 3 shape scale, in dp.
  ///
  /// Names follow the `md.sys.shape.corner.*` tokens so a value can be matched
  /// to the spec. Do not introduce radii outside this scale — an off-scale
  /// number (18, 24, 30) is the usual sign of a one-off decision that will
  /// drift the moment the design changes.
  static const double shapeNone = 0;

  /// Chips, snackbars.
  static const double shapeXs = 4;

  /// Text fields, menus.
  static const double shapeSm = 8;

  /// Cards.
  static const double shapeMd = 12;

  /// FABs, navigation drawer.
  static const double shapeLg = 16;

  /// Large-increased (M3 Expressive).
  static const double shapeLgIncreased = 20;

  /// Dialogs, bottom sheets.
  static const double shapeXl = 28;

  /// Extra-extra-large (M3 Expressive).
  static const double shapeXxl = 48;

  /// Buttons, chips, search bars — clamped to half the shortest side.
  static const double shapeFull = 999;
}

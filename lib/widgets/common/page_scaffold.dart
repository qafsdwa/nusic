import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

/// Standard scrollable page body.
///
/// Every top-level page centres its content at [AppSizes.pageMaxWidth] and
/// reserves [AppSizes.scrollBottomPadding] at the bottom so the floating player
/// bar never covers the last row or an action button. Keeping that in one place
/// stops the two constants from drifting apart page by page.
class PageScaffold extends StatelessWidget {
  /// Page built from a fixed list of [children].
  const PageScaffold({
    super.key,
    required this.children,
    this.horizontalPadding = AppSizes.spacingLg,
    this.topPadding = AppSizes.spacingLg,
    this.maxWidth = AppSizes.pageMaxWidth,
  }) : itemCount = 0,
       itemBuilder = null;

  /// Page built lazily from [itemBuilder].
  ///
  /// Use this for long or filtered lists so only visible rows are built.
  const PageScaffold.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.horizontalPadding = AppSizes.spacingLg,
    this.topPadding = AppSizes.spacingLg,
    this.maxWidth = AppSizes.pageMaxWidth,
  }) : children = const <Widget>[];

  final List<Widget> children;

  /// Item count for [PageScaffold.builder]; ignored by the default constructor.
  final int itemCount;

  /// Lazy row builder; `null` means the page uses [children] instead.
  final IndexedWidgetBuilder? itemBuilder;

  final double horizontalPadding;
  final double topPadding;

  /// Content max width. Text-dense pages should pass
  /// [AppSizes.pageMaxWidthText] so reading lines stay scannable.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = EdgeInsets.fromLTRB(
      horizontalPadding,
      topPadding,
      horizontalPadding,
      AppSizes.scrollBottomPadding,
    );

    final IndexedWidgetBuilder? builder = itemBuilder;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: builder != null
            ? ListView.builder(
                padding: padding,
                itemCount: itemCount,
                itemBuilder: builder,
              )
            : ListView(padding: padding, children: children),
      ),
    );
  }
}

/// Centred, non-scrolling page body.
///
/// For pages whose content is sized by the viewport rather than by a scroll
/// extent — the now-playing view is the only current user.
class CenteredPage extends StatelessWidget {
  const CenteredPage({
    super.key,
    required this.child,
    this.maxWidth = AppSizes.pageMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../app/breakpoints.dart';
import '../../app/router.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/constants/app_sizes.dart';
import '../common/search_launcher.dart';

/// Material-styled custom desktop title bar.
///
/// The native title bar is hidden by [setUpDesktopWindow], so this widget owns
/// window dragging, double-click maximize/restore and the window controls.
///
/// It deliberately paints no opaque background: the ambient wash runs behind it,
/// which is what makes the shell surface below read as a floating pane instead
/// of a full-bleed window.
class CustomTitleBar extends ConsumerStatefulWidget {
  const CustomTitleBar({super.key});

  static const double height = AppSizes.titleBarHeight;

  /// Below this width the search field is dropped rather than squeezed. A
  /// 200dp-wide search field reads as broken, and the Home header search is
  /// still available at that size.
  static const double _searchMinWidth = 620;

  @override
  ConsumerState<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends ConsumerState<CustomTitleBar>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _syncMaximizeState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _syncMaximizeState() async {
    try {
      final bool isMaximized = await windowManager.isMaximized();
      if (mounted) {
        setState(() => _isMaximized = isMaximized);
      }
    } catch (_) {
      // The window_manager plugin is unavailable in widget tests and on
      // unsupported platforms. The title bar still renders.
    }
  }

  Future<void> _toggleMaximize() async {
    try {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    } catch (_) {
      // Ignore plugin absence in tests.
    }
  }

  Future<void> _minimize() async {
    try {
      await windowManager.minimize();
    } catch (_) {
      // Ignore plugin absence in tests.
    }
  }

  Future<void> _close() async {
    try {
      await windowManager.close();
    } catch (_) {
      // Ignore plugin absence in tests.
    }
  }

  @override
  void onWindowMaximize() {
    if (mounted) {
      setState(() => _isMaximized = true);
    }
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) {
      setState(() => _isMaximized = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String appName = ref.watch(appConfigProvider).appName;

    return SizedBox(
      height: CustomTitleBar.height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // The title bar spans the same width as the shell, so it can work out
          // the breakpoint itself and align the brand over the navigation column
          // rather than duplicating the shell's layout decision.
          final double leadingWidth = switch (AppBreakpoints.fromWidth(
            constraints.maxWidth,
          )) {
            AppBreakpoint.desktop => AppSizes.navigationPanelWidth,
            AppBreakpoint.tablet => AppSizes.navigationRailWidth,
            AppBreakpoint.mobile => 0,
          };
          final bool showSearch =
              constraints.maxWidth >= CustomTitleBar._searchMinWidth;
          final EdgeInsets brandPadding = EdgeInsets.only(
            left: AppSizes.shellMargin + AppSizes.spacingMd,
          );
          final Widget brand = _BrandLockup(
            appName: appName,
            // Drop the wordmark on the narrow shells, where the navigation
            // column is a rail or absent and horizontal room is scarce.
            showWordmark: leadingWidth >= AppSizes.navigationPanelWidth,
          );

          return Row(
            children: <Widget>[
              if (leadingWidth > 0)
                SizedBox(
                  width: leadingWidth,
                  child: Padding(
                    padding: brandPadding,
                    child: Align(alignment: Alignment.centerLeft, child: brand),
                  ),
                )
              else
                Padding(padding: brandPadding, child: brand),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    // The drag surface sits behind the search field so the whole
                    // bar drags except where a control needs the tap.
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: _toggleMaximize,
                        child: const DragToMoveArea(child: SizedBox.expand()),
                      ),
                    ),
                    if (showSearch)
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: SearchLauncherField(
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRoutes.search);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _WindowControlButton(
                icon: Icons.remove,
                tooltip: '最小化',
                onPressed: _minimize,
              ),
              _WindowControlButton(
                icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
                tooltip: _isMaximized ? '还原' : '最大化',
                onPressed: _toggleMaximize,
              ),
              _WindowControlButton(
                icon: Icons.close,
                tooltip: '关闭',
                onPressed: _close,
                isClose: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Rounded-square glyph plus the app wordmark.
class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.appName, required this.showWordmark});

  final String appName;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(AppSizes.shapeSm),
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            size: 20,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        if (showWordmark) ...<Widget>[
          const SizedBox(width: AppSizes.spacingSm),
          Flexible(
            child: Text(
              appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WindowControlButton extends StatelessWidget {
  const _WindowControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isClose = false,
  });

  final IconData icon;
  final String tooltip;
  final Future<void> Function() onPressed;
  final bool isClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foregroundColor = isClose
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onPressed,
          hoverColor: isClose
              ? theme.colorScheme.errorContainer.withValues(alpha: 0.45)
              : theme.colorScheme.surfaceContainerHighest,
          child: SizedBox(
            width: 46,
            height: CustomTitleBar.height,
            child: Icon(icon, size: 16, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}

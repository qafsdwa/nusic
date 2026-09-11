import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Material-styled custom desktop title bar.
///
/// The native title bar is hidden by [setUpDesktopWindow], so this widget owns
/// window dragging, double-click maximize/restore and the window controls.
class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({super.key});

  static const double height = 44;

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
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
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        height: CustomTitleBar.height,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 14),
            Icon(Icons.graphic_eq, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Muse Player',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: _toggleMaximize,
                child: const DragToMoveArea(child: SizedBox.expand()),
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
        ),
      ),
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

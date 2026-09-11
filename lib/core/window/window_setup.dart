import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// Whether the current platform supports native desktop window management.
bool get isDesktopPlatform {
  if (kIsWeb) {
    return false;
  }

  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// Hides the native title bar and configures the initial desktop window.
///
/// The Flutter [CustomTitleBar] then provides the visible title bar, window
/// dragging and minimize / maximize / close actions.
Future<void> setUpDesktopWindow() async {
  if (!isDesktopPlatform) {
    return;
  }

  await windowManager.ensureInitialized();

  const WindowOptions options = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(960, 640),
    center: true,
    title: 'Muse Player',
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

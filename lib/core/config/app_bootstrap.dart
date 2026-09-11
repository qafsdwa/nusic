import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../window/window_setup.dart';
import 'app_config.dart';
import 'app_config_loader.dart';

/// Initializes Flutter bindings, loads the startup configuration and prepares
/// the custom desktop window chrome.
///
/// `main()` awaits this function before creating the root `ProviderScope`, so
/// the whole widget tree can read a fully resolved [AppConfig] synchronously.
Future<AppConfig> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppConfig config = await const AppConfigLoader().load();

  await setUpDesktopWindow();
  await _setUpMobileSystemUi();

  return config;
}

Future<void> _setUpMobileSystemUi() async {
  if (kIsWeb) {
    return;
  }

  final bool isMobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (!isMobile) {
    return;
  }

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

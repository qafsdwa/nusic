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

  return config;
}

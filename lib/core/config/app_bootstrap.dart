import 'package:flutter/widgets.dart';

import 'app_config.dart';
import 'app_config_loader.dart';

/// Initializes Flutter bindings and loads the startup configuration.
///
/// `main()` awaits this function before creating the root `ProviderScope`, so
/// the whole widget tree can read a fully resolved [AppConfig] synchronously.
Future<AppConfig> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  return const AppConfigLoader().load();
}

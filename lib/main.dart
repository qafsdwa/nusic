import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_bootstrap.dart';
import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';

Future<void> main() async {
  final AppConfig config = await initializeApp();

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const MuseApp(),
    ),
  );
}

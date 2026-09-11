import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muse_player/core/config/app_config.dart';
import 'package:muse_player/core/config/app_config_provider.dart';
import 'package:muse_player/providers/theme_mode_provider.dart';

void main() {
  test('theme mode starts from config and cycles system/light/dark', () {
    final config = AppConfig.fromJson(<String, dynamic>{
      'theme': <String, dynamic>{'mode': 'light'},
    });
    final container = ProviderContainer(
      overrides: [appConfigProvider.overrideWithValue(config)],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.light);

    container.read(themeModeProvider.notifier).cycle();
    expect(container.read(themeModeProvider), ThemeMode.dark);

    container.read(themeModeProvider.notifier).cycle();
    expect(container.read(themeModeProvider), ThemeMode.system);

    container.read(themeModeProvider.notifier).cycle();
    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}

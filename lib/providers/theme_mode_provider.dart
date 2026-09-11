import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config_provider.dart';

/// Runtime theme mode state.
///
/// The initial value is read from `AppConfig.theme.mode`, so the JSON file
/// controls the startup theme. The Settings page can then toggle the mode for
/// the current session without writing back to the asset.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final String configuredMode = ref.read(appConfigProvider).theme.mode;
    return _parse(configuredMode);
  }

  /// Cycles `system -> light -> dark -> system`.
  void cycle() {
    state = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }

  void setMode(ThemeMode mode) {
    state = mode;
  }

  static ThemeMode _parse(String value) {
    return switch (value.toLowerCase()) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

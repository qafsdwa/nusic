import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_config.dart';

/// Loads [AppConfig] from a Flutter asset.
///
/// The loader never throws: if the asset is missing or malformed, it logs a
/// debug message and returns [AppConfig.fallback] so the app can still start.
class AppConfigLoader {
  const AppConfigLoader({this.assetPath = 'assets/config/app_config.json'});

  final String assetPath;

  Future<AppConfig> load() async {
    try {
      final String rawJson = await rootBundle.loadString(assetPath);
      final Object? decoded = json.decode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return AppConfig.fromJson(decoded);
      }
      debugPrint(
        'AppConfigLoader: expected a JSON object at "$assetPath", '
        'using fallback config.',
      );
    } catch (error, stackTrace) {
      debugPrint('AppConfigLoader: failed to load "$assetPath": $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    return AppConfig.fallback;
  }
}

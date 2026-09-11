import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// Provides the immutable app configuration.
///
/// `main.dart` overrides this provider with the value loaded from
/// `assets/config/app_config.json`. Widgets and providers that need config
/// values should read this provider instead of importing JSON directly.
///
/// The default value is [AppConfig.fallback] so widget tests and previews can
/// run without a bootstrap step.
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fallback);

import 'package:flutter/material.dart';

import '../pages/now_playing_page.dart';
import '../pages/search_page.dart';

/// Central route table for Phase 1.
///
/// The main shell is not a named route; it is passed to MaterialApp as `home`.
/// Named routes are kept for deep links and for future Rust-driven navigation.
abstract final class AppRoutes {
  static const String home = '/';
  static const String search = '/search';
  static const String library = '/library';
  static const String nowPlaying = '/now-playing';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.search:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const _SearchRoutePage(),
        );
      case AppRoutes.library:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const Scaffold(
            body: Center(child: Text('Library placeholder route')),
          ),
        );
      case AppRoutes.nowPlaying:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const NowPlayingPage(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}

class _SearchRoutePage extends StatelessWidget {
  const _SearchRoutePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('搜索')),
      body: const SafeArea(child: SearchPage()),
    );
  }
}

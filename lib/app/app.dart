import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/config/app_config_provider.dart';
import '../core/constants/app_sizes.dart';
import '../pages/home/home_page.dart';
import '../pages/library/library_page.dart';
import '../pages/playlist/playlist_page.dart';
import '../pages/search/search_page.dart';
import '../providers/navigation_provider.dart';
import '../widgets/common/placeholder_page.dart';
import '../widgets/navigation/desktop_navigation.dart';
import '../widgets/player/floating_player_bar.dart';
import 'breakpoints.dart';
import 'router.dart';
import 'theme.dart';

/// Root [MaterialApp] of Muse Player.
class MuseApp extends ConsumerWidget {
  const MuseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppConfig config = ref.watch(appConfigProvider);

    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const MainShell(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

/// Responsive application shell.
///
/// The floating player bar is always rendered inside a [Stack] as a true
/// floating surface — never as a footer or a `bottomNavigationBar`.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int selectedIndex = ref.watch(navigationProvider);

    final List<Widget> pages = <Widget>[
      HomePage(
        onSearchTap: () {
          ref.read(navigationProvider.notifier).select(1);
        },
      ),
      const SearchPage(),
      const LibraryPage(),
      const PlaceholderPage(
        title: '收藏',
        icon: Icons.favorite_outline,
        description: '收藏的歌曲和专辑将在这里显示，等待 Rust 后端接入。',
      ),
      const PlaylistPage(),
      const PlaceholderPage(
        title: '设置',
        icon: Icons.settings_outlined,
        description: '音频输出、外观与同步设置将在后续版本中开放。',
      ),
    ];

    final Widget content = IndexedStack(index: selectedIndex, children: pages);

    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final AppBreakpoint breakpoint = AppBreakpoints.fromWidth(
            constraints.maxWidth,
          );

          return switch (breakpoint) {
            AppBreakpoint.desktop => Stack(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    DesktopNavigationPanel(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (int index) {
                        ref.read(navigationProvider.notifier).select(index);
                      },
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Expanded(child: content),
                  ],
                ),
                const Positioned(
                  left: AppSizes.floatingPlayerBarHorizontalMargin,
                  right: AppSizes.floatingPlayerBarHorizontalMargin,
                  bottom: AppSizes.floatingPlayerBarBottom,
                  child: FloatingPlayerBar(),
                ),
              ],
            ),
            AppBreakpoint.tablet => Stack(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    MuseNavigationRail(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (int index) {
                        ref.read(navigationProvider.notifier).select(index);
                      },
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Expanded(child: content),
                  ],
                ),
                const Positioned(
                  left: AppSizes.floatingPlayerBarHorizontalMargin,
                  right: AppSizes.floatingPlayerBarHorizontalMargin,
                  bottom: AppSizes.floatingPlayerBarBottom,
                  child: FloatingPlayerBar(),
                ),
              ],
            ),
            AppBreakpoint.mobile => Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Expanded(child: content),
                    MuseBottomNavigationBar(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (int index) {
                        ref.read(navigationProvider.notifier).select(index);
                      },
                    ),
                  ],
                ),
                const Positioned(
                  left: AppSizes.floatingPlayerBarHorizontalMargin,
                  right: AppSizes.floatingPlayerBarHorizontalMargin,
                  bottom: AppSizes.floatingPlayerBarMobileBottom,
                  child: FloatingPlayerBar(),
                ),
              ],
            ),
          };
        },
      ),
    );
  }
}

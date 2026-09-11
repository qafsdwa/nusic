import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/config/app_config_provider.dart';
import '../core/window/window_setup.dart';
import '../core/constants/app_sizes.dart';
import '../pages/home/home_page.dart';
import '../pages/library/library_page.dart';
import '../pages/playlist/playlist_page.dart';
import '../pages/search/search_page.dart';
import '../pages/settings/settings_page.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../widgets/common/placeholder_page.dart';
import '../widgets/navigation/desktop_navigation.dart';
import '../widgets/window/custom_title_bar.dart';
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
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(config.theme.light),
      darkTheme: AppTheme.dark(config.theme.dark),
      themeMode: themeMode,
      home: const MainShell(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (BuildContext context, Widget? child) {
        final ThemeData theme = Theme.of(context);
        final bool isDark = theme.brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: theme.colorScheme.surface,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
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
      const SettingsPage(),
    ];

    final Widget content = IndexedStack(index: selectedIndex, children: pages);

    return Scaffold(
      body: Column(
        children: <Widget>[
          if (isDesktopPlatform) const CustomTitleBar(),
          Expanded(
            child: SafeArea(
              top: !isDesktopPlatform,
              bottom: false,
              child: LayoutBuilder(
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
                                ref
                                    .read(navigationProvider.notifier)
                                    .select(index);
                              },
                            ),
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
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
                                ref
                                    .read(navigationProvider.notifier)
                                    .select(index);
                              },
                            ),
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
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
                                ref
                                    .read(navigationProvider.notifier)
                                    .select(index);
                              },
                            ),
                          ],
                        ),
                        Positioned(
                          left: AppSizes.floatingPlayerBarHorizontalMargin,
                          right: AppSizes.floatingPlayerBarHorizontalMargin,
                          bottom:
                              AppSizes.navigationBarHeight +
                              MediaQuery.paddingOf(context).bottom +
                              AppSizes.spacingSm,
                          child: const FloatingPlayerBar(),
                        ),
                      ],
                    ),
                  };
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

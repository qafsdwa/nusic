import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/config/app_config_provider.dart';
import '../core/constants/app_section.dart';
import '../core/constants/app_sizes.dart';
import '../core/window/window_setup.dart';
import '../pages/home/home_page.dart';
import '../pages/library/library_page.dart';
import '../pages/playlist/playlist_page.dart';
import '../pages/settings/settings_page.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../widgets/common/ambient_background.dart';
import '../widgets/common/placeholder_page.dart';
import '../widgets/common/responsive_layout.dart';
import '../widgets/navigation/desktop_navigation.dart';
import '../widgets/player/floating_player_bar.dart';
import '../widgets/window/custom_title_bar.dart';
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
///
/// Shell selection goes through [ResponsiveLayout] so the window size classes
/// live in exactly one place (`AppBreakpoints`).
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Decorative wash, behind everything including the title bar. The
          // shell surface below is inset from the window edge, which is what
          // lets the wash read as a background rather than as a border.
          const Positioned.fill(child: AmbientBackground()),
          Column(
            children: <Widget>[
              if (isDesktopPlatform) const CustomTitleBar(),
              Expanded(
                child: Padding(
                  // A uniform inset on all four sides: the shell reads as one
                  // pane floating on the wash regardless of which shell renders.
                  padding: const EdgeInsets.all(AppSizes.shellMargin),
                  child: const _ShellSurface(child: _ShellBody()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inset, rounded app surface that hosts the navigation and page content.
class _ShellSurface extends StatelessWidget {
  const _ShellSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSizes.shellRadius),
      // Clipped so the bottom navigation bar and any surface-coloured child
      // cannot square off the rounded corners they sit inside.
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// The responsive shell inside [_ShellSurface].
///
/// Split out so the surface wrapper can stay `const` and the shell can keep
/// depending on Riverpod state.
class _ShellBody extends ConsumerWidget {
  const _ShellBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int selectedIndex = ref.watch(navigationProvider);
    final NavigationNotifier navigation = ref.read(navigationProvider.notifier);

    final List<Widget> pages = <Widget>[
      for (final AppSection section in AppSection.values)
        switch (section) {
          AppSection.home => const HomePage(),
          AppSection.library => const LibraryPage(),
          AppSection.favorites => const PlaceholderPage(
            title: '收藏',
            icon: Icons.favorite_outline,
            description: '收藏的歌曲和专辑将在这里显示，等待 Rust 后端接入。',
          ),
          AppSection.playlists => const PlaylistPage(),
          AppSection.settings => const SettingsPage(),
        },
    ];

    final Widget content = IndexedStack(index: selectedIndex, children: pages);

    return SafeArea(
      top: !isDesktopPlatform,
      bottom: false,
      child: ResponsiveLayout(
        // `large` + `extra-large`: permanent navigation panel.
        desktop: _SideNavigationShell(
          navigation: DesktopNavigationPanel(
            selectedIndex: selectedIndex,
            onDestinationSelected: navigation.select,
          ),
          content: content,
        ),
        // `medium` + `expanded`: navigation rail.
        tablet: _SideNavigationShell(
          navigation: MuseNavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: navigation.select,
          ),
          content: content,
        ),
        // `compact`: bottom navigation.
        mobile: _BottomNavigationShell(
          selectedIndex: selectedIndex,
          onDestinationSelected: navigation.select,
          content: content,
        ),
      ),
    );
  }
}

/// Side navigation (panel or rail) with the floating player bar over the
/// content. Shared by the desktop and tablet shells, which differ only in which
/// navigation widget they render.
///
/// No divider between the navigation and the content: both are transparent over
/// the same shell surface, so the pane reads as one piece with the navigation
/// column mapped out by its selected pill rather than by a rule.
class _SideNavigationShell extends StatelessWidget {
  const _SideNavigationShell({required this.navigation, required this.content});

  final Widget navigation;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            navigation,
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
    );
  }
}

/// Bottom navigation with the floating player bar lifted clear of the bar and
/// the system inset.
class _BottomNavigationShell extends StatelessWidget {
  const _BottomNavigationShell({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.content,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Expanded(child: content),
            MuseBottomNavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
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
    );
  }
}

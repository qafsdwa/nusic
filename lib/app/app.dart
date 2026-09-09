import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_section.dart';
import '../pages/home_page.dart';
import '../pages/library_page.dart';
import '../pages/placeholder_page.dart';
import '../pages/search_page.dart';
import '../widgets/mini_player.dart';
import '../widgets/navigation.dart';
import 'router.dart';
import 'theme.dart';

/// Root [MaterialApp] of Muse Player.
///
/// Wires the light/dark themes, system theme mode, the [MainShell] as home, and
/// the named route table from [AppRoutes].
class MuseApp extends StatelessWidget {
  const MuseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muse Player',
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
/// - Desktop/tablet width >= 900: left NavigationRail + main content.
/// - Mobile width < 900: main content + bottom Material NavigationBar.
/// - A mini player is fixed at the very bottom on all form factors.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = AppSection.home.index;

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _openSearch() {
    _onDestinationSelected(AppSection.search.index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomePage(onSearchTap: _openSearch),
      const SearchPage(),
      const LibraryPage(),
      const PlaceholderPage(
        title: '收藏',
        icon: Icons.favorite_outline,
        description: '收藏的歌曲和专辑将在这里显示，等待 Rust 后端接入。',
      ),
      const PlaceholderPage(
        title: '播放列表',
        icon: Icons.queue_music_outlined,
        description: '播放列表管理将在后续版本中开放。',
      ),
      const PlaceholderPage(
        title: '设置',
        icon: Icons.settings_outlined,
        description: '音频输出、外观与同步设置将在后续版本中开放。',
      ),
    ];

    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool useDesktopRail = constraints.maxWidth >= 900;
          final Widget content = IndexedStack(
            index: _selectedIndex,
            children: pages,
          );

          if (useDesktopRail) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppNavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(child: content),
              ],
            );
          }

          return Column(
            children: <Widget>[
              Expanded(child: content),
              AppBottomNavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}

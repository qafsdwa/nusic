import 'package:flutter/material.dart';

import '../core/constants/app_section.dart';
import '../core/constants/app_sizes.dart';

IconData _iconFor(AppSection section, {required bool selected}) {
  switch (section) {
    case AppSection.home:
      return selected ? Icons.home : Icons.home_outlined;
    case AppSection.search:
      return selected ? Icons.search : Icons.search;
    case AppSection.library:
      return selected ? Icons.library_music : Icons.library_music_outlined;
    case AppSection.favorites:
      return selected ? Icons.favorite : Icons.favorite_outline;
    case AppSection.playlists:
      return selected ? Icons.queue_music : Icons.queue_music_outlined;
    case AppSection.settings:
      return selected ? Icons.settings : Icons.settings_outlined;
  }
}

/// Side navigation used on desktop/tablet (width ≥ 900).
///
/// Renders the Muse Player brand, a full [NavigationRail] driven by
/// [AppSection], and a phase footer.
class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = AppSection.values;

    return SizedBox(
      width: AppSizes.navigationRailWidth,
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.spacingMd,
                  AppSizes.spacingLg,
                  AppSizes.spacingMd,
                  AppSizes.spacingLg,
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.graphic_eq, color: Color(0xFF1A73E8)),
                    const SizedBox(width: 8),
                    Text(
                      'Muse Player',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  extended: true,
                  labelType: NavigationRailLabelType.none,
                  minExtendedWidth: AppSizes.navigationRailWidth,
                  groupAlignment: -0.9,
                  leading: const SizedBox(height: 8),
                  destinations: <NavigationRailDestination>[
                    for (var index = 0; index < sections.length; index++)
                      NavigationRailDestination(
                        icon: Icon(_iconFor(sections[index], selected: false)),
                        selectedIcon: Icon(
                          _iconFor(sections[index], selected: true),
                        ),
                        label: Text(sections[index].label),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(AppSizes.spacingMd),
                child: Text(
                  'Phase 1 · Mock UI',
                  style: TextStyle(fontSize: 11, letterSpacing: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom navigation used on mobile (width < 900).
///
/// Mirrors [AppNavigationRail] destinations using a Material [NavigationBar].
class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final sections = AppSection.values;

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: <NavigationDestination>[
        for (final section in sections)
          NavigationDestination(
            icon: Icon(_iconFor(section, selected: false)),
            selectedIcon: Icon(_iconFor(section, selected: true)),
            label: section.label,
          ),
      ],
    );
  }
}

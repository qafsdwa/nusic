import 'package:flutter/material.dart';

import '../../core/constants/app_section.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/motion.dart';

IconData _iconFor(AppSection section, {required bool selected}) {
  return switch (section) {
    AppSection.home => selected ? Icons.home : Icons.home_outlined,
    AppSection.search => selected ? Icons.search : Icons.search,
    AppSection.library =>
      selected ? Icons.library_music : Icons.library_music_outlined,
    AppSection.favorites => selected ? Icons.favorite : Icons.favorite_outline,
    AppSection.playlists =>
      selected ? Icons.queue_music : Icons.queue_music_outlined,
    AppSection.settings => selected ? Icons.settings : Icons.settings_outlined,
  };
}

/// Custom desktop navigation panel (width ≥ 1101).
///
/// Lightweight, flat, and Material — selected items use the primary container
/// with primary text and a 16px radius.
class DesktopNavigationPanel extends StatelessWidget {
  const DesktopNavigationPanel({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<AppSection> sections = AppSection.values;

    return SizedBox(
      width: AppSizes.navigationPanelWidth,
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
                    Icon(Icons.graphic_eq, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Muse Player',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.spacingSm),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingSm,
                  ),
                  itemCount: sections.length,
                  separatorBuilder: (BuildContext context, int index) {
                    return const SizedBox(height: 4);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final AppSection section = sections[index];
                    return _DesktopNavigationItem(
                      section: section,
                      selected: index == selectedIndex,
                      onTap: () => onDestinationSelected(index),
                    );
                  },
                ),
              ),
              // The floating player bar spans the full window width (it is
              // positioned `left: 24, right: 24` over the whole shell), so the
              // panel's footer needs the same bottom clearance the scrollable
              // pages reserve. Without it the bar sits on top of this label.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.spacingMd,
                  AppSizes.spacingMd,
                  AppSizes.spacingMd,
                  AppSizes.scrollBottomPadding,
                ),
                child: Text(
                  'Phase 1 · Mock UI',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopNavigationItem extends StatelessWidget {
  const _DesktopNavigationItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final AppSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foregroundColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.shapeLg),
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.standard),
          curve: Curves.easeOut,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.shapeLg),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                _iconFor(section, selected: selected),
                size: 22,
                color: foregroundColor,
              ),
              const SizedBox(width: AppSizes.spacingSm),
              Text(
                section.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: foregroundColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tablet Material [NavigationRail] (width 700 – 1100).
class MuseNavigationRail extends StatelessWidget {
  const MuseNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final List<AppSection> sections = AppSection.values;

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        right: false,
        child: NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          labelType: NavigationRailLabelType.selected,
          backgroundColor: Colors.transparent,
          leading: Padding(
            padding: const EdgeInsets.only(top: AppSizes.spacingLg),
            child: Icon(
              Icons.graphic_eq,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          destinations: <NavigationRailDestination>[
            for (final AppSection section in sections)
              NavigationRailDestination(
                icon: Icon(_iconFor(section, selected: false)),
                selectedIcon: Icon(_iconFor(section, selected: true)),
                label: Text(section.label),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mobile Material [NavigationBar] (width < 700).
class MuseBottomNavigationBar extends StatelessWidget {
  const MuseBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final List<AppSection> sections = AppSection.values;

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: <NavigationDestination>[
        for (final AppSection section in sections)
          NavigationDestination(
            icon: Icon(_iconFor(section, selected: false)),
            selectedIcon: Icon(_iconFor(section, selected: true)),
            label: section.label,
          ),
      ],
    );
  }
}

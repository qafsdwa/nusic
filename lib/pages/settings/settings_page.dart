import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../providers/theme_mode_provider.dart';
import '../../widgets/common/list_card.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/section_header.dart';

/// Settings page.
///
/// Phase 1 exposes a runtime theme-mode switch. The initial mode comes from
/// `app_config.json`; the button cycles `system -> light -> dark -> system`.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ThemeMode mode = ref.watch(themeModeProvider);

    return PageScaffold(
      maxWidth: AppSizes.pageMaxWidthText,
      children: <Widget>[
        const SectionHeader(title: '设置', size: SectionHeaderSize.page),
        const SizedBox(height: AppSizes.spacingLg),
        ListCard(
          children: <Widget>[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingLg,
                vertical: AppSizes.spacingSm,
              ),
              leading: Icon(
                _iconForMode(mode),
                color: theme.colorScheme.primary,
              ),
              title: const Text('主题'),
              subtitle: Text(_descriptionForMode(mode)),
              trailing: FilledButton.tonalIcon(
                onPressed: () {
                  ref.read(themeModeProvider.notifier).cycle();
                },
                icon: const Icon(Icons.swap_horiz),
                label: Text(_buttonLabelForMode(mode)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingMd),
        const ListCard(
          children: <Widget>[
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSizes.spacingLg,
                vertical: AppSizes.spacingSm,
              ),
              leading: Icon(Icons.info_outline),
              title: Text('关于'),
              subtitle: Text('Muse Player · Phase 1 Mock UI'),
            ),
          ],
        ),
      ],
    );
  }

  static IconData _iconForMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };
  }

  static String _descriptionForMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => '跟随系统外观',
      ThemeMode.light => '始终使用浅色主题',
      ThemeMode.dark => '始终使用深色主题',
    };
  }

  static String _buttonLabelForMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => '跟随系统',
      ThemeMode.light => '浅色',
      ThemeMode.dark => '深色',
    };
  }
}

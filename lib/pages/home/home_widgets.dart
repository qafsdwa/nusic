import 'package:flutter/material.dart';

import '../../app/breakpoints.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/common/search_launcher.dart';

/// Header row for Home, used on the shells that have no title bar.
///
/// On desktop the search field lives in the custom title bar instead, so this
/// header is only built for the mobile and tablet shells. It carries the greeting
/// plus the same [SearchLauncherField] the title bar uses.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String greeting = _greetingForHour(TimeOfDay.now().hour);
    final Widget title = Text(
      greeting,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < AppBreakpoints.tabletMin) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              title,
              const SizedBox(height: AppSizes.spacingSm),
              SearchLauncherField(onTap: onSearchTap),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: title),
            SizedBox(
              width: AppSizes.searchFieldWidth,
              child: SearchLauncherField(onTap: onSearchTap),
            ),
          ],
        );
      },
    );
  }

  static String _greetingForHour(int hour) {
    if (hour >= 5 && hour < 12) {
      return '早上好，音乐旅人';
    }
    if (hour >= 12 && hour < 18) {
      return '下午好，音乐旅人';
    }
    return '晚上好，音乐旅人';
  }
}

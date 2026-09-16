import 'package:flutter/material.dart';

import '../../app/breakpoints.dart';
import '../../core/constants/app_sizes.dart';

/// Header row for Home: greeting + inline search field on desktop/tablet and
/// a stacked search field on mobile.
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
              HomeSearchField(onTap: onSearchTap),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: title),
            SizedBox(
              width: AppSizes.searchFieldWidth,
              child: HomeSearchField(onTap: onSearchTap),
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

/// Read-only home search field that jumps to the Search page.
class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.searchFieldHeight,
      child: TextField(
        onTap: onTap,
        readOnly: true,
        // No explicit fill: this field and the Search page's field must read as
        // the same control, so both take `inputDecorationTheme`.
        decoration: const InputDecoration(
          hintText: '搜索歌曲、专辑、歌手或歌单',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

/// Visual weight of a [SectionHeader].
enum SectionHeaderSize {
  /// Top-of-page title, e.g. "音乐库".
  page,

  /// Title above a group of content, e.g. "最近播放".
  section,

  /// Title nested inside another section, e.g. "歌曲" on the search page.
  subsection,
}

/// A page or section title with an optional trailing "查看全部" action.
///
/// All headings in the app go through this widget so a change to heading
/// typography is a one-line edit instead of a hunt across every page.
///
/// Hierarchy is carried by **size + weight + colour together**, not by size
/// alone. Using one weight everywhere would spend the type scale's most
/// legible axis on nothing.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAllTap,
    this.size = SectionHeaderSize.section,
  });

  final String title;

  /// Opens the full list behind this section. `null` renders no trailing
  /// action rather than a link that goes nowhere.
  final VoidCallback? onSeeAllTap;

  final SectionHeaderSize size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final (
      TextStyle? baseStyle,
      FontWeight weight,
      Color color,
    ) = switch (size) {
      // The page's own name: largest, heaviest, full-emphasis text colour.
      SectionHeaderSize.page => (
        textTheme.headlineMedium,
        FontWeight.w700,
        colors.onSurface,
      ),
      // A group of content: mid size, medium weight, full emphasis.
      SectionHeaderSize.section => (
        textTheme.titleLarge,
        FontWeight.w500,
        colors.onSurface,
      ),
      // Nested inside another section: smallest, medium weight, de-emphasised
      // colour so it does not compete with its parent.
      SectionHeaderSize.subsection => (
        textTheme.titleMedium,
        FontWeight.w500,
        colors.onSurfaceVariant,
      ),
    };

    final Widget label = Text(
      title,
      style: baseStyle?.copyWith(fontWeight: weight, color: color),
    );

    if (onSeeAllTap == null) {
      return label;
    }

    return Row(
      children: <Widget>[
        Expanded(child: label),
        TextButton(
          onPressed: onSeeAllTap,
          style: TextButton.styleFrom(
            foregroundColor: colors.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingSm),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('查看全部'),
              Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

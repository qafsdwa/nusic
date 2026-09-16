import 'package:flutter/material.dart';

/// Visual weight of a [SectionHeader].
enum SectionHeaderSize {
  /// Top-of-page title, e.g. "音乐库".
  page,

  /// Title above a group of content, e.g. "最近播放".
  section,

  /// Title nested inside another section, e.g. "歌曲" on the search page.
  subsection,
}

/// A page or section title with an optional trailing "更多" action.
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
    this.onMoreTap,
    this.size = SectionHeaderSize.section,
  });

  final String title;
  final VoidCallback? onMoreTap;
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

    if (onMoreTap == null) {
      return label;
    }

    return Row(
      children: <Widget>[
        Expanded(child: label),
        TextButton(onPressed: onMoreTap, child: const Text('更多')),
      ],
    );
  }
}

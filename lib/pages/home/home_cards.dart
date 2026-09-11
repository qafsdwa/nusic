import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../widgets/common/cover_artwork.dart';

/// Large horizontal recommendation card with a soft blue-purple-pink wash.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key, required this.onPlayRecommended});

  final VoidCallback onPlayRecommended;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final List<Color> colors = isDark
        ? const <Color>[Color(0xFF1F2A44), Color(0xFF2E2344), Color(0xFF3E2135)]
        : const <Color>[
            Color(0xFFDCE7FB),
            Color(0xFFE8E0FB),
            Color(0xFFFBE3EE),
          ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 480;
        return Container(
          height: compact ? 200 : 240,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacingLg),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '今日推荐',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingSm),
                      Text(
                        '在音乐中遇见更好的自己',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingLg),
                      FilledButton.icon(
                        onPressed: onPlayRecommended,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('播放推荐'),
                      ),
                    ],
                  ),
                ),
                if (!compact) ...<Widget>[
                  const SizedBox(width: AppSizes.spacingLg),
                  const CoverArtwork(
                    title: 'Midnight Drive',
                    coverKey: 'mock://hero-midnight-drive',
                    size: 156,
                    borderRadius: 22,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Small section title with an optional trailing action.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({super.key, required this.title, this.onMoreTap});

  final String title;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onMoreTap != null)
          TextButton(onPressed: onMoreTap, child: const Text('更多')),
      ],
    );
  }
}

/// Horizontal "recently played" song card with soft hover scale.
class RecentSongCard extends StatefulWidget {
  const RecentSongCard({super.key, required this.song, required this.onTap});

  final Song song;
  final VoidCallback onTap;

  @override
  State<RecentSongCard> createState() => _RecentSongCardState();
}

class _RecentSongCardState extends State<RecentSongCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: 160,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _hovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOut,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CoverArtwork(
                  title: widget.song.title,
                  coverKey: widget.song.cover,
                  size: 160,
                  borderRadius: 16,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDuration(widget.song.duration),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal playlist card used by the "recommended playlist" rail.
class PlaylistCard extends StatelessWidget {
  const PlaylistCard({super.key, required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CoverArtwork(
              title: playlist.name,
              coverKey: playlist.cover,
              size: 160,
              borderRadius: 16,
            ),
            const SizedBox(height: 8),
            Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${playlist.songCount} 首歌曲',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/breakpoints.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/motion.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../widgets/common/cover_artwork.dart';
import '../../widgets/common/generated_artwork.dart';
import '../../widgets/song/song_tile.dart' show SongAction;

/// Large home banner: generated artwork with the recommendation copy overlaid.
///
/// The text sits on a fixed dark scrim rather than directly on the artwork.
/// Scenes are generated, so their colours are not controllable — without a
/// scrim, some scene/theme combinations would drop white body text below the
/// 4.5:1 contrast floor. The scrim makes legibility independent of which scene
/// the seed happens to produce.
class HomeHeroCard extends ConsumerWidget {
  const HomeHeroCard({super.key, required this.onPlayRecommended});

  final VoidCallback onPlayRecommended;

  /// Scrim over the artwork, left to right. Always dark in both themes: the text
  /// on top is always white, so this layer must not follow the theme.
  ///
  /// Clears to fully transparent by ~72% of the width, so only the text side is
  /// darkened and the right of the banner still reads as artwork rather than as
  /// a darkened panel. 60% black under white text holds >7:1 contrast against
  /// any scene the generator can produce.
  static const LinearGradient _scrim = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[Color(0x99000000), Color(0x66000000), Color(0x00000000)],
    stops: <double>[0.0, 0.42, 0.72],
  );

  /// Label colour for the white call-to-action button.
  ///
  /// Fixed rather than a theme role on purpose. The button is always white and
  /// sits on the dark scrim, so both ends are theme-independent —
  /// `colorScheme.primary` would fall to roughly 2.3:1 in dark mode, where
  /// primary is a light blue.
  static const Color _ctaLabel = Color(0xFF16233A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final List<Color> wash = isDark
        ? ref.watch(appConfigProvider).theme.heroGradient.dark
        : ref.watch(appConfigProvider).theme.heroGradient.light;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact =
            constraints.maxWidth < AppBreakpoints.heroCompactMax;

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.shapeXl),
          child: SizedBox(
            height: compact ? 200 : 240,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Configured palette wash: the base colour, and what shows if
                // artwork generation is ever turned off.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: wash,
                    ),
                  ),
                ),
                // Slightly under full opacity so the wash tints the scene
                // instead of being completely covered by it.
                const Opacity(
                  opacity: 0.92,
                  child: GeneratedArtwork(
                    seedKey: 'hero|midnight-drive',
                    scene: GeneratedScene.sunsetSea,
                  ),
                ),
                const DecoratedBox(decoration: BoxDecoration(gradient: _scrim)),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '今日推荐',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingSm),
                      Text(
                        '在音乐中遇见更好的自己',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (compact
                                    ? theme.textTheme.titleLarge
                                    : theme.textTheme.headlineSmall)
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: AppSizes.spacingXs),
                      Text(
                        '让旋律陪你度过每一个瞬间',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingLg),
                      FilledButton.icon(
                        onPressed: onPlayRecommended,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _ctaLabel,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spacingLg,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('播放推荐'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Horizontal "recently played" song card with soft hover scale.
///
/// Carries a per-song action menu, so the rail is usable without opening the
/// song first.
class RecentSongCard extends StatefulWidget {
  const RecentSongCard({
    super.key,
    required this.song,
    required this.onTap,
    this.onAction,
  });

  final Song song;
  final VoidCallback onTap;

  /// `null` hides the action menu rather than showing one that does nothing.
  final ValueChanged<SongAction>? onAction;

  /// Cover edge length, and the card's fixed width.
  static const double size = 160;

  @override
  State<RecentSongCard> createState() => _RecentSongCardState();
}

class _RecentSongCardState extends State<RecentSongCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ValueChanged<SongAction>? onAction = widget.onAction;

    return SizedBox(
      width: RecentSongCard.size,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _hovered ? 1.02 : 1.0,
          duration: AppMotion.of(context, AppMotion.fast),
          curve: Curves.easeOut,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSizes.shapeLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ArtworkWithHoverPlay(
                  hovered: _hovered,
                  child: CoverArtwork(
                    title: widget.song.title,
                    coverKey: widget.song.cover,
                    size: RecentSongCard.size,
                    borderRadius: 16,
                  ),
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        formatDuration(widget.song.duration),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (onAction != null)
                      SongActionMenu(song: widget.song, onAction: onAction),
                  ],
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
class PlaylistCard extends StatefulWidget {
  const PlaylistCard({super.key, required this.playlist, this.onTap});

  final Playlist playlist;

  /// Opens the playlist. `null` renders the card as non-interactive rather than
  /// as a button that silently does nothing.
  final VoidCallback? onTap;

  static const double size = 160;

  @override
  State<PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<PlaylistCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: PlaylistCard.size,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppSizes.shapeLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ArtworkWithHoverPlay(
                hovered: _hovered && widget.onTap != null,
                child: CoverArtwork(
                  title: widget.playlist.name,
                  coverKey: widget.playlist.cover,
                  size: PlaylistCard.size,
                  borderRadius: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.playlist.songCount} 首歌曲',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps artwork with a play affordance that fades in on hover.
///
/// The card itself is already tappable; this exists so the primary action is
/// visible before the user commits to a click, and so the rail reads as playable
/// rather than as a row of static images.
class _ArtworkWithHoverPlay extends StatelessWidget {
  const _ArtworkWithHoverPlay({required this.hovered, required this.child});

  final bool hovered;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Stack(
      children: <Widget>[
        child,
        Positioned(
          right: AppSizes.spacingSm,
          bottom: AppSizes.spacingSm,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: hovered ? 1 : 0,
              duration: AppMotion.of(context, AppMotion.fast),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact per-song action menu sized for the artwork rails.
///
/// Offers a subset of [SongAction]: `收藏` is omitted because favourites do not
/// exist yet (Phase 4 — the section is still a placeholder). A menu entry that
/// silently does nothing is exactly the dead-affordance failure
/// `docs/m3-audit.md` scores as blocking, so the entry is absent rather than
/// inert. Re-add it when there is a favourites store to write to.
class SongActionMenu extends StatelessWidget {
  const SongActionMenu({
    super.key,
    required this.song,
    required this.onAction,
    this.iconSize = 18,
    this.tapTarget = 36,
  });

  final Song song;
  final ValueChanged<SongAction> onAction;
  final double iconSize;

  /// Side of the square tap target.
  ///
  /// Below the 48dp touch minimum on purpose: this sits in a 160dp card inside a
  /// horizontal rail, where a 48dp target would dominate the layout. The icon
  /// stays small and the target is a compromise, not an oversight.
  final double tapTarget;

  @override
  Widget build(BuildContext context) {
    // A tight box rather than `minimumSize`: IconButton's own size also depends
    // on the platform visual density, so only a tight constraint makes the row
    // the same height on desktop and in tests.
    return SizedBox.square(
      dimension: tapTarget,
      child: PopupMenuButton<SongAction>(
        tooltip: '更多',
        icon: Icon(Icons.more_horiz, size: iconSize),
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onSelected: onAction,
        itemBuilder: (BuildContext context) {
          return const <PopupMenuEntry<SongAction>>[
            PopupMenuItem<SongAction>(
              value: SongAction.play,
              child: Text('播放'),
            ),
            PopupMenuItem<SongAction>(
              value: SongAction.playNext,
              child: Text('下一首播放'),
            ),
            PopupMenuItem<SongAction>(
              value: SongAction.addToQueue,
              child: Text('加入播放队列'),
            ),
          ];
        },
      ),
    );
  }
}

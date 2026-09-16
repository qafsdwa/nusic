import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../common/cover_artwork.dart';

enum SongAction { play, playNext, addToQueue, favorite }

/// A standard list row for a song, used by Home, Search, Library and playlists.
class SongTile extends ConsumerWidget {
  const SongTile({
    super.key,
    required this.song,
    this.onTap,
    this.onAction,
    this.coverSize = 48,
    this.showAlbum = false,
  });

  final Song song;
  final VoidCallback? onTap;
  final ValueChanged<SongAction>? onAction;
  final double coverSize;
  final bool showAlbum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    // Only the current song id and the play state affect this row. Watching the
    // whole [PlayerState] would rebuild every tile in the list on each position
    // tick once a real audio engine starts driving progress.
    final (String? currentSongId, bool isPlaying) = ref.watch(
      playerProvider.select(
        (PlayerState state) => (state.currentSong?.id, state.isPlaying),
      ),
    );
    final bool isCurrentSong = currentSongId == song.id;
    final String subtitle = showAlbum
        ? '${song.artist} · ${song.album}'
        : song.artist;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      tileColor: isCurrentSong
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      hoverColor: theme.colorScheme.surfaceContainerHighest,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isCurrentSong) ...<Widget>[
            // A shape, not just a colour. Tinting the row alone would leave
            // colour as the only cue for "this is the current track", which
            // fails WCAG 1.4.1 and is the single most important state in a
            // music player.
            Icon(
              isPlaying ? Icons.graphic_eq_rounded : Icons.pause_rounded,
              size: 18,
              color: theme.colorScheme.primary,
              semanticLabel: isPlaying ? '正在播放' : '已暂停',
            ),
            const SizedBox(width: AppSizes.spacingSm),
          ],
          CoverArtwork(
            title: song.title,
            coverKey: song.cover,
            size: coverSize,
          ),
        ],
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: SizedBox(
        width: 104,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: Text(
                formatDuration(song.duration),
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            _SongMoreButton(song: song, onAction: onAction),
          ],
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.shapeMd),
      ),
      onTap: onTap,
    );
  }
}

class _SongMoreButton extends StatelessWidget {
  const _SongMoreButton({required this.song, this.onAction});

  final Song song;
  final ValueChanged<SongAction>? onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SongAction>(
      tooltip: '更多',
      icon: const Icon(Icons.more_horiz),
      onSelected: onAction,
      itemBuilder: (BuildContext context) {
        return const <PopupMenuEntry<SongAction>>[
          PopupMenuItem<SongAction>(value: SongAction.play, child: Text('播放')),
          PopupMenuItem<SongAction>(
            value: SongAction.playNext,
            child: Text('下一首播放'),
          ),
          PopupMenuItem<SongAction>(
            value: SongAction.addToQueue,
            child: Text('加入播放列表'),
          ),
          PopupMenuItem<SongAction>(
            value: SongAction.favorite,
            child: Text('收藏'),
          ),
        ];
      },
    );
  }
}

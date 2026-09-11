import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final PlayerState playerState = ref.watch(playerProvider);
    final bool isCurrentSong = playerState.currentSong?.id == song.id;
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
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

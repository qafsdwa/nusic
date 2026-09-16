import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../mock/mock_music.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../widgets/common/cover_artwork.dart';
import '../../widgets/common/list_card.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/song/song_tile.dart';

/// Playlist detail page backed by mock data.
class PlaylistPage extends ConsumerWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Playlist playlist = MockMusic.playlists.first;

    return PageScaffold(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const CoverArtwork(
              title: '深夜驾驶',
              coverKey: 'mock://playlist-midnight-drive',
              size: 168,
              borderRadius: 24,
            ),
            const SizedBox(width: AppSizes.spacingLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '歌单',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXs),
                  SectionHeader(
                    title: playlist.name,
                    size: SectionHeaderSize.page,
                  ),
                  const SizedBox(height: AppSizes.spacingXs),
                  Text(
                    '${playlist.songCount} 首歌曲',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(playerProvider.notifier)
                          .play(playlist.songs.first);
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('播放全部'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingXl),
        const SectionHeader(title: '曲目'),
        const SizedBox(height: AppSizes.spacingSm),
        ListCard(
          children: <Widget>[
            for (final Song song in playlist.songs)
              SongTile(
                song: song,
                showAlbum: true,
                onTap: () {
                  ref.read(playerProvider.notifier).play(song);
                },
                onAction: (SongAction action) {
                  if (action == SongAction.play) {
                    ref.read(playerProvider.notifier).play(song);
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}

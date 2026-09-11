import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../mock/mock_music.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../widgets/common/cover_artwork.dart';
import '../../widgets/song/song_tile.dart';

/// Playlist detail page backed by mock data.
class PlaylistPage extends ConsumerWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Playlist playlist = MockMusic.playlists.first;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.pageMaxWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.spacingLg,
            AppSizes.spacingLg,
            AppSizes.spacingLg,
            AppSizes.scrollBottomPadding,
          ),
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
                      Text(
                        playlist.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
            Text(
              '曲目',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.spacingSm),
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
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
            ),
          ],
        ),
      ),
    );
  }
}

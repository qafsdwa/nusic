import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_sizes.dart';
import '../core/constants/mock_data.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../widgets/album_card.dart';
import '../widgets/song_tile.dart';

/// Library page showing a horizontal album strip and the full song library.
///
/// Reads [MockData.albums] and [MockData.songs] directly in Phase 1.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.pageMaxWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.spacingLg,
            AppSizes.spacingLg,
            AppSizes.spacingLg,
            96,
          ),
          children: <Widget>[
            Text(
              '音乐库',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLg),
            Text(
              '专辑',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.spacingSm),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockData.albums.length,
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(width: AppSizes.spacingMd);
                },
                itemBuilder: (BuildContext context, int index) {
                  final album = MockData.albums[index];
                  return AlbumCard(
                    album: album,
                    width: 160,
                    onTap: () {
                      // Future phase: navigate to album detail from Rust API.
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSizes.spacingXl),
            Text(
              '曲库',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.spacingSm),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  for (final Song song in MockData.songs)
                    SongTile(
                      song: song,
                      showAlbum: true,
                      onTap: () {
                        ref.read(playerProvider.notifier).playSong(song);
                      },
                      onAction: (SongAction action) {
                        if (action == SongAction.play) {
                          ref.read(playerProvider.notifier).playSong(song);
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

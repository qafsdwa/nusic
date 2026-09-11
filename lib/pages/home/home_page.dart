import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../core/constants/app_sizes.dart';
import '../../mock/mock_music.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import 'home_cards.dart';
import 'home_widgets.dart';

/// Home page: greeting, hero card, recently played and recommended playlists.
class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.onSearchTap});

  /// Callback used by the responsive shell to switch to the Search page.
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            HomeHeader(
              onSearchTap:
                  onSearchTap ??
                  () {
                    Navigator.of(context).pushNamed(AppRoutes.search);
                  },
            ),
            const SizedBox(height: AppSizes.spacingLg),
            HomeHeroCard(
              onPlayRecommended: () {
                ref.read(playerProvider.notifier).play(MockMusic.songs.first);
              },
            ),
            const SizedBox(height: AppSizes.spacingXl),
            const HomeSectionHeader(title: '最近播放'),
            const SizedBox(height: AppSizes.spacingSm),
            SizedBox(
              height: 232,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockMusic.recentlyPlayed.length,
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(width: AppSizes.spacingMd);
                },
                itemBuilder: (BuildContext context, int index) {
                  final Song song = MockMusic.recentlyPlayed[index];
                  return RecentSongCard(
                    song: song,
                    onTap: () {
                      ref.read(playerProvider.notifier).play(song);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSizes.spacingXl),
            const HomeSectionHeader(title: '推荐歌单'),
            const SizedBox(height: AppSizes.spacingSm),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockMusic.playlists.length,
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(width: AppSizes.spacingMd);
                },
                itemBuilder: (BuildContext context, int index) {
                  final Playlist playlist = MockMusic.playlists[index];
                  return PlaylistCard(playlist: playlist);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

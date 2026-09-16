import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../core/constants/app_section.dart';
import '../../core/constants/app_sizes.dart';
import '../../mock/mock_music.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/section_header.dart';
import 'home_cards.dart';
import 'home_widgets.dart';

/// Home page: greeting, hero card, recently played and recommended playlists.
class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.onSearchTap});

  /// Callback used by the responsive shell to switch to the Search page.
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
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
        const SectionHeader(title: '最近播放'),
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
        const SectionHeader(title: '推荐歌单'),
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
              return PlaylistCard(
                playlist: playlist,
                // The shell already owns a playlist section, so open that
                // rather than pushing a duplicate route.
                onTap: () {
                  ref
                      .read(navigationProvider.notifier)
                      .select(AppSection.playlists.index);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

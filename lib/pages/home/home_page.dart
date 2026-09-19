import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../core/constants/app_section.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/window/window_setup.dart';
import '../../mock/mock_music.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/song/song_tile.dart' show SongAction;
import 'home_cards.dart';
import 'home_widgets.dart';

/// Home page: hero banner, recently played and recommended playlists.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NavigationNotifier navigation = ref.read(navigationProvider.notifier);

    return PageScaffold(
      children: <Widget>[
        // On desktop the search field lives in the title bar, so the greeting
        // header is only built where there is no title bar to hold it.
        if (!isDesktopPlatform) ...<Widget>[
          HomeHeader(
            onSearchTap: () {
              Navigator.of(context).pushNamed(AppRoutes.search);
            },
          ),
          const SizedBox(height: AppSizes.spacingLg),
        ],
        HomeHeroCard(
          onPlayRecommended: () {
            ref.read(playerProvider.notifier).play(MockMusic.songs.first);
          },
        ),
        const SizedBox(height: AppSizes.spacingXl),
        SectionHeader(
          title: '最近播放',
          onSeeAllTap: () => navigation.select(AppSection.library.index),
        ),
        const SizedBox(height: AppSizes.spacingSm),
        _ArtworkRail(
          itemCount: MockMusic.recentlyPlayed.length,
          itemBuilder: (BuildContext context, int index) {
            final Song song = MockMusic.recentlyPlayed[index];
            return RecentSongCard(
              song: song,
              onTap: () {
                ref.read(playerProvider.notifier).play(song);
              },
              onAction: (SongAction action) {
                final PlayerNotifier player = ref.read(playerProvider.notifier);
                switch (action) {
                  case SongAction.play:
                    player.play(song);
                  case SongAction.playNext:
                    player.playNext(song);
                  case SongAction.addToQueue:
                    player.addToQueue(song);
                  case SongAction.favorite:
                    // Not offered by SongActionMenu; see its doc comment.
                    break;
                }
              },
            );
          },
        ),
        const SizedBox(height: AppSizes.spacingXl),
        SectionHeader(
          title: '推荐歌单',
          onSeeAllTap: () => navigation.select(AppSection.playlists.index),
        ),
        const SizedBox(height: AppSizes.spacingSm),
        _ArtworkRail(
          itemCount: MockMusic.playlists.length,
          itemBuilder: (BuildContext context, int index) {
            final Playlist playlist = MockMusic.playlists[index];
            return PlaylistCard(
              playlist: playlist,
              // The shell already owns a playlist section, so open that rather
              // than pushing a duplicate route.
              onTap: () => navigation.select(AppSection.playlists.index),
            );
          },
        ),
      ],
    );
  }
}

/// Horizontally scrolling row of artwork cards.
///
/// Sizes itself from its children instead of taking a fixed height. The cards
/// carry three lines of text plus an action row, so a hardcoded height is a
/// latent overflow the moment the platform text scale changes — which the fixed
/// heights this replaced already were.
class _ArtworkRail extends StatelessWidget {
  const _ArtworkRail({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // The rail is inside a vertical `ListView`, so it is laid out with
      // unbounded height and can adopt the cards' natural height.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int index = 0; index < itemCount; index++)
            Padding(
              padding: EdgeInsets.only(
                right: index == itemCount - 1 ? 0 : AppSizes.spacingMd,
              ),
              child: itemBuilder(context, index),
            ),
        ],
      ),
    );
  }
}

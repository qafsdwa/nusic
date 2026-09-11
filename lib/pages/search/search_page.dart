import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../mock/mock_music.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../widgets/song/song_tile.dart';

/// Search page with local, incremental filtering over [MockMusic.songs].
///
/// Matches the query against title, artist and album. No backend call is made
/// in Phase 1.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Song> get _filteredSongs {
    final String keyword = _query.trim().toLowerCase();
    if (keyword.isEmpty) {
      return MockMusic.songs;
    }
    return MockMusic.songs
        .where((Song song) {
          return song.title.toLowerCase().contains(keyword) ||
              song.artist.toLowerCase().contains(keyword) ||
              song.album.toLowerCase().contains(keyword);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Song> results = _filteredSongs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.spacingLg,
            AppSizes.spacingLg,
            AppSizes.spacingLg,
            AppSizes.spacingSm,
          ),
          child: Text(
            '搜索',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingLg),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.searchFieldWidth,
              ),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                onChanged: (String value) {
                  setState(() => _query = value);
                },
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '搜索歌曲、专辑、歌手或歌单',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                          tooltip: '清空',
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spacingMd),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingLg),
          child: Text(
            '歌曲',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spacingSm),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.pageMaxWidth,
              ),
              child: results.isEmpty
                  ? const _EmptySearchResult()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.spacingMd,
                        0,
                        AppSizes.spacingMd,
                        AppSizes.scrollBottomPadding,
                      ),
                      itemCount: results.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Song song = results[index];
                        return SongTile(
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
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Text(
        '没有找到匹配的歌曲',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

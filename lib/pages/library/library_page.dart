import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../mock/mock_music.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../widgets/album/album_card.dart';
import '../../widgets/song/song_tile.dart';

enum _LibraryTab { songs, albums, artists }

/// Library page with song / album / artist tabs.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  _LibraryTab _tab = _LibraryTab.songs;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
            Text(
              '音乐库',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            SegmentedButton<_LibraryTab>(
              segments: const <ButtonSegment<_LibraryTab>>[
                ButtonSegment<_LibraryTab>(
                  value: _LibraryTab.songs,
                  label: Text('歌曲'),
                  icon: Icon(Icons.music_note_outlined),
                ),
                ButtonSegment<_LibraryTab>(
                  value: _LibraryTab.albums,
                  label: Text('专辑'),
                  icon: Icon(Icons.album_outlined),
                ),
                ButtonSegment<_LibraryTab>(
                  value: _LibraryTab.artists,
                  label: Text('歌手'),
                  icon: Icon(Icons.person_outline),
                ),
              ],
              selected: <_LibraryTab>{_tab},
              onSelectionChanged: (Set<_LibraryTab> selection) {
                setState(() => _tab = selection.first);
              },
            ),
            const SizedBox(height: AppSizes.spacingLg),
            ...switch (_tab) {
              _LibraryTab.songs => _buildSongList(context),
              _LibraryTab.albums => _buildAlbumGrid(context),
              _LibraryTab.artists => _buildArtistList(context),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSongList(BuildContext context) {
    return <Widget>[
      Text(
        '曲库',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppSizes.spacingSm),
      Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: <Widget>[
            for (final Song song in MockMusic.songs)
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
    ];
  }

  List<Widget> _buildAlbumGrid(BuildContext context) {
    return <Widget>[
      Text(
        '专辑',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppSizes.spacingSm),
      Wrap(
        spacing: AppSizes.spacingMd,
        runSpacing: AppSizes.spacingLg,
        children: <Widget>[
          for (final album in MockMusic.albums)
            AlbumCard(album: album, width: 160, onTap: () {}),
        ],
      ),
    ];
  }

  List<Widget> _buildArtistList(BuildContext context) {
    final List<String> artists = <String>{
      for (final Song song in MockMusic.songs) song.artist,
    }.toList(growable: false);

    return <Widget>[
      Text(
        '歌手',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppSizes.spacingSm),
      Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: <Widget>[
            for (final String artist in artists)
              ListTile(
                leading: CircleAvatar(child: Text(artist.characters.first)),
                title: Text(artist),
                onTap: () {},
              ),
          ],
        ),
      ),
    ];
  }
}

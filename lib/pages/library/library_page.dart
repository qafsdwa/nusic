import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../mock/mock_music.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../widgets/album/album_card.dart';
import '../../widgets/common/list_card.dart';
import '../../widgets/common/page_scaffold.dart';
import '../../widgets/common/section_header.dart';
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
    return PageScaffold(
      children: <Widget>[
        const SectionHeader(title: '音乐库', size: SectionHeaderSize.page),
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
          _LibraryTab.songs => _buildSongList(),
          _LibraryTab.albums => _buildAlbumGrid(),
          _LibraryTab.artists => _buildArtistList(),
        },
      ],
    );
  }

  List<Widget> _buildSongList() {
    return <Widget>[
      const SectionHeader(title: '曲库'),
      const SizedBox(height: AppSizes.spacingSm),
      ListCard(
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
    ];
  }

  List<Widget> _buildAlbumGrid() {
    return <Widget>[
      const SectionHeader(title: '专辑'),
      const SizedBox(height: AppSizes.spacingSm),
      Wrap(
        spacing: AppSizes.spacingMd,
        runSpacing: AppSizes.spacingLg,
        children: <Widget>[
          // Album detail is Phase 4, so these stay non-interactive rather than
          // offering a button that does nothing.
          for (final album in MockMusic.albums)
            AlbumCard(album: album, width: 160),
        ],
      ),
    ];
  }

  List<Widget> _buildArtistList() {
    final List<String> artists = <String>{
      for (final Song song in MockMusic.songs) song.artist,
    }.toList(growable: false);

    return <Widget>[
      const SectionHeader(title: '歌手'),
      const SizedBox(height: AppSizes.spacingSm),
      ListCard(
        children: <Widget>[
          // Artist detail is Phase 4; no tap target until it exists.
          for (final String artist in artists)
            ListTile(
              leading: CircleAvatar(child: Text(artist.characters.first)),
              title: Text(artist),
            ),
        ],
      ),
    ];
  }
}

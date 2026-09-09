import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/router.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/mock_data.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key, this.onSearchTap});

  /// Callback used by the responsive shell to switch to the Search page.
  ///
  /// When null, a full named route is pushed as a fallback.
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
            96,
          ),
          children: <Widget>[
            Text(
              '首页',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            _HomeSearchField(
              onTap:
                  onSearchTap ??
                  () {
                    Navigator.of(context).pushNamed(AppRoutes.search);
                  },
            ),
            const SizedBox(height: AppSizes.spacingXl),
            Text(
              '最近播放',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSizes.spacingSm),
            _RecentPlayCard(
              onSongTap: (Song song) {
                ref.read(playerProvider.notifier).playSong(song);
              },
              onSongAction: (Song song, SongAction action) {
                _handleAction(context, ref, song, action);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    Song song,
    SongAction action,
  ) {
    switch (action) {
      case SongAction.play:
        ref.read(playerProvider.notifier).playSong(song);
      case SongAction.playNext:
      case SongAction.addToQueue:
      case SongAction.favorite:
        break;
    }
  }
}

class _HomeSearchField extends StatelessWidget {
  const _HomeSearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      onTap: onTap,
      readOnly: true,
      decoration: InputDecoration(
        hintText: '搜索歌曲、艺术家、专辑',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Icon(Icons.tune),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingMd,
          vertical: 12,
        ),
      ),
    );
  }
}

class _RecentPlayCard extends StatelessWidget {
  const _RecentPlayCard({required this.onSongTap, required this.onSongAction});

  final ValueChanged<Song> onSongTap;
  final void Function(Song song, SongAction action) onSongAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          for (final Song song in MockData.songs.take(6))
            SongTile(
              song: song,
              onTap: () => onSongTap(song),
              onAction: (SongAction action) => onSongAction(song, action),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/utils/motion.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../widgets/common/cover_artwork.dart';
import '../../widgets/player/player_progress.dart';

/// Desktop now-playing layout: large cover on the left, song info, controls
/// and lyrics on the right.
class NowPlayingDesktopLayout extends ConsumerWidget {
  const NowPlayingDesktopLayout({
    super.key,
    required this.song,
    required this.playerState,
  });

  final Song song;
  final PlayerState playerState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(width: AppSizes.spacingLg),
        CoverArtwork(
          title: song.title,
          coverKey: song.cover,
          size: 380,
          borderRadius: 28,
        ),
        const SizedBox(width: AppSizes.spacingXl),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, AppSizes.spacingLg, 24),
            children: <Widget>[
              NowPlayingSongTitle(song: song),
              const SizedBox(height: AppSizes.spacingSm),
              Text(
                song.artist,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSizes.spacingLg),
              PlayerProgressSlider(
                position: playerState.position,
                duration: playerState.duration,
                onSeek: ref.read(playerProvider.notifier).seek,
              ),
              const SizedBox(height: AppSizes.spacingMd),
              NowPlayingTransportControls(playerState: playerState),
              const SizedBox(height: AppSizes.spacingXl),
              Text(
                '歌词',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSizes.spacingSm),
              const LyricsPanel(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mobile/tablet now-playing layout: vertical cover, info, controls, lyrics.
class NowPlayingMobileLayout extends ConsumerWidget {
  const NowPlayingMobileLayout({
    super.key,
    required this.song,
    required this.playerState,
  });

  final Song song;
  final PlayerState playerState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double coverSize = constraints.maxWidth * 0.72;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.spacingLg,
            AppSizes.spacingSm,
            AppSizes.spacingLg,
            AppSizes.spacingXl,
          ),
          children: <Widget>[
            Center(
              child: CoverArtwork(
                title: song.title,
                coverKey: song.cover,
                size: coverSize,
                borderRadius: 24,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXl),
            NowPlayingSongTitle(song: song),
            const SizedBox(height: AppSizes.spacingXs),
            Text(
              song.artist,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLg),
            PlayerProgressSlider(
              position: playerState.position,
              duration: playerState.duration,
              onSeek: ref.read(playerProvider.notifier).seek,
            ),
            const SizedBox(height: AppSizes.spacingMd),
            NowPlayingTransportControls(playerState: playerState),
            const SizedBox(height: AppSizes.spacingXl),
            Text(
              '歌词',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.spacingSm),
            const LyricsPanel(),
          ],
        );
      },
    );
  }
}

class NowPlayingSongTitle extends StatelessWidget {
  const NowPlayingSongTitle({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    return Text(
      song.title,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class NowPlayingTransportControls extends ConsumerWidget {
  const NowPlayingTransportControls({super.key, required this.playerState});

  final PlayerState playerState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final PlayerNotifier notifier = ref.read(playerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          onPressed: notifier.toggleShuffle,
          icon: Icon(
            playerState.isShuffle ? Icons.shuffle : Icons.shuffle_outlined,
          ),
          color: playerState.isShuffle ? theme.colorScheme.primary : null,
          tooltip: '随机播放',
        ),
        const SizedBox(width: AppSizes.spacingSm),
        IconButton.filledTonal(
          onPressed: notifier.previous,
          icon: const Icon(Icons.skip_previous),
          tooltip: '上一首',
        ),
        const SizedBox(width: AppSizes.spacingSm),
        IconButton.filled(
          onPressed: notifier.togglePlayPause,
          iconSize: 40,
          padding: const EdgeInsets.all(16),
          style: IconButton.styleFrom(
            minimumSize: const Size(68, 68),
            shape: const CircleBorder(),
          ),
          tooltip: playerState.isPlaying ? '暂停' : '播放',
          icon: AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.emphasized),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Icon(
              playerState.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              key: ValueKey<bool>(playerState.isPlaying),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spacingSm),
        IconButton.filledTonal(
          onPressed: notifier.next,
          icon: const Icon(Icons.skip_next),
          tooltip: '下一首',
        ),
        const SizedBox(width: AppSizes.spacingSm),
        IconButton(
          onPressed: notifier.cycleRepeatMode,
          icon: Icon(
            playerState.repeatMode == RepeatMode.one
                ? Icons.repeat_one
                : Icons.repeat,
          ),
          color: playerState.repeatMode == RepeatMode.off
              ? null
              : theme.colorScheme.primary,
          tooltip: switch (playerState.repeatMode) {
            RepeatMode.off => '列表循环：关',
            RepeatMode.all => '列表循环：开',
            RepeatMode.one => '单曲循环：开',
          },
        ),
      ],
    );
  }
}

class LyricsPanel extends StatelessWidget {
  const LyricsPanel({super.key});

  static const List<({String text, bool active})> _lines =
      <({String text, bool active})>[
        (text: '在音乐中遇见更好的自己', active: true),
        (text: 'Midnight Drive · 让夜色带你前行', active: false),
        (text: 'The Nights · 那些夜晚值得铭记', active: false),
        (text: 'Fix You · 总有一束光为你而来', active: false),
        (text: 'Lemon · 酸涩之后，仍有回甘', active: false),
      ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.shapeLgIncreased),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final ({String text, bool active}) line in _lines) ...<Widget>[
            Text(
              line.text,
              style: line.active
                  ? theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    )
                  : theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
            const SizedBox(height: AppSizes.spacingSm),
          ],
        ],
      ),
    );
  }
}

class NoSongMessage extends StatelessWidget {
  const NoSongMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(child: Text('还没有正在播放的歌曲', style: theme.textTheme.bodyLarge));
  }
}

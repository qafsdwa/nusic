import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_sizes.dart';
import '../providers/player_provider.dart';
import '../widgets/cover_artwork.dart';

/// Full-screen "now playing" view with large cover art, transport controls and
/// a lyrics placeholder. State comes from [playerProvider].
class NowPlayingPage extends ConsumerWidget {
  const NowPlayingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;

    return Scaffold(
      appBar: AppBar(
        title: const Text('正在播放'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: song == null
                ? const _NoSongMessage()
                : LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final availableWidth = math.min(
                            constraints.maxWidth,
                            900.0,
                          );
                          final coverSize = availableWidth < 600
                              ? availableWidth * 0.62
                              : 340.0;
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSizes.spacingLg,
                              AppSizes.spacingLg,
                              AppSizes.spacingLg,
                              AppSizes.spacingXl,
                            ),
                            children: <Widget>[
                              Center(
                                child: CoverArtwork(
                                  title: song.title,
                                  coverKey: song.cover,
                                  size: coverSize,
                                  borderRadius: 28,
                                ),
                              ),
                              const SizedBox(height: AppSizes.spacingXl),
                              Center(
                                child: Text(
                                  song.title,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: AppSizes.spacingXs),
                              Center(
                                child: Text(
                                  song.artist,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.spacingLg),
                              _NowPlayingControls(
                                isPlaying: playerState.isPlaying,
                                onPrevious: () {
                                  ref.read(playerProvider.notifier).previous();
                                },
                                onToggle: () {
                                  ref
                                      .read(playerProvider.notifier)
                                      .togglePlayPause();
                                },
                                onNext: () {
                                  ref.read(playerProvider.notifier).next();
                                },
                              ),
                              const SizedBox(height: AppSizes.spacingXl),
                              Text(
                                '歌词',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSizes.spacingSm),
                              const _LyricsPlaceholder(),
                            ],
                          );
                        },
                  ),
          ),
        ),
      ),
    );
  }
}

class _NowPlayingControls extends StatelessWidget {
  const _NowPlayingControls({
    required this.isPlaying,
    required this.onPrevious,
    required this.onToggle,
    required this.onNext,
  });

  final bool isPlaying;
  final VoidCallback onPrevious;
  final VoidCallback onToggle;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton.filledTonal(
          onPressed: onPrevious,
          icon: const Icon(Icons.skip_previous),
          tooltip: '上一首',
        ),
        const SizedBox(width: AppSizes.spacingMd),
        IconButton.filled(
          onPressed: onToggle,
          iconSize: 40,
          padding: const EdgeInsets.all(12),
          icon: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
          tooltip: isPlaying ? '暂停' : '播放',
        ),
        const SizedBox(width: AppSizes.spacingMd),
        IconButton.filledTonal(
          onPressed: onNext,
          icon: const Icon(Icons.skip_next),
          tooltip: '下一首',
        ),
      ],
    );
  }
}

class _LyricsPlaceholder extends StatelessWidget {
  const _LyricsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 160,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          '歌词区域预留\n接入真实播放后，这里将随 Rust WebSocket 同步显示歌词',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _NoSongMessage extends StatelessWidget {
  const _NoSongMessage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(child: Text('还没有正在播放的歌曲', style: theme.textTheme.bodyLarge));
  }
}

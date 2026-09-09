import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/router.dart';
import '../core/constants/app_sizes.dart';
import '../core/utils/formatters.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import 'cover_artwork.dart';

/// Fixed bottom player bar.
///
/// It listens to [playerProvider] so the same widget can later receive state
/// from a real audio service and/or the Rust WebSocket without changing the UI.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(playerProvider);
    final song = state.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    final playerNotifier = ref.read(playerProvider.notifier);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: AppSizes.miniPlayerHeight,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth < 720) {
              return _CompactMiniPlayer(
                song: song,
                isPlaying: state.isPlaying,
                progress: state.position,
                duration: state.duration,
                onSongTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.nowPlaying);
                },
                onPrevious: playerNotifier.previous,
                onTogglePlayPause: playerNotifier.togglePlayPause,
                onNext: playerNotifier.next,
              );
            }
            return _WideMiniPlayer(
              song: song,
              isPlaying: state.isPlaying,
              progress: state.position,
              duration: state.duration,
              showVolume: constraints.maxWidth >= 1080,
              onSongTap: () {
                Navigator.of(context).pushNamed(AppRoutes.nowPlaying);
              },
              onPrevious: playerNotifier.previous,
              onTogglePlayPause: playerNotifier.togglePlayPause,
              onNext: playerNotifier.next,
              onSeek: playerNotifier.seek,
            );
          },
        ),
      ),
    );
  }
}

class _CompactMiniPlayer extends StatelessWidget {
  const _CompactMiniPlayer({
    required this.song,
    required this.isPlaying,
    required this.progress,
    required this.duration,
    required this.onSongTap,
    required this.onPrevious,
    required this.onTogglePlayPause,
    required this.onNext,
  });

  final Song song;
  final bool isPlaying;
  final Duration progress;
  final Duration duration;
  final VoidCallback onSongTap;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              const SizedBox(width: AppSizes.spacingXs),
              _MiniPlayerArtwork(song: song, onTap: onSongTap, size: 48),
              const SizedBox(width: AppSizes.spacingSm),
              Expanded(child: _MiniPlayerText(song: song)),
              _MiniPlayerControls(
                isPlaying: isPlaying,
                compact: true,
                onPrevious: onPrevious,
                onTogglePlayPause: onTogglePlayPause,
                onNext: onNext,
              ),
              const SizedBox(width: AppSizes.spacingXs),
            ],
          ),
        ),
        _MiniPlayerProgressLine(
          progress: progress,
          duration: duration,
          minHeight: 2,
        ),
      ],
    );
  }
}

class _WideMiniPlayer extends StatelessWidget {
  const _WideMiniPlayer({
    required this.song,
    required this.isPlaying,
    required this.progress,
    required this.duration,
    required this.showVolume,
    required this.onSongTap,
    required this.onPrevious,
    required this.onTogglePlayPause,
    required this.onNext,
    required this.onSeek,
  });

  final Song song;
  final bool isPlaying;
  final Duration progress;
  final Duration duration;
  final bool showVolume;
  final VoidCallback onSongTap;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onNext;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const SizedBox(width: AppSizes.spacingMd),
        SizedBox(
          width: 280,
          child: Row(
            children: <Widget>[
              _MiniPlayerArtwork(song: song, onTap: onSongTap),
              const SizedBox(width: AppSizes.spacingSm),
              Expanded(child: _MiniPlayerText(song: song)),
            ],
          ),
        ),
        Expanded(
          child: _MiniPlayerSlider(
            progress: progress,
            duration: duration,
            onChanged: onSeek,
          ),
        ),
        _MiniPlayerControls(
          isPlaying: isPlaying,
          onPrevious: onPrevious,
          onTogglePlayPause: onTogglePlayPause,
          onNext: onNext,
        ),
        if (showVolume) const _MiniPlayerVolume(),
        const SizedBox(width: AppSizes.spacingMd),
      ],
    );
  }
}

class _MiniPlayerArtwork extends StatelessWidget {
  const _MiniPlayerArtwork({
    required this.song,
    required this.onTap,
    this.size = 56,
  });

  final Song song;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: CoverArtwork(
        title: song.title,
        coverKey: song.cover,
        size: size,
        borderRadius: 10,
      ),
    );
  }
}

class _MiniPlayerText extends StatelessWidget {
  const _MiniPlayerText({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MiniPlayerControls extends StatelessWidget {
  const _MiniPlayerControls({
    required this.isPlaying,
    required this.onPrevious,
    required this.onTogglePlayPause,
    required this.onNext,
    this.compact = false,
  });

  final bool isPlaying;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onNext;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color? iconColor = compact ? theme.colorScheme.onSurface : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.skip_previous),
          tooltip: '上一首',
          color: iconColor,
        ),
        IconButton(
          onPressed: onTogglePlayPause,
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
          ),
          iconSize: compact ? 36 : 40,
          tooltip: isPlaying ? '暂停' : '播放',
          color: iconColor,
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.skip_next),
          tooltip: '下一首',
          color: iconColor,
        ),
      ],
    );
  }
}

class _MiniPlayerSlider extends StatelessWidget {
  const _MiniPlayerSlider({
    required this.progress,
    required this.duration,
    required this.onChanged,
  });

  final Duration progress;
  final Duration duration;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxMilliseconds = duration.inMilliseconds.toDouble();
    final value = progress.inMilliseconds.toDouble().clamp(
      0.0,
      maxMilliseconds > 0 ? maxMilliseconds : 1.0,
    );

    return Row(
      children: <Widget>[
        Text(
          formatDuration(progress),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            max: maxMilliseconds > 0 ? maxMilliseconds : 1.0,
            onChanged: (double newValue) {
              onChanged(Duration(milliseconds: newValue.round()));
            },
          ),
        ),
        Text(
          formatDuration(duration),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MiniPlayerProgressLine extends StatelessWidget {
  const _MiniPlayerProgressLine({
    required this.progress,
    required this.duration,
    required this.minHeight,
  });

  final Duration progress;
  final Duration duration;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final maxMilliseconds = duration.inMilliseconds.toDouble();
    final value = maxMilliseconds <= 0
        ? 0.0
        : (progress.inMilliseconds / maxMilliseconds).clamp(0.0, 1.0);

    return LinearProgressIndicator(
      value: value,
      minHeight: minHeight,
      borderRadius: BorderRadius.circular(2),
    );
  }
}

class _MiniPlayerVolume extends StatefulWidget {
  const _MiniPlayerVolume();

  @override
  State<_MiniPlayerVolume> createState() => _MiniPlayerVolumeState();
}

class _MiniPlayerVolumeState extends State<_MiniPlayerVolume> {
  double _volume = 0.7;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () {
              setState(() {
                _volume = _volume == 0 ? 0.7 : 0;
              });
            },
            icon: Icon(_volume == 0 ? Icons.volume_off : Icons.volume_up),
            tooltip: '音量',
          ),
          Expanded(
            child: Slider(
              value: _volume,
              onChanged: (double value) {
                setState(() => _volume = value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

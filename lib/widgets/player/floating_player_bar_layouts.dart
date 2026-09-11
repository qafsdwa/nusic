import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import '../../models/song.dart';
import '../common/cover_artwork.dart';
import 'player_controls.dart';
import 'player_progress.dart';

/// Desktop/tablet floating player bar content.
class DesktopFloatingPlayerBar extends StatelessWidget {
  const DesktopFloatingPlayerBar({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.progress,
    required this.duration,
    required this.isDesktop,
    required this.volume,
    required this.onTogglePlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onSeek,
    required this.onVolumeChanged,
  });

  final Song song;
  final bool isPlaying;
  final Duration progress;
  final Duration duration;
  final bool isDesktop;
  final double volume;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: isDesktop ? 264 : 216,
            child: NowPlayingIdentity(song: song),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: PlayerProgressSlider(
                position: progress,
                duration: duration,
                onSeek: onSeek,
                showPosition: true,
                showDuration: isDesktop,
              ),
            ),
          ),
          PlayerBarControls(
            isPlaying: isPlaying,
            onPrevious: onPrevious,
            onTogglePlayPause: onTogglePlayPause,
            onNext: onNext,
            showVolume: isDesktop,
            showQueue: true,
            volume: volume,
            onVolumeChanged: onVolumeChanged,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// Mobile floating player bar content.
class MobileFloatingPlayerBar extends StatelessWidget {
  const MobileFloatingPlayerBar({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.progress,
    required this.duration,
    required this.onTogglePlayPause,
  });

  final Song song;
  final bool isPlaying;
  final Duration progress;
  final Duration duration;
  final VoidCallback onTogglePlayPause;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: PlayerProgressLine(
            position: progress,
            duration: duration,
            minHeight: 2,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                NowPlayingArtwork(song: song, size: 50, borderRadius: 14),
                const SizedBox(width: AppSizes.spacingSm),
                Expanded(child: NowPlayingText(song: song)),
                MobilePlayButton(
                  isPlaying: isPlaying,
                  onTogglePlayPause: onTogglePlayPause,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Cover + song title/artist used by the desktop player bar left area.
class NowPlayingIdentity extends StatelessWidget {
  const NowPlayingIdentity({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        NowPlayingArtwork(song: song),
        const SizedBox(width: AppSizes.spacingSm),
        Expanded(child: NowPlayingText(song: song)),
      ],
    );
  }
}

class NowPlayingArtwork extends StatelessWidget {
  const NowPlayingArtwork({
    super.key,
    required this.song,
    this.size = 56,
    this.borderRadius = 14,
  });

  final Song song;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return CoverArtwork(
      title: song.title,
      coverKey: song.cover,
      size: size,
      borderRadius: borderRadius,
    );
  }
}

class NowPlayingText extends StatelessWidget {
  const NowPlayingText({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
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

class MobilePlayButton extends StatelessWidget {
  const MobilePlayButton({
    super.key,
    required this.isPlaying,
    required this.onTogglePlayPause,
  });

  final bool isPlaying;
  final VoidCallback onTogglePlayPause;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onTogglePlayPause,
      iconSize: 28,
      padding: const EdgeInsets.all(10),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: const CircleBorder(),
      ),
      tooltip: isPlaying ? '暂停' : '播放',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          key: ValueKey<bool>(isPlaying),
        ),
      ),
    );
  }
}

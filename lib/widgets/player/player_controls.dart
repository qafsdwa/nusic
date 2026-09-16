import 'package:flutter/material.dart';

import '../../core/utils/motion.dart';

/// Transport controls for the floating player bar.
///
/// Play / Pause is the visual center and uses an animated icon switch so the
/// state change reads as a calm, deliberate transition.
class PlayerBarControls extends StatelessWidget {
  const PlayerBarControls({
    super.key,
    required this.isPlaying,
    required this.onPrevious,
    required this.onTogglePlayPause,
    required this.onNext,
    this.showVolume = false,
    this.volume = 0.7,
    this.onVolumeChanged,
  });

  final bool isPlaying;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onNext;
  final bool showVolume;
  final double volume;
  final ValueChanged<double>? onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.skip_previous),
          tooltip: '上一首',
        ),
        const SizedBox(width: 2),
        IconButton.filled(
          onPressed: onTogglePlayPause,
          iconSize: 32,
          padding: const EdgeInsets.all(14),
          style: IconButton.styleFrom(
            minimumSize: const Size(52, 52),
            shape: const CircleBorder(),
          ),
          tooltip: isPlaying ? '暂停' : '播放',
          icon: AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.standard),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey<bool>(isPlaying),
            ),
          ),
        ),
        const SizedBox(width: 2),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.skip_next),
          tooltip: '下一首',
        ),
        if (showVolume) ...<Widget>[
          const SizedBox(width: 4),
          SizedBox(
            width: 132,
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    onVolumeChanged?.call(volume == 0 ? 0.7 : 0);
                  },
                  icon: Icon(volume == 0 ? Icons.volume_off : Icons.volume_up),
                  tooltip: volume == 0 ? '取消静音' : '静音',
                ),
                Expanded(
                  child: Slider(
                    value: volume.clamp(0.0, 1.0),
                    onChanged: onVolumeChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

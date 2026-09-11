import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

import '../../core/utils/formatters.dart';

/// Slim desktop/tablet progress row: current time, slider, duration.
class PlayerProgressSlider extends StatelessWidget {
  const PlayerProgressSlider({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.showDuration = true,
    this.showPosition = true,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final bool showDuration;
  final bool showPosition;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int maxMilliseconds = duration.inMilliseconds;
    final double value = position.inMilliseconds.toDouble().clamp(
      0.0,
      maxMilliseconds > 0 ? maxMilliseconds.toDouble() : 1.0,
    );

    return Row(
      children: <Widget>[
        if (showPosition) ...<Widget>[
          Text(
            formatDuration(position),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSizes.spacingSm),
        ],
        Expanded(
          child: Slider(
            value: value,
            max: maxMilliseconds > 0 ? maxMilliseconds.toDouble() : 1.0,
            onChanged: (double newValue) {
              onSeek(Duration(milliseconds: newValue.round()));
            },
          ),
        ),
        if (showDuration) ...<Widget>[
          const SizedBox(width: AppSizes.spacingSm),
          Text(
            formatDuration(duration),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

/// Very thin progress line used by the compact mobile player bar.
class PlayerProgressLine extends StatelessWidget {
  const PlayerProgressLine({
    super.key,
    required this.position,
    required this.duration,
    this.minHeight = 2,
  });

  final Duration position;
  final Duration duration;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final int maxMilliseconds = duration.inMilliseconds;
    final double value = maxMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / maxMilliseconds).clamp(0.0, 1.0);

    return LinearProgressIndicator(
      value: value,
      minHeight: minHeight,
      borderRadius: BorderRadius.circular(2),
    );
  }
}

/// Utility functions shared across UI widgets.
library;

/// Formats a [Duration] as a compact time string.
///
/// Returns `m:ss` (or `mm:ss` when minutes exceed 9) for durations under an
/// hour, and `hh:mm:ss` for durations of one hour or longer.
String formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString();
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = duration.inHours;
  if (hours > 0) {
    final hourText = hours.toString().padLeft(2, '0');
    final minuteText = minutes.padLeft(2, '0');
    return '$hourText:$minuteText:$seconds';
  }
  return '$minutes:$seconds';
}

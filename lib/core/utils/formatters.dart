/// Formats a [Duration] as a compact time string.
///
/// Returns `m:ss` (or `mm:ss` when minutes exceed 9) for durations under an
/// hour, and `hh:mm:ss` for durations of one hour or longer.
String formatDuration(Duration duration) {
  final int minutes = duration.inMinutes.remainder(60);
  final String seconds = duration.inSeconds
      .remainder(60)
      .toString()
      .padLeft(2, '0');
  final int hours = duration.inHours;
  if (hours > 0) {
    final String hourText = hours.toString().padLeft(2, '0');
    final String minuteText = minutes.toString().padLeft(2, '0');
    return '$hourText:$minuteText:$seconds';
  }
  return '$minutes:$seconds';
}

class TimeFormatter {
  static String formatMinutesSeconds(Duration duration) {
    final m = duration.inMinutes.toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String formatForDisplay(Duration duration) {
    if (duration.inHours > 0) {
      final h = duration.inHours.toString().padLeft(2, '0');
      final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    return formatMinutesSeconds(duration);
  }
}

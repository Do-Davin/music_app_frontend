import '../../data/models/lrc_line.dart';

class LrcLine {
  final Duration timestamp;
  final String text;

  LrcLine({required this.timestamp, required this.text});

  // ADD THIS STATIC METHOD
  static LrcLine parse(String line) {
    // Example format: [00:12.50] Hello world
    final regExp = RegExp(r'^\[(\d{2}):(\d{2}\.\d{2})\](.*)$');
    final match = regExp.firstMatch(line);

    if (match == null) {
      throw FormatException('Invalid LRC line format');
    }

    final minutes = int.parse(match.group(1)!);
    final secondsAndMillis = double.parse(match.group(2)!);
    final text = match.group(3)!.trim();

    return LrcLine(
      timestamp: Duration(
        minutes: minutes,
        seconds: secondsAndMillis.toInt(),
        milliseconds: ((secondsAndMillis - secondsAndMillis.toInt()) * 1000)
            .toInt(),
      ),
      text: text,
    );
  }
}

import '../../data/models/lrc_line.dart';

/// Parses standard and Enhanced LRC format lyrics.
///
/// Standard LRC:  `[00:12.50]Hello world`
/// Enhanced LRC:  `[00:12.50]<00:12.50>Hello <00:13.20>world`
class LrcParser {
  /// Parse a single LRC line string into an [LrcLine].
  ///
  /// Supports both standard format (line-level only) and enhanced format
  /// (with inline `<mm:ss.xx>` word timestamps).
  static LrcLine parseLine(String line) {
    // Match the line-level timestamp: [mm:ss.xx] or [mm:ss.xxx]
    final lineRegex = RegExp(r'^\[(\d+):(\d+[.:]\d+)\](.*)$');
    final match = lineRegex.firstMatch(line);

    if (match == null) {
      throw const FormatException('Invalid LRC line format');
    }

    final minutes = int.parse(match.group(1)!);
    final secStr = match.group(2)!.replaceAll(':', '.');
    final secondsAndMillis = double.parse(secStr);
    final content = match.group(3)!;

    final lineTimestamp = Duration(
      minutes: minutes,
      seconds: secondsAndMillis.toInt(),
      milliseconds: ((secondsAndMillis - secondsAndMillis.toInt()) * 1000)
          .toInt(),
    );

    // Try to parse Enhanced LRC word timestamps: <mm:ss.xx>word
    final wordRegex = RegExp(r'<(\d+):(\d+[.:]\d+)>([^<]*)');
    final wordMatches = wordRegex.allMatches(content);

    if (wordMatches.isNotEmpty) {
      // Enhanced LRC — extract word-level timing
      final words = <LrcWord>[];
      for (final wm in wordMatches) {
        final wMin = int.parse(wm.group(1)!);
        final wSecStr = wm.group(2)!.replaceAll(':', '.');
        final wSec = double.parse(wSecStr);
        final wText = wm.group(3)!;

        if (wText.trim().isEmpty) continue;

        words.add(
          LrcWord(
            timestamp: Duration(
              minutes: wMin,
              seconds: wSec.toInt(),
              milliseconds: ((wSec - wSec.toInt()) * 1000).toInt(),
            ),
            text: wText.trimRight(), // keep leading space for display
          ),
        );
      }

      final fullText = words.map((w) => w.text).join(' ');
      return LrcLine(
        timestamp: lineTimestamp,
        text: fullText,
        words: words.isNotEmpty ? words : null,
      );
    }

    // Standard LRC — line-level only
    return LrcLine(timestamp: lineTimestamp, text: content.trim());
  }

  /// Parse a full LRC file content into a list of [LrcLine]s.
  ///
  /// Skips metadata tags like `[ti:...]`, `[ar:...]`, etc.
  /// Returns lines sorted by timestamp.
  static List<LrcLine> parseContent(String content) {
    final lines = content.split('\n');
    final result = <LrcLine>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Skip metadata tags: [ti:...], [ar:...], [al:...], [by:...], [offset:...]
      if (RegExp(r'^\[(ti|ar|al|by|offset|re|ve):').hasMatch(line)) continue;

      try {
        result.add(parseLine(line));
      } catch (_) {
        // Skip unparseable lines
      }
    }

    // Sort by timestamp
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }
}

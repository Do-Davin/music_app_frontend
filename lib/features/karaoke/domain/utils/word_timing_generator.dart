import '../../data/models/lrc_line.dart';

/// Generates word-level timing from line-level timestamps.
///
/// For lines that don't already have word timing, this distributes
/// the line's duration across its words proportionally based on
/// character length. This gives approximate word-by-word highlighting
/// even from standard LRC files.
class WordTimingGenerator {
  /// Generate word-level timing for all lines that don't already have it.
  ///
  /// [lyrics] - the list of lyric lines with line-level timestamps.
  /// Returns a new list with auto-generated word timing attached.
  static List<LrcLine> generateWordTiming(List<LrcLine> lyrics) {
    if (lyrics.isEmpty) return lyrics;

    final result = <LrcLine>[];

    for (int i = 0; i < lyrics.length; i++) {
      final line = lyrics[i];

      // Skip if already has word timing or text is empty
      if (line.hasWordTiming || line.text.trim().isEmpty) {
        result.add(line);
        continue;
      }

      // Calculate line duration: from this line's start to next line's start
      final lineStart = line.timestamp;
      Duration lineEnd;
      if (i + 1 < lyrics.length) {
        lineEnd = lyrics[i + 1].timestamp;
      } else {
        // Last line: assume 5 seconds duration
        lineEnd = lineStart + const Duration(seconds: 5);
      }

      final lineDuration = lineEnd - lineStart;
      if (lineDuration.inMilliseconds <= 0) {
        result.add(line);
        continue;
      }

      // Split text into words
      final rawWords = line.text.split(RegExp(r'\s+'));
      if (rawWords.length <= 1) {
        // Single word — just use line timestamp
        result.add(line.copyWith(
          words: [LrcWord(timestamp: lineStart, text: line.text.trim())],
        ));
        continue;
      }

      // Distribute time proportionally by character count
      final totalChars = rawWords.fold<int>(0, (sum, w) => sum + w.length);
      if (totalChars == 0) {
        result.add(line);
        continue;
      }

      final words = <LrcWord>[];
      var currentOffset = lineStart;

      for (int w = 0; w < rawWords.length; w++) {
        final word = rawWords[w];
        words.add(LrcWord(timestamp: currentOffset, text: word));

        // Calculate this word's duration proportional to its character count
        final wordDurationMs =
            (lineDuration.inMilliseconds * word.length / totalChars).round();
        currentOffset = currentOffset + Duration(milliseconds: wordDurationMs);
      }

      result.add(line.copyWith(words: words));
    }

    return result;
  }
}

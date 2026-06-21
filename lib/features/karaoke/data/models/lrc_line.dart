/// Represents a single word with its own timestamp for word-by-word karaoke.
class LrcWord {
  final Duration timestamp;
  final String text;

  LrcWord({required this.timestamp, required this.text});

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.inMilliseconds,
    'text': text,
  };

  factory LrcWord.fromJson(Map<String, dynamic> json) {
    final timestamp = json['timestamp'];
    if (timestamp == null) {
      throw FormatException('LrcWord timestamp is null in JSON: $json');
    }

    final text = json['text'];
    if (text == null) {
      throw FormatException('LrcWord text is null in JSON: $json');
    }

    return LrcWord(
      timestamp: Duration(milliseconds: (timestamp as num).round()),
      text: text as String,
    );
  }

  @override
  String toString() => '<${_formatDuration(timestamp)}>$text';

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final c = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(
      2,
      '0',
    );
    return '$m:$s.$c';
  }
}

/// Represents a single line of lyrics with a timestamp.
/// Optionally contains [words] for word-by-word karaoke highlighting.
/// When [words] is null or empty, the player falls back to line-level highlighting.
class LrcLine {
  final Duration timestamp;
  final String text;
  final List<LrcWord>? words;

  LrcLine({required this.timestamp, required this.text, this.words});

  /// Whether this line has word-level timing data.
  bool get hasWordTiming => words != null && words!.isNotEmpty;

  String get formattedTime {
    final m = timestamp.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = timestamp.inSeconds.remainder(60).toString().padLeft(2, '0');
    final c = (timestamp.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '[$m:$s.$c]';
  }

  LrcLine copyWith({Duration? timestamp, String? text, List<LrcWord>? words}) {
    return LrcLine(
      timestamp: timestamp ?? this.timestamp,
      text: text ?? this.text,
      words: words ?? this.words,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.inMilliseconds,
    'text': text,
    if (words != null && words!.isNotEmpty)
      'words': words!.map((w) => w.toJson()).toList(),
  };

  factory LrcLine.fromJson(Map<String, dynamic> json) {
    List<LrcWord>? words;
    if (json['words'] != null) {
      words = (json['words'] as List)
          .map((w) => LrcWord.fromJson(w as Map<String, dynamic>))
          .toList();
    }

    final timestamp = json['timestamp'];
    if (timestamp == null) {
      throw FormatException('LrcLine timestamp is null in JSON: $json');
    }

    final text = json['text'];
    if (text == null) {
      throw FormatException('LrcLine text is null in JSON: $json');
    }

    return LrcLine(
      timestamp: Duration(milliseconds: (timestamp as num).round()),
      text: text as String,
      words: words,
    );
  }

  @override
  String toString() {
    if (hasWordTiming) {
      return '$formattedTime${words!.map((w) => w.toString()).join(' ')}';
    }
    return '$formattedTime$text';
  }
}

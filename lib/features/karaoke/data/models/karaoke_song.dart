import 'lrc_line.dart';

enum SongSource { youtube, local }

class KaraokeSong {
  final String id;
  final String title;
  final String? artist;
  final SongSource source;
  final String sourcePath; // YouTube URL or local file path
  final List<LrcLine> lyrics;
  final DateTime createdAt;
  final Duration? duration;

  KaraokeSong({
    required this.id,
    required this.title,
    this.artist,
    required this.source,
    required this.sourcePath,
    required this.lyrics,
    this.duration,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  // Add this method inside the KaraokeSong class
  KaraokeSong copyWith({
    String? id,
    String? title,
    String? artist,
    SongSource? source,
    String? sourcePath,
    List<LrcLine>? lyrics,
    Duration? duration,
    DateTime? createdAt,
  }) {
    return KaraokeSong(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      source: source ?? this.source,
      sourcePath: sourcePath ?? this.sourcePath,
      lyrics: lyrics ?? this.lyrics,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'source': source.name,
      'sourcePath': sourcePath,
      'lyrics': lyrics.map((l) => l.toJson()).toList(),
      'duration': duration?.inMilliseconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory KaraokeSong.fromJson(Map<String, dynamic> json) {
    return KaraokeSong(
      id: (json['id'] ?? json['_id']) as String,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      source: SongSource.values.byName((json['source'] as String).toLowerCase()),
      sourcePath: json['sourcePath'] as String,
      lyrics: ((json['lyrics'] as List?) ?? [])
          .map((l) => LrcLine.fromJson(l as Map<String, dynamic>))
          .toList(),
      duration: json['duration'] != null
          ? Duration(milliseconds: (json['duration'] as num).round())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

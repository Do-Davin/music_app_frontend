class Song {
  final String id;
  final String title;
  final String artist;
  final String? albumName;
  final int? duration;
  final String? key;
  final int? tempo;
  final String? difficulty;
  final List<String>? tags;
  /// Source type: 'mp3' or 'youtube'
  final String? source;
  /// File path (mp3) or YouTube URL
  final String? sourcePath;
  final String? fileUrl;
  final String? videoUrl;
  final String? coverImageUrl;
  final String? lyrics;
  final String? chordNotationStyle;
  final bool isPublic;
  final int playCount;
  final String? userId;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.albumName,
    this.duration,
    this.key,
    this.tempo,
    this.difficulty,
    this.tags,
    this.source,
    this.sourcePath,
    this.fileUrl,
    this.videoUrl,
    this.coverImageUrl,
    this.lyrics,
    this.chordNotationStyle,
    this.isPublic = false,
    this.playCount = 0,
    this.userId,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title']?.toString() ?? 'Untitled',
      artist: json['artist']?.toString() ?? 'Unknown Artist',
      albumName: json['albumName']?.toString(),
      duration: (json['duration'] as num?)?.toInt(),
      key: json['key']?.toString(),
      tempo: (json['tempo'] as num?)?.toInt(),
      difficulty: json['difficulty']?.toString(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      source: json['source']?.toString(),
      sourcePath: json['sourcePath']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      lyrics: json['lyrics']?.toString(),
      chordNotationStyle: json['chordNotationStyle']?.toString(),
      isPublic: json['isPublic'] == true,
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      userId: json['userId']?.toString(),
    );
  }

  /// Returns the best playback URL: sourcePath first, then videoUrl/fileUrl as fallback.
  String? get audioUrl {
    for (final value in [sourcePath, videoUrl, fileUrl]) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }

    return null;
  }

  /// Whether this song is played via YouTube.
  bool get isYoutube {
    if (source == 'youtube') return true;

    final url = audioUrl?.toLowerCase();
    if (url == null) return false;

    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'artist': artist,
      'albumName': albumName,
      'duration': duration,
      'key': key,
      'tempo': tempo,
      'difficulty': difficulty,
      'tags': tags,
      'source': source,
      'sourcePath': sourcePath,
      'fileUrl': fileUrl,
      'videoUrl': videoUrl,
      'coverImageUrl': coverImageUrl,
      'lyrics': lyrics,
      'chordNotationStyle': chordNotationStyle,
      'isPublic': isPublic,
      'playCount': playCount,
    };
  }
}

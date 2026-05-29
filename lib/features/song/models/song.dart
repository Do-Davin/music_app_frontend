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
  final bool isFavorite;

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
    this.isFavorite = false,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['_id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      albumName: json['albumName'] as String?,
      duration: json['duration'] as int?,
      key: json['key'] as String?,
      tempo: json['tempo'] as int?,
      difficulty: json['difficulty'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      source: json['source'] as String?,
      sourcePath: json['sourcePath'] as String?,
      fileUrl: json['fileUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      lyrics: json['lyrics'] as String?,
      chordNotationStyle: json['chordNotationStyle'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      playCount: json['playCount'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  /// Returns the best playback URL: sourcePath first, then videoUrl/fileUrl as fallback.
  String? get audioUrl => sourcePath ?? videoUrl ?? fileUrl;

  /// Whether this song is played via YouTube.
  bool get isYoutube => source == 'youtube';

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
      'isFavorite': isFavorite,
    };
  }

  /// Create a copy of this Song with modified fields
  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumName,
    int? duration,
    String? key,
    int? tempo,
    String? difficulty,
    List<String>? tags,
    String? source,
    String? sourcePath,
    String? fileUrl,
    String? videoUrl,
    String? coverImageUrl,
    String? lyrics,
    String? chordNotationStyle,
    bool? isPublic,
    int? playCount,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumName: albumName ?? this.albumName,
      duration: duration ?? this.duration,
      key: key ?? this.key,
      tempo: tempo ?? this.tempo,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      sourcePath: sourcePath ?? this.sourcePath,
      fileUrl: fileUrl ?? this.fileUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      lyrics: lyrics ?? this.lyrics,
      chordNotationStyle: chordNotationStyle ?? this.chordNotationStyle,
      isPublic: isPublic ?? this.isPublic,
      playCount: playCount ?? this.playCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

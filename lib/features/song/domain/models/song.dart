class Song {
  final String id;
  final String title;
  final String artist;
  final String? albumName;
  final int duration;
  final String? key;
  final int? tempo;
  final String? difficulty;
  final List<String>? tags;
  final String? fileUrl;
  final String? videoUrl;
  final String? coverImageUrl;
  final String? lyrics;
  final String? chordNotationStyle;
  final bool isPublic;
  final int playCount;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.albumName,
    required this.duration,
    this.key,
    this.tempo,
    this.difficulty,
    this.tags,
    this.fileUrl,
    this.videoUrl,
    this.coverImageUrl,
    this.lyrics,
    this.chordNotationStyle,
    this.isPublic = false,
    this.playCount = 0,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['_id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      albumName: json['albumName'] as String?,
      duration: json['duration'] as int,
      key: json['key'] as String?,
      tempo: json['tempo'] as int?,
      difficulty: json['difficulty'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      fileUrl: json['fileUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      lyrics: json['lyrics'] as String?,
      chordNotationStyle: json['chordNotationStyle'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      playCount: json['playCount'] as int? ?? 0,
    );
  }
}

import '../../song/models/song.dart';

class Playlist {
  final String id;
  final String? userId;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final List<String>? songIds;
  final List<String>? savedUserIds;
  final List<Song>? songs;
  final bool isPublic;
  final bool isKaraoke;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Playlist({
    required this.id,
    this.userId,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.songIds,
    this.savedUserIds,
    this.songs,
    this.isPublic = false,
    this.isKaraoke = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: (json['userId'] ?? json['ownerId'])?.toString(),
      name: json['name']?.toString() ?? 'Unnamed Playlist',
      description: json['description']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      songIds: (json['songIds'] as List<dynamic>?)
          ?.map((e) => e?.toString())
          .whereType<String>()
          .toList(),
      savedUserIds: (json['savedUserIds'] as List<dynamic>?)
          ?.map((e) => e?.toString())
          .whereType<String>()
          .toList(),
      songs: (json['songs'] as List<dynamic>?)
          ?.map(
            (song) => song != null
                ? Song.fromJson(song as Map<String, dynamic>)
                : null,
          )
          .whereType<Song>()
          .toList(),
      isPublic: json['isPublic'] == true,
      isKaraoke: json['isKaraoke'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Playlist copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? coverImageUrl,
    List<String>? songIds,
    List<String>? savedUserIds,
    List<Song>? songs,
    bool? isPublic,
    bool? isKaraoke,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      songIds: songIds ?? this.songIds,
      savedUserIds: savedUserIds ?? this.savedUserIds,
      songs: songs ?? this.songs,
      isPublic: isPublic ?? this.isPublic,
      isKaraoke: isKaraoke ?? this.isKaraoke,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

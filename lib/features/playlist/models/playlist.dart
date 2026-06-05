import '../../song/models/song.dart';

class Playlist {
  final String id;
  final String? userId;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final List<String>? songIds;
  final List<Song>? songs;
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Playlist({
    required this.id,
    this.userId,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.songIds,
    this.songs,
    this.isPublic = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['_id'] as String,
      userId: json['userId'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      songIds: (json['songIds'] as List<dynamic>?)?.cast<String>(),
      songs: (json['songs'] as List<dynamic>?)
          ?.map((song) => Song.fromJson(song as Map<String, dynamic>))
          .toList(),
      isPublic: json['isPublic'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
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
    List<Song>? songs,
    bool? isPublic,
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
      songs: songs ?? this.songs,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

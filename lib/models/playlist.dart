class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final List<String>? songIds;
  final bool isPublic;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.songIds,
    this.isPublic = false,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      songIds: (json['songIds'] as List<dynamic>?)?.cast<String>(),
      isPublic: json['isPublic'] as bool? ?? false,
    );
  }
}

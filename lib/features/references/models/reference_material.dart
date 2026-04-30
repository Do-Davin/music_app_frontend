class ReferenceMaterial {
  final String id;
  final String title;
  final String type;
  final String? description;
  final String? fileUrl;
  final String? songId;
  final String? topic;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReferenceMaterial({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    this.fileUrl,
    this.songId,
    this.topic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReferenceMaterial.fromJson(Map<String, dynamic> json) {
    return ReferenceMaterial(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      description: json['description'],
      fileUrl: json['fileUrl'],
      songId: json['songId'],
      topic: json['topic'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
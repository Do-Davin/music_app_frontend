import '../services/reference_material_service.dart';

class ReferenceMaterial {
  final String id;
  final String title;
  final String type;
  final String? description;
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? songId;
  final String? topic;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReferenceMaterial({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    this.filePath,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.songId,
    this.topic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReferenceMaterial.fromJson(Map<String, dynamic> json) {
    return ReferenceMaterial(
      id: json['_id'],
      title: json['title'],
      type: json['type'],
      description: json['description'],
      filePath: json['filePath'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      songId: json['songId'],
      topic: json['topic'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Helper to get full file URL
  String? get fileUrl {
    if (filePath == null) return null;
    return '${ReferenceMaterialService.baseUrl}$filePath';
  }

  // Helper to format file size
  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Helper to format time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Added just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return 'Added ${mins} ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Added ${hours} ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'Added ${days} ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Added ${weeks} ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Added ${months} ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Added ${years} ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
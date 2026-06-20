import 'package:music_app_frontend/core/network/graphql_config.dart';

class ReferenceMaterial {
  final String id;
  final String title;
  final String type;
  final String? description;
  final String? filePath;
  /// Full URL returned by the backend (includes BASE_URL prefix).
  final String? fileUrl;
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
    this.fileUrl,
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
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: json['title']?.toString() ?? 'Untitled',
      type: json['type']?.toString() ?? 'Other',
      description: json['description']?.toString(),
      filePath: json['filePath']?.toString(),
      fileUrl: _rewriteUrl(json['fileUrl']?.toString()),
      fileName: json['fileName']?.toString(),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType']?.toString(),
      songId: json['songId']?.toString(),
      topic: json['topic']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Rewrites the host in a backend-returned URL to match the runtime server
  /// the app is actually talking to.
  /// Fixes the localhost vs 10.0.2.2 vs real device IP mismatch: the backend
  /// builds fileUrl using BASE_URL (defaults to localhost:3000), but a physical
  /// device or a different emulator host can't reach localhost on the PC.
  static String? _rewriteUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final serverBase = GraphQLConfig.serverBaseUrl;
    if (serverBase.isEmpty) return url;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return url;
    final serverUri = Uri.tryParse(serverBase);
    if (serverUri == null) return url;
    return uri
        .replace(
          scheme: serverUri.scheme,
          host: serverUri.host,
          port: serverUri.hasPort ? serverUri.port : -1,
        )
        .toString();
  }

  /// Returns the best available URL for downloading/previewing the file.
  /// Prefers [fileUrl] (full URL from the backend), but falls back to
  /// constructing a download URL using the material's ID.
  String? get downloadUrl {
    if (fileUrl != null && fileUrl!.isNotEmpty) return fileUrl;
    // Fallback: build the download URL from the material ID
    final serverBase = GraphQLConfig.serverBaseUrl;
    if (serverBase.isNotEmpty && id.isNotEmpty) {
      return '$serverBase/references/$id/download';
    }
    return null;
  }

  /// Whether this material has a file attached.
  bool get hasFile => downloadUrl != null;

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
      return 'Added $mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Added $hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'Added $days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Added $weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Added $months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Added $years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
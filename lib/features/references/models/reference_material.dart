// No imports needed — all fields are primitive types

class ReferenceMaterial {
  final String id;
  final String title;
  final String type;
  final String? description;

  /// Cloudinary public_id — used internally by the backend for deletion.
  /// Not used for building preview URLs in the frontend.
  final String? filePath;

  /// Cloudinary secure_url — the direct URL to the uploaded asset.
  /// Use this for all previewing and downloading.
  final String? fileUrl;

  /// Cloudinary resource_type ('image', 'video', 'raw').
  /// Helps the frontend decide which viewer to use.
  final String? cloudinaryResourceType;

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
    this.cloudinaryResourceType,
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
      // Cloudinary URLs are absolute (https://res.cloudinary.com/...) —
      // no host rewriting needed; they are globally accessible.
      fileUrl: json['fileUrl']?.toString(),
      cloudinaryResourceType: json['cloudinaryResourceType']?.toString(),
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

  /// Returns the correct Cloudinary delivery URL for this file.
  ///
  /// Existing records uploaded when `resource_type: 'auto'` was used may have
  /// `cloudinaryResourceType = "image"` even for PDFs. In that case the stored
  /// `fileUrl` contains `/image/upload/` which Cloudinary cannot serve as PDF
  /// bytes. We detect the mismatch and rewrite the URL to `/raw/upload/` so
  /// the PDF viewer receives the actual file bytes.
  ///
  /// Falls back to extension/type detection when `mimeType` or
  /// `cloudinaryResourceType` is missing (older records).
  String? get downloadUrl {
    if (fileUrl == null || fileUrl!.isEmpty) return null;

    // A record is a "document" if we can confirm it from any available signal:
    // MIME type, file name extension, or the material's type field.
    final isDocument = _isDocumentMime(mimeType) ||
        _isDocumentExtension(fileName) ||
        _isDocumentType(type);

    // Cloudinary misclassified documents as 'image' (or resourceType is null,
    // which means it was uploaded before this field was stored — also unsafe).
    // In both cases, if the URL still contains /image/upload/, rewrite it.
    final storedAsImage = cloudinaryResourceType == 'image' ||
        cloudinaryResourceType == null;

    if (isDocument && storedAsImage && fileUrl!.contains('/image/upload/')) {
      return fileUrl!.replaceFirst('/image/upload/', '/raw/upload/');
    }

    return fileUrl;
  }

  /// Returns true when the MIME type indicates a non-image document.
  static bool _isDocumentMime(String? mime) {
    if (mime == null) return false;
    const docMimes = {
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/plain',
    };
    return docMimes.contains(mime.toLowerCase()) ||
        mime.startsWith('text/') && !mime.startsWith('text/html');
  }

  /// Returns true when the file name extension indicates a document.
  /// Used as a fallback when [mimeType] is null (older records).
  static bool _isDocumentExtension(String? name) {
    if (name == null) return false;
    const docExtensions = {
      'pdf', 'doc', 'docx', 'ppt', 'pptx',
      'xls', 'xlsx', 'txt', 'csv', 'odt', 'odp', 'ods',
    };
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return docExtensions.contains(ext);
  }

  /// Returns true when the material's [type] field indicates a document.
  /// Used as a fallback when both [mimeType] and [fileName] are unavailable.
  static bool _isDocumentType(String? t) {
    if (t == null) return false;
    const docTypes = {'pdf', 'ppt', 'doc', 'sheet music', 'note'};
    return docTypes.contains(t.toLowerCase());
  }

  /// Whether this material has a file attached.
  bool get hasFile => downloadUrl != null;

  // Helper to format file size
  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    if (fileSize! < 1024) {
      return '$fileSize B';
    }
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
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

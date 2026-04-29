class PracticeSession {
  final String id;
  final String title;
  final DateTime practiceDate;
  final int duration; // in minutes
  final String focusArea; // KARAOKE, VOCAL, TIMING, LYRICS
  final String? notes;
  final int rating; // 1-5
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PracticeSession({
    required this.id,
    required this.title,
    required this.practiceDate,
    required this.duration,
    required this.focusArea,
    this.notes,
    required this.rating,
    this.createdAt,
    this.updatedAt,
  });

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      id: json['_id'] as String,
      title: json['title'] as String,
      practiceDate: DateTime.parse(json['practiceDate'] as String),
      duration: json['duration'] as int,
      focusArea: json['focusArea'] as String,
      notes: json['notes'] as String?,
      rating: json['rating'] as int,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'practiceDate': practiceDate.toIso8601String(),
      'duration': duration,
      'focusArea': focusArea,
      'notes': notes,
      'rating': rating,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

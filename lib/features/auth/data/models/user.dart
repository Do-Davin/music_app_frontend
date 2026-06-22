class User {
  static const String personalProfileType = 'PERSONAL';
  static const String professionalProfileType = 'PROFESSIONAL';

  final String id;
  final String username;
  final String email;
  final String profileType;
  final String? profileImageUrl;
  final String? profileImageThumbnailUrl;
  final int? practiceGoalsDailyMinutes;
  final int? practiceGoalsWeeklyDays;
  final int? practiceStreakCurrentStreak;
  final int? practiceStreakLongestStreak;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileType = personalProfileType,
    this.profileImageUrl,
    this.profileImageThumbnailUrl,
    this.practiceGoalsDailyMinutes,
    this.practiceGoalsWeeklyDays,
    this.practiceStreakCurrentStreak,
    this.practiceStreakLongestStreak,
  });

  /// Thumbnail URL for small avatar display; falls back to full-size URL.
  String? get effectiveAvatarUrl => profileImageThumbnailUrl ?? profileImageUrl;

  factory User.fromJson(Map<String, dynamic> json) {
    final practiceGoals = json['practiceGoals'] as Map<String, dynamic>?;
    final practiceStreak = json['practiceStreak'] as Map<String, dynamic>?;

    return User(
      id: json['_id'] as String,
      username: (json['username'] as String?) ?? '',
      email: json['email'] as String,
      profileType: _parseProfileType(json['profileType']),
      profileImageUrl: json['profileImageUrl'] as String?,
      profileImageThumbnailUrl: json['profileImageThumbnailUrl'] as String?,
      practiceGoalsDailyMinutes: practiceGoals?['dailyMinutes'] as int?,
      practiceGoalsWeeklyDays: practiceGoals?['weeklyDays'] as int?,
      practiceStreakCurrentStreak: practiceStreak?['currentStreak'] as int?,
      practiceStreakLongestStreak: practiceStreak?['longestStreak'] as int?,
    );
  }

  static String _parseProfileType(Object? value) {
    if (value is! String) return personalProfileType;

    final normalized = value.trim().toUpperCase();
    return switch (normalized) {
      personalProfileType || professionalProfileType => normalized,
      _ => personalProfileType,
    };
  }
}

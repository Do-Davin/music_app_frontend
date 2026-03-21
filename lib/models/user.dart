class User {
  final String id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final int? practiceGoalsDailyMinutes;
  final int? practiceGoalsWeeklyDays;
  final int? practiceStreakCurrentStreak;
  final int? practiceStreakLongestStreak;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.practiceGoalsDailyMinutes,
    this.practiceGoalsWeeklyDays,
    this.practiceStreakCurrentStreak,
    this.practiceStreakLongestStreak,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      practiceGoalsDailyMinutes: json['practiceGoals_dailyMinutes'] as int?,
      practiceGoalsWeeklyDays: json['practiceGoals_weeklyDays'] as int?,
      practiceStreakCurrentStreak: json['practiceStreak_currentStreak'] as int?,
      practiceStreakLongestStreak: json['practiceStreak_longestStreak'] as int?,
    );
  }
}

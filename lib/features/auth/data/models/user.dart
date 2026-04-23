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
    final practiceGoals = json['practiceGoals'] as Map<String, dynamic>?;
    final practiceStreak = json['practiceStreak'] as Map<String, dynamic>?;

    return User(
      id: json['_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      practiceGoalsDailyMinutes: practiceGoals?['dailyMinutes'] as int?,
      practiceGoalsWeeklyDays: practiceGoals?['weeklyDays'] as int?,
      practiceStreakCurrentStreak: practiceStreak?['currentStreak'] as int?,
      practiceStreakLongestStreak: practiceStreak?['longestStreak'] as int?,
    );
  }
}

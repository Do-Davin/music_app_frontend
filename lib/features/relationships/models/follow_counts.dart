class FollowCounts {
  final int followers;
  final int following;

  const FollowCounts({this.followers = 0, this.following = 0});

  factory FollowCounts.fromJson(Map<String, dynamic> json) {
    return FollowCounts(
      followers: _parseCount(json['followers']),
      following: _parseCount(json['following']),
    );
  }

  static int _parseCount(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

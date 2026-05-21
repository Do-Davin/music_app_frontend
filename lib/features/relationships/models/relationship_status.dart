class RelationshipStatus {
  static const String personalProfileType = 'PERSONAL';
  static const String professionalProfileType = 'PROFESSIONAL';

  final String profileType;
  final bool isFriend;
  final bool hasIncomingFriendRequest;
  final bool hasOutgoingFriendRequest;
  final bool isFollowing;
  final bool canAddFriend;
  final bool canFollow;

  const RelationshipStatus({
    this.profileType = personalProfileType,
    this.isFriend = false,
    this.hasIncomingFriendRequest = false,
    this.hasOutgoingFriendRequest = false,
    this.isFollowing = false,
    this.canAddFriend = false,
    this.canFollow = false,
  });

  factory RelationshipStatus.fromJson(Map<String, dynamic> json) {
    return RelationshipStatus(
      profileType: _parseProfileType(json['profileType']),
      isFriend: _parseBool(json['isFriend']),
      hasIncomingFriendRequest: _parseBool(json['hasIncomingFriendRequest']),
      hasOutgoingFriendRequest: _parseBool(json['hasOutgoingFriendRequest']),
      isFollowing: _parseBool(json['isFollowing']),
      canAddFriend: _parseBool(json['canAddFriend']),
      canFollow: _parseBool(json['canFollow']),
    );
  }

  static bool _parseBool(Object? value) {
    return value is bool ? value : false;
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

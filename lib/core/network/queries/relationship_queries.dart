class RelationshipQueries {
  static const String myFollowing = '''
    query MyFollowing {
      myFollowing {
        _id
        username
        email
        profileType
        profileImageUrl
        profileImageThumbnailUrl
      }
    }
  ''';

  static const String myFollowers = '''
    query MyFollowers {
      myFollowers {
        _id
        username
        email
        profileType
        profileImageUrl
        profileImageThumbnailUrl
      }
    }
  ''';

  static const String followCounts = '''
    query FollowCounts(\$userId: ID!) {
      followCounts(userId: \$userId) {
        followers
        following
      }
    }
  ''';

  static const String relationshipStatus = '''
    query RelationshipStatus(\$userId: ID!) {
      relationshipStatus(userId: \$userId) {
        profileType
        isFriend
        hasIncomingFriendRequest
        hasOutgoingFriendRequest
        isFollowing
        canAddFriend
        canFollow
      }
    }
  ''';

  static const String followUser = '''
    mutation FollowUser(\$userId: ID!) {
      followUser(userId: \$userId)
    }
  ''';

  static const String unfollowUser = '''
    mutation UnfollowUser(\$userId: ID!) {
      unfollowUser(userId: \$userId)
    }
  ''';
}

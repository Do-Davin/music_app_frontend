class FriendQueries {
  static const String searchUsers = '''
    query SearchUsers(\$search: String!) {
      searchUsers(search: \$search) {
        _id
        username
        email
        profileType
        profileImageUrl
        profileImageThumbnailUrl
      }
    }
  ''';

  static const String myFriends = '''
    query MyFriends(\$limit: Int, \$offset: Int) {
      myFriends(limit: \$limit, offset: \$offset) {
        _id
        username
        email
        profileType
        profileImageUrl
        profileImageThumbnailUrl
      }
    }
  ''';

  static const String incomingFriendRequests = '''
    query IncomingFriendRequests(\$limit: Int, \$offset: Int) {
      incomingFriendRequests(limit: \$limit, offset: \$offset) {
        _id
        username
        email
        profileType
        profileImageUrl
        profileImageThumbnailUrl
      }
    }
  ''';

  static const String outgoingFriendRequests = '''
    query OutgoingFriendRequests(\$limit: Int, \$offset: Int) {
      outgoingFriendRequests(limit: \$limit, offset: \$offset) {
        _id
        username
        email
        profileType
        profileImageUrl
        profileImageThumbnailUrl
      }
    }
  ''';

  static const String sendFriendRequest = '''
    mutation SendFriendRequest(\$userId: ID!) {
      sendFriendRequest(userId: \$userId)
    }
  ''';

  static const String acceptFriendRequest = '''
    mutation AcceptFriendRequest(\$userId: ID!) {
      acceptFriendRequest(userId: \$userId)
    }
  ''';

  static const String rejectFriendRequest = '''
    mutation RejectFriendRequest(\$userId: ID!) {
      rejectFriendRequest(userId: \$userId)
    }
  ''';

  static const String cancelFriendRequest = '''
    mutation CancelFriendRequest(\$userId: ID!) {
      cancelFriendRequest(userId: \$userId)
    }
  ''';
}

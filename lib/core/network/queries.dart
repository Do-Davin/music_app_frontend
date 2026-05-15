class SongQueries {
  static const String getAllSongs = '''
    query GetAllSongs {
      songs {
        _id
        title
        artist
        albumName
        duration
        key
        tempo
        difficulty
        tags
        fileUrl
        videoUrl
        coverImageUrl
        lyrics
        chordNotationStyle
        isPublic
        playCount
      }
    }
  ''';

  static const String getSongById = '''
    query GetSongById(\$id: ID!) {
      song(id: \$id) {
        _id
        title
        artist
        albumName
        duration
        key
        tempo
        difficulty
        tags
        fileUrl
        videoUrl
        coverImageUrl
        lyrics
        chordNotationStyle
        isPublic
        playCount
      }
    }
  ''';
}

class PlaylistQueries {
  static const String getAllPlaylists = '''
    query GetAllPlaylists {
      playlists {
        _id
        name
        description
        coverImageUrl
        songIds
        isPublic
      }
    }
  ''';

  static const String getPlaylistById = '''
    query GetPlaylistById(\$id: ID!) {
      playlist(id: \$id) {
        _id
        name
        description
        coverImageUrl
        songIds
        isPublic
      }
    }
  ''';
}

class UserQueries {
  static const String getMe = '''
    query GetMe {
      me {
        _id
        username
        email
        profileImageUrl
        practiceGoals {
          dailyMinutes
          weeklyDays
        }
        practiceStreak {
          currentStreak
          longestStreak
        }
      }
    }
  ''';

  static const String searchUsers = '''
    query SearchUsersForUsername(\$search: String!) {
      searchUsers(search: \$search) {
        _id
        username
        email
        profileImageUrl
      }
    }
  ''';
}

class UserMutations {
  static const String updateUsername = '''
    mutation UpdateUsername(\$username: String!) {
      updateUsername(username: \$username) {
        _id
        username
        email
        profileImageUrl
        practiceGoals {
          dailyMinutes
          weeklyDays
        }
        practiceStreak {
          currentStreak
          longestStreak
        }
      }
    }
  ''';
}

class FriendQueries {
  static const String searchUsers = '''
    query SearchUsers(\$search: String!) {
      searchUsers(search: \$search) {
        _id
        username
        email
        profileImageUrl
      }
    }
  ''';

  static const String myFriends = '''
    query MyFriends(\$limit: Int, \$offset: Int) {
      myFriends(limit: \$limit, offset: \$offset) {
        _id
        username
        email
        profileImageUrl
      }
    }
  ''';

  static const String incomingFriendRequests = '''
    query IncomingFriendRequests(\$limit: Int, \$offset: Int) {
      incomingFriendRequests(limit: \$limit, offset: \$offset) {
        _id
        username
        email
        profileImageUrl
      }
    }
  ''';

  static const String outgoingFriendRequests = '''
    query OutgoingFriendRequests(\$limit: Int, \$offset: Int) {
      outgoingFriendRequests(limit: \$limit, offset: \$offset) {
        _id
        username
        email
        profileImageUrl
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
}

class AuthMutations {
  static const String login = '''
    mutation Login(\$input: LoginInput!) {
      login(input: \$input) {
        accessToken
        refreshToken
        user {
          _id
          username
          email
          profileImageUrl
          practiceGoals {
            dailyMinutes
            weeklyDays
          }
          practiceStreak {
            currentStreak
            longestStreak
          }
        }
      }
    }
  ''';

  static const String register = '''
    mutation Register(\$input: RegisterInput!) {
      register(input: \$input) {
        accessToken
        refreshToken
        user {
          _id
          username
          email
          profileImageUrl
          practiceGoals {
            dailyMinutes
            weeklyDays
          }
          practiceStreak {
            currentStreak
            longestStreak
          }
        }
      }
    }
  ''';

  static const String sendResetCode = '''
    mutation SendResetCode(\$input: SendResetCodeInput!) {
      sendResetCode(input: \$input) {
        message
        email
      }
    }
  ''';

  static const String verifyCode = '''
    mutation VerifyCode(\$input: VerifyCodeInput!) {
      verifyCode(input: \$input) {
        valid
        message
      }
    }
  ''';

  static const String resetPassword = '''
    mutation ResetPassword(\$input: ResetPasswordInput!) {
      resetPassword(input: \$input) {
        success
        message
      }
    }
  ''';
}

class UserQueries {
  static const String getMe = '''
    query GetMe {
      me {
        _id
        username
        email
        profileType
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

  static const String likedSongs = '''
    query GetLikedSongs {
      likedSongs {
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

  static const String searchUsers = '''
    query SearchUsersForUsername(\$search: String!) {
      searchUsers(search: \$search) {
        _id
        username
        email
        profileType
        profileImageUrl
      }
    }
  ''';
}

class UserMutations {
  static const String updateUsername = '''
    mutation UpdateUsername(\$newUsername: String!) {
      updateUsername(newUsername: \$newUsername) {
        _id
        username
        email
        profileType
        profileImageUrl
      }
    }
  ''';

  static const String toggleLikeSong = '''
    mutation ToggleLikeSong(\$songId: ID!) {
      toggleLikeSong(songId: \$songId)
    }
  ''';
}

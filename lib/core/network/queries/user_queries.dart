class UserQueries {
  static const String getMe = '''
    query GetMe {
      me {
        _id
        username
        email
        profileType
        profileImageUrl
        profileImageThumbnailUrl
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
        source
        sourcePath
        fileUrl
        videoUrl
        coverImageUrl
        lyrics
        chordNotationStyle
        isPublic
        playCount
        userId
      }
    }
  ''';

  static const String recentlyPlayed = r'''
    query GetRecentlyPlayed($limit: Int) {
      recentlyPlayed(limit: $limit) {
        playedAt
        song {
          _id
          title
          artist
          albumName
          source
          sourcePath
          fileUrl
          videoUrl
          coverImageUrl
          isPublic
          playCount
          userId
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
        profileType
        profileImageUrl
        profileImageThumbnailUrl
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
        profileImageThumbnailUrl
      }
    }
  ''';

  static const String switchToProfessionalAccount = '''
    mutation SwitchToProfessionalAccount {
      switchToProfessionalAccount {
        _id
        username
        email
        profileType
        profileImageUrl
        profileImageThumbnailUrl
      }
    }
  ''';

  static const String toggleLikeSong = '''
    mutation ToggleLikeSong(\$songId: ID!) {
      toggleLikeSong(songId: \$songId)
    }
  ''';

  static const String addRecentlyPlayed = r'''
    mutation AddRecentlyPlayed($songId: ID!) {
      addRecentlyPlayed(songId: $songId)
    }
  ''';
}

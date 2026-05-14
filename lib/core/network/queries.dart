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

  static const String likedSongsPlaylist = '''
    query LikedSongsPlaylist {
      likedSongsPlaylist {
        _id
        name
        description
        coverImageUrl
        songIds
        isPublic
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

  static const String likedSongs = '''
    query LikedSongs {
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
}

class UserMutations {
  static const String toggleLikeSong = '''
    mutation ToggleLikeSong(\$songId: ID!) {
      toggleLikeSong(songId: \$songId) {
        _id
      }
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

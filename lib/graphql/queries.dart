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
        practiceGoals_dailyMinutes
        practiceGoals_weeklyDays
        practiceStreak_currentStreak
        practiceStreak_longestStreak
      }
    }
  ''';
}

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
        source
        sourcePath
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
        source
        sourcePath
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

  static const String searchSongs = '''
    query SearchSongs(\$query: String!) {
      searchSongs(query: \$query) {
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
      }
    }
  ''';

  static const String isSongFavorite = '''
    query IsSongFavorite(\$songId: ID!) {
      isSongFavorite(songId: \$songId)
    }
  ''';

  static const String toggleFavoriteSong = '''
    mutation ToggleFavoriteSong(\$songId: ID!) {
      toggleFavoriteSong(songId: \$songId) {
        isFavorite
      }
    }
  ''';

  static const String getMyFavoriteSongs = '''
    query GetMyFavoriteSongs {
      myFavoriteSongs {
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
      }
    }
  ''';
}

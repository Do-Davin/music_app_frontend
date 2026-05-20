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
}

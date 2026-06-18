class SongQueries {
  static const String getAllSongs = r'''
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
        userId
      }
    }
  ''';

  static const String getSongById = r'''
    query GetSongById($id: ID!) {
      song(id: $id) {
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

  static const String searchSongs = r'''
    query SearchSongs($query: String!) {
      searchSongs(query: $query) {
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

  static const String createSong = r'''
    mutation CreateSong($input: CreateSongInput!) {
      createSong(createSongInput: $input) {
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

  static const String updateSong = r'''
    mutation UpdateSong($input: UpdateSongInput!) {
      updateSong(updateSongInput: $input) {
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

  static const String removeSong = r'''
    mutation RemoveSong($id: ID!) {
      removeSong(id: $id)
    }
  ''';

  static const String getMySongs = r'''
    query GetMySongs {
      mySongs {
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
}

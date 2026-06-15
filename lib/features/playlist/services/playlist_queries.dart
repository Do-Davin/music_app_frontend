class PlaylistQueries {
  static const String getPlaylists = r'''
    query GetPlaylists {
      playlists {
        _id
        userId
        name
        description
        coverImageUrl
        isPublic
        songIds
        createdAt
      }
    }
  ''';

  static const String getMyPlaylists = r'''
    query GetMyPlaylists {
      myPlaylists {
        _id
        userId
        name
        description
        coverImageUrl
        isPublic
        songIds
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
        createdAt
        updatedAt
      }
    }
  ''';

  static const String getPlaylistById = r'''
    query GetPlaylistById($id: ID!) {
      playlist(id: $id) {
        _id
        userId
        name
        description
        coverImageUrl
        isPublic
        songIds
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
        createdAt
        updatedAt
      }
    }
  ''';

  static const String createPlaylist = r'''
    mutation CreatePlaylist($input: CreatePlaylistInput!) {
      createPlaylist(createPlaylistInput: $input) {
        _id
        userId
        name
        description
        coverImageUrl
        isPublic
        songIds
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
        createdAt
        updatedAt
      }
    }
  ''';

  static const String updatePlaylist = r'''
    mutation UpdatePlaylist($input: UpdatePlaylistInput!) {
      updatePlaylist(updatePlaylistInput: $input) {
        _id
        userId
        name
        description
        coverImageUrl
        isPublic
        songIds
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
        createdAt
        updatedAt
      }
    }
  ''';

  static const String removePlaylist = r'''
    mutation RemovePlaylist($id: ID!) {
      removePlaylist(id: $id)
    }
  ''';

  static const String addSongToPlaylist = r'''
    mutation AddSongToPlaylist($playlistId: ID!, $songId: ID!) {
      addSongToPlaylist(playlistId: $playlistId, songId: $songId) {
        _id
        userId
        name
        description
        coverImageUrl
        isPublic
        songIds
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
        createdAt
        updatedAt
      }
    }
  ''';

  static const String removeSongFromPlaylist = r'''
    mutation RemoveSongFromPlaylist($playlistId: ID!, $songId: ID!) {
      removeSongFromPlaylist(playlistId: $playlistId, songId: $songId) {
        _id
        userId
        name
        description
        coverImageUrl
        isPublic
        songIds
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
        createdAt
        updatedAt
      }
    }
  ''';

  static const String moveSongBetweenPlaylists = r'''
    mutation MoveSongBetweenPlaylists($fromPlaylistId: ID!, $toPlaylistId: ID!, $songId: ID!) {
      moveSongBetweenPlaylists(fromPlaylistId: $fromPlaylistId, toPlaylistId: $toPlaylistId, songId: $songId) {
        _id
        userId
        name
        description
        coverImageUrl
        isPublic
        songIds
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
        createdAt
        updatedAt
      }
    }
  ''';
}

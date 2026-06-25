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
        isKaraoke
        songIds
        savedUserIds
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
        isKaraoke
        songIds
        savedUserIds
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
        isKaraoke
        songIds
        savedUserIds
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
        isKaraoke
        songIds
        savedUserIds
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
        isKaraoke
        songIds
        savedUserIds
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
        isKaraoke
        songIds
        savedUserIds
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
        isKaraoke
        songIds
        savedUserIds
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
        isKaraoke
        songIds
        savedUserIds
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

  static const String isSongInLikedSongs = r'''
    query IsSongInLikedSongs($songId: ID!) {
      isSongInLikedSongs(songId: $songId)
    }
  ''';

  static const String toggleSongInLikedSongs = r'''
    mutation ToggleLikeSong($songId: ID!) {
      toggleLikeSong(songId: $songId)
    }
  ''';

  static const String getLikedSongsPlaylist = r'''
    query GetLikedSongsPlaylist {
      likedSongsPlaylist {
        _id
        userId
        name
        description
        coverImageUrl
        isPublic
        isKaraoke
        songIds
        songs {
          _id
          title
          artist
          albumName
          coverImageUrl
          duration
          source
          sourcePath
          fileUrl
          videoUrl
          difficulty
          key
          tempo
          tags
        }
        createdAt
        updatedAt
      }
    }
  ''';

  static const String searchPlaylists = r'''
    query SearchPlaylists($query: String!) {
      searchPlaylists(query: $query) {
        _id
        userId
        name
        description
        coverImageUrl
        isPublic
        isKaraoke
        songIds
        savedUserIds
        createdAt
        updatedAt
      }
    }
  ''';

  static const String savePlaylistToLibrary = r'''
    mutation SavePlaylistToLibrary($playlistId: ID!) {
      savePlaylistToLibrary(playlistId: $playlistId) {
        _id
        userId
        name
        description
        coverImageUrl
        isPublic
        isKaraoke
        songIds
        savedUserIds
        createdAt
        updatedAt
      }
    }
  ''';

  static const String removePlaylistFromLibrary = r'''
    mutation RemovePlaylistFromLibrary($playlistId: ID!) {
      removePlaylistFromLibrary(playlistId: $playlistId) {
        _id
        userId
        name
        description
        coverImageUrl
        isPublic
        isKaraoke
        songIds
        savedUserIds
        createdAt
        updatedAt
      }
    }
  ''';
}

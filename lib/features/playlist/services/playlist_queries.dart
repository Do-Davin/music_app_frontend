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
          coverImageUrl
          duration
          source
          sourcePath
          fileUrl
          videoUrl
          lyrics
        }
        createdAt
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
          lyrics
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
        name
        userId
        description
        isPublic
        songIds
      }
    }
  ''';

  static const String updatePlaylist = r'''
    mutation UpdatePlaylist($input: UpdatePlaylistInput!) {
      updatePlaylist(updatePlaylistInput: $input) {
        _id
        name
        description
        coverImageUrl
        isPublic
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
        songIds
        songs {
          _id
          title
          artist
          coverImageUrl
          duration
          source
          sourcePath
          fileUrl
          videoUrl
          lyrics
        }
      }
    }
  ''';

  static const String removeSongFromPlaylist = r'''
    mutation RemoveSongFromPlaylist($playlistId: ID!, $songId: ID!) {
      removeSongFromPlaylist(playlistId: $playlistId, songId: $songId) {
        _id
        songIds
      }
    }
  ''';

  static const String isSongInLikedSongs = r'''
    query IsSongInLikedSongs($songId: ID!) {
      isSongInLikedSongs(songId: $songId)
    }
  ''';

  static const String toggleSongInLikedSongs = r'''
    mutation ToggleSongInLikedSongs($songId: ID!) {
      toggleSongInLikedSongs(songId: $songId) {
        isLiked
      }
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
}

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
    query GetLikedSongsPlaylist {
      likedSongsPlaylist {
        _id
        userId
        name
        description
        coverImageUrl
        songIds
        isPublic
        createdAt
        updatedAt
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

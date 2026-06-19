// NOTE: The authoritative playlist queries (getMyPlaylists, createPlaylist,
// addSongToPlaylist, etc.) live in
// features/playlist/services/playlist_queries.dart and are used directly by
// PlaylistService. This file only contains the queries used by other parts of
// the app (liked-songs playlist, public playlist browsing).

class PlaylistQueries {
  // Full song fields reused across queries
  static const String _songFields = '''
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
  ''';

  static const String getAllPlaylists = '''
    query GetAllPlaylists {
      playlists {
        _id
        userId
        name
        description
        coverImageUrl
        songIds
        isPublic
        createdAt
        updatedAt
      }
    }
  ''';

  static const String getPlaylistById =
      '''
    query GetPlaylistById(\$id: ID!) {
      playlist(id: \$id) {
        _id
        userId
        name
        description
        coverImageUrl
        isPublic
        songIds
        songs {
          $_songFields
        }
        createdAt
        updatedAt
      }
    }
  ''';

  static const String likedSongsPlaylist =
      '''
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
          $_songFields
        }
      }
    }
  ''';
}

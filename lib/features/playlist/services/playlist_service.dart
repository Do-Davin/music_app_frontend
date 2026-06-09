import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../core/network/graphql_config.dart';
import '../../../core/network/graphql_error_parser.dart';
import '../models/playlist.dart';
import 'playlist_queries.dart';

class PlaylistService {
  // Build the client lazily so it always reads the latest token from storage.
  GraphQLClient get _client => GraphQLConfig.clientToQuery(authenticated: true);

  Future<List<Playlist>> getMyPlaylists() async {
    try {
      debugPrint('PlaylistService: Fetching my playlists...');
      final QueryOptions options = QueryOptions(
        document: gql(PlaylistQueries.getMyPlaylists),
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _client.query(options);

      if (result.hasException) {
        final error = parseGraphQlException(result.exception!);
        debugPrint('PlaylistService: Error fetching playlists: $error');
        throw Exception(error);
      }

      final List data = result.data?['myPlaylists'] ?? [];
      debugPrint('PlaylistService: Found ${data.length} playlists');
      return data.map((json) => Playlist.fromJson(json)).toList();
    } catch (e) {
      debugPrint('PlaylistService: Exception in getMyPlaylists: $e');
      rethrow;
    }
  }

  Future<Playlist> getPlaylistById(String id) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(PlaylistQueries.getPlaylistById),
        variables: {'id': id},
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _client.query(options);

      if (result.hasException) {
        throw Exception(parseGraphQlException(result.exception!));
      }

      final data = result.data?['playlist'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Playlist not found');
      final playlist = Playlist.fromJson(data);
      debugPrint(
        'PlaylistService: getPlaylistById(${playlist.name}) returned '
        '${playlist.songIds?.length} songIds and ${playlist.songs?.length} songs',
      );
      return playlist;
    } catch (e) {
      rethrow;
    }
  }

  Future<Playlist> createPlaylist(String name, {String? description}) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PlaylistQueries.createPlaylist),
        variables: {
          'input': {'name': name, 'description': description},
        },
      );

      final QueryResult result = await _client.mutate(options);

      if (result.hasException) {
        throw Exception(parseGraphQlException(result.exception!));
      }

      final data = result.data?['createPlaylist'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Failed to create playlist');
      return Playlist.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Playlist> addSongToPlaylist(String playlistId, String songId) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PlaylistQueries.addSongToPlaylist),
        variables: {'playlistId': playlistId, 'songId': songId},
      );

      final QueryResult result = await _client.mutate(options);

      if (result.hasException) {
        throw Exception(parseGraphQlException(result.exception!));
      }

      final data = result.data?['addSongToPlaylist'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Failed to add song to playlist');
      final playlist = Playlist.fromJson(data);
      debugPrint(
        'PlaylistService: addSongToPlaylist returned ${playlist.name} '
        'with ${playlist.songIds?.length} songIds and ${playlist.songs?.length} songs',
      );
      return playlist;
    } catch (e) {
      rethrow;
    }
  }

  Future<Playlist> removeSongFromPlaylist(
    String playlistId,
    String songId,
  ) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PlaylistQueries.removeSongFromPlaylist),
        variables: {'playlistId': playlistId, 'songId': songId},
      );

      final QueryResult result = await _client.mutate(options);

      if (result.hasException) {
        throw Exception(parseGraphQlException(result.exception!));
      }

      final data =
          result.data?['removeSongFromPlaylist'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Failed to remove song from playlist');
      return Playlist.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Playlist> moveSongBetweenPlaylists({
    required String fromPlaylistId,
    required String toPlaylistId,
    required String songId,
  }) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PlaylistQueries.moveSongBetweenPlaylists),
        variables: {
          'fromPlaylistId': fromPlaylistId,
          'toPlaylistId': toPlaylistId,
          'songId': songId,
        },
      );

      final QueryResult result = await _client.mutate(options);

      if (result.hasException) {
        throw Exception(parseGraphQlException(result.exception!));
      }

      final data =
          result.data?['moveSongBetweenPlaylists'] as Map<String, dynamic>?;
      if (data == null)
        throw Exception('Failed to move song between playlists');
      return Playlist.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> removePlaylist(String id) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PlaylistQueries.removePlaylist),
        variables: {'id': id},
      );

      final QueryResult result = await _client.mutate(options);

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      return result.data?['removePlaylist'] ?? false;
    } catch (e) {
      rethrow;
    }
  }

  // ── Liked Songs methods ────────────────────────────────────────────────────
  // These were removed from the dev branch but are still required by
  // playlist_provider.dart, liked_songs_screen.dart, and favorite_icon_button.dart.

  Future<Playlist> getLikedSongsPlaylist() async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(PlaylistQueries.getLikedSongsPlaylist),
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _client.query(options);

      if (result.hasException) {
        throw Exception(parseGraphQlException(result.exception!));
      }

      final data = result.data?['likedSongsPlaylist'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Liked songs playlist not found');
      return Playlist.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isSongInLikedSongs(String songId) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(PlaylistQueries.isSongInLikedSongs),
        variables: {'songId': songId},
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _client.query(options);

      if (result.hasException) {
        throw Exception(parseGraphQlException(result.exception!));
      }

      return result.data?['isSongInLikedSongs'] as bool? ?? false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> toggleSongInLikedSongs(String songId) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PlaylistQueries.toggleSongInLikedSongs),
        variables: {'songId': songId},
      );

      final QueryResult result = await _client.mutate(options);

      if (result.hasException) {
        throw Exception(parseGraphQlException(result.exception!));
      }

      return result.data?['toggleSongInLikedSongs']['isLiked'] as bool? ??
          false;
    } catch (e) {
      rethrow;
    }
  }
}

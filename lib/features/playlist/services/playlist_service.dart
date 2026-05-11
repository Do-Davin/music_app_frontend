import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../core/network/graphql_config.dart';
import '../models/playlist.dart';
import 'playlist_queries.dart';

class PlaylistService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery(authenticated: true);

  Future<List<Playlist>> getMyPlaylists() async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(PlaylistQueries.getMyPlaylists),
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _client.query(options);

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final List data = result.data?['myPlaylists'] ?? [];
      return data.map((json) => Playlist.fromJson(json)).toList();
    } catch (e) {
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
        throw Exception(result.exception.toString());
      }

      final Map<String, dynamic> data = result.data?['playlist'];
      return Playlist.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Playlist> createPlaylist(String name, {String? description}) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PlaylistQueries.createPlaylist),
        variables: {
          'input': {
            'name': name,
            'description': description,
          }
        },
      );

      final QueryResult result = await _client.mutate(options);

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final Map<String, dynamic> data = result.data?['createPlaylist'];
      return Playlist.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Playlist> addSongToPlaylist(String playlistId, String songId) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PlaylistQueries.addSongToPlaylist),
        variables: {
          'playlistId': playlistId,
          'songId': songId,
        },
      );

      final QueryResult result = await _client.mutate(options);

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final Map<String, dynamic> data = result.data?['addSongToPlaylist'];
      return Playlist.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Playlist> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PlaylistQueries.removeSongFromPlaylist),
        variables: {
          'playlistId': playlistId,
          'songId': songId,
        },
      );

      final QueryResult result = await _client.mutate(options);

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final Map<String, dynamic> data = result.data?['removeSongFromPlaylist'];
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
}

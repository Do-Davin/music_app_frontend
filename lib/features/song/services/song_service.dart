import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/core/network/graphql_error_parser.dart';
import 'package:music_app_frontend/core/network/queries/index.dart';
import 'package:music_app_frontend/features/song/models/song.dart';

class SongService {
  GraphQLClient get _client => GraphQLConfig.clientToQuery();
  GraphQLClient get _authClient => GraphQLConfig.clientToQuery(authenticated: true);

  Future<List<Song>> fetchSongs() async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(SongQueries.getAllSongs),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw Exception(parseGraphQlException(result.exception!));
      }

      final List<dynamic> data = result.data?['songs'] ?? [];
      return data.map((json) => Song.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Song> fetchSongById(String id) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(SongQueries.getSongById),
          variables: {'id': id},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw Exception(parseGraphQlException(result.exception!));
      }

      final data = result.data?['song'];
      if (data == null) throw Exception('Song not found');
      return Song.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Song>> searchSongs(String query) async {
    try {
      if (query.isEmpty) return [];
      final result = await _client.query(
        QueryOptions(
          document: gql(SongQueries.searchSongs),
          variables: {'query': query},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        throw Exception(parseGraphQlException(result.exception!));
      }

      final List<dynamic> data = result.data?['searchSongs'] ?? [];
      return data.map((json) => Song.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Song> createSong({
    required String title,
    required String artist,
    required String source,
    required String sourcePath,
    String? lyrics,
    bool isPublic = false,
  }) async {
    try {
      final result = await _authClient.mutate(
        MutationOptions(
          document: gql(SongQueries.createSong),
          variables: {
            'input': {
              'title': title,
              'artist': artist,
              'source': source,
              'sourcePath': sourcePath,
              'lyrics': lyrics,
              'isPublic': isPublic,
            }
          },
        ),
      );

      if (result.hasException) {
        throw Exception(parseGraphQlException(result.exception!));
      }

      final data = result.data?['createSong'];
      if (data == null) throw Exception('Failed to create song');
      return Song.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Song> updateSongLyrics({
    required String songId,
    required String lyrics,
  }) async {
    try {
      final result = await _authClient.mutate(
        MutationOptions(
          document: gql(SongQueries.updateSong),
          variables: {
            'input': {
              'id': songId,
              'lyrics': lyrics,
            }
          },
        ),
      );

      if (result.hasException) {
        throw Exception(parseGraphQlException(result.exception!));
      }

      final data = result.data?['updateSong'];
      if (data == null) throw Exception('Failed to update song');
      return Song.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }
}

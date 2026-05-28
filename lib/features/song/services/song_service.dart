import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/core/network/queries/index.dart';
import 'package:music_app_frontend/features/song/models/song.dart';

class SongService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery();

  Future<List<Song>> fetchSongs() async {
    final result = await _client.query(
      QueryOptions(document: gql(SongQueries.getAllSongs)),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final List<dynamic> data = result.data?['songs'] ?? [];
    return data.map((json) => Song.fromJson(json)).toList();
  }

  Future<Song> fetchSongById(String id) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(SongQueries.getSongById),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return Song.fromJson(result.data!['song']);
  }

  Future<List<Song>> searchSongs(String query) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(SongQueries.searchSongs),
        variables: {'query': query},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final List<dynamic> data = result.data?['searchSongs'] ?? [];
    return data.map((json) => Song.fromJson(json)).toList();
  }

  Future<Song> createSong({
    required String title,
    required String artist,
    required String source, // 'mp3' or 'youtube'
    required String sourcePath,
    String? lyrics,
  }) async {
    final authenticatedClient = GraphQLConfig.clientToQuery(authenticated: true);
    final result = await authenticatedClient.mutate(
      MutationOptions(
        document: gql(r'''
          mutation CreateSong($input: CreateSongInput!) {
            createSong(createSongInput: $input) {
              _id
              title
              artist
              source
              sourcePath
              lyrics
            }
          }
        '''),
        variables: {
          'input': {
            'title': title,
            'artist': artist,
            'source': source,
            'sourcePath': sourcePath,
            'lyrics': lyrics,
          }
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return Song.fromJson(result.data!['createSong']);
  }

  Future<Song> updateSongLyrics({
    required String songId,
    required String lyrics,
  }) async {
    final authenticatedClient = GraphQLConfig.clientToQuery(authenticated: true);
    final result = await authenticatedClient.mutate(
      MutationOptions(
        document: gql(r'''
          mutation UpdateSongLyrics($input: UpdateSongInput!) {
            updateSong(updateSongInput: $input) {
              _id
              title
              artist
              source
              sourcePath
              fileUrl
              videoUrl
              coverImageUrl
              lyrics
            }
          }
        '''),
        variables: {
          'input': {
            'id': songId,
            'lyrics': lyrics,
          }
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return Song.fromJson(result.data!['updateSong']);
  }
}

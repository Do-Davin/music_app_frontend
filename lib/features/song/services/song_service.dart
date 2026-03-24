import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/core/network/queries.dart';
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
}

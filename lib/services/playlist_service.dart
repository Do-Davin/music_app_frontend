import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/config/graphql_config.dart';
import 'package:music_app_frontend/graphql/queries.dart';
import 'package:music_app_frontend/models/playlist.dart';

class PlaylistService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery();

  Future<List<Playlist>> fetchPlaylists() async {
    final result = await _client.query(
      QueryOptions(document: gql(PlaylistQueries.getAllPlaylists)),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final List<dynamic> data = result.data?['playlists'] ?? [];
    return data.map((json) => Playlist.fromJson(json)).toList();
  }

  Future<Playlist> fetchPlaylistById(String id) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(PlaylistQueries.getPlaylistById),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return Playlist.fromJson(result.data!['playlist']);
  }
}

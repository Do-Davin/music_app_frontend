import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/core/network/queries.dart';
import 'package:music_app_frontend/features/song/models/song.dart';

class LikedSongsService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery(authenticated: true);

  Future<List<Song>> fetchLikedSongs() async {
    final result = await _client.query(
      QueryOptions(
        document: gql(UserQueries.likedSongs),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final List<dynamic> data = result.data?['likedSongs'] ?? [];
    return data.map((json) => Song.fromJson(json)).toList();
  }

  Future<void> toggleLikeSong(String songId) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(UserMutations.toggleLikeSong),
        variables: {'songId': songId},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
  }
}


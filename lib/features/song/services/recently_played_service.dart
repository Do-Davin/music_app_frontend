import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/core/network/graphql_error_parser.dart';
import 'package:music_app_frontend/core/network/queries/index.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/providers/recently_played_provider.dart';

class RecentlyPlayedService {
  GraphQLClient get _client => GraphQLConfig.clientToQuery(authenticated: true);

  Future<List<RecentlyPlayedEntry>> fetchRecentlyPlayed({
    int limit = 20,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(UserQueries.recentlyPlayed),
        variables: {'limit': limit},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    final List<dynamic> data = result.data?['recentlyPlayed'] ?? [];
    return data.map((entry) {
      final songData = entry['song'] as Map<String, dynamic>;
      final playedAtRaw = entry['playedAt']?.toString() ?? '';
      return RecentlyPlayedEntry(
        song: Song.fromJson(songData),
        playedAt: DateTime.tryParse(playedAtRaw) ?? DateTime.now(),
      );
    }).toList();
  }

  Future<void> addRecentlyPlayed(String songId) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(UserMutations.addRecentlyPlayed),
        variables: {'songId': songId},
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }
  }
}

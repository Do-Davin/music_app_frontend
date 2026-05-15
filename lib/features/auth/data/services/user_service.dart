import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/core/network/graphql_error_parser.dart';
import 'package:music_app_frontend/core/network/queries.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';

class UserService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery(
    authenticated: true,
  );

  Future<User> fetchMe() async {
    final result = await _client.query(
      QueryOptions(document: gql(UserQueries.getMe)),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    return User.fromJson(result.data!['me'] as Map<String, dynamic>);
  }

  Future<bool> isUsernameAvailable({
    required String username,
    required String currentUserId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(UserQueries.searchUsers),
        variables: {'search': username},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    final users = result.data?['searchUsers'] as List<dynamic>? ?? [];
    final normalizedUsername = username.trim().toLowerCase();

    return users.every((json) {
      final user = User.fromJson(json as Map<String, dynamic>);
      final isSameUsername =
          user.username.trim().toLowerCase() == normalizedUsername;
      return !isSameUsername || user.id == currentUserId;
    });
  }

  Future<User> updateUsername(String username) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(UserMutations.updateUsername),
        variables: {'username': username},
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    return User.fromJson(
      result.data!['updateUsername'] as Map<String, dynamic>,
    );
  }
}

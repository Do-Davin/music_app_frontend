import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/config/graphql_config.dart';
import 'package:music_app_frontend/core/network/queries.dart';
import 'package:music_app_frontend/features/auth/domain/user.dart';

class UserService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery();

  Future<User> fetchMe() async {
    final result = await _client.query(
      QueryOptions(document: gql(UserQueries.getMe)),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return User.fromJson(result.data!['me']);
  }
}

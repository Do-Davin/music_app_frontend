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
}

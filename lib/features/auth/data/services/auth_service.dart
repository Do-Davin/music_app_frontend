import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/core/network/graphql_error_parser.dart';
import 'package:music_app_frontend/core/network/queries/index.dart';
import 'package:music_app_frontend/features/auth/data/models/auth_session.dart';

class AuthService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery();

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(AuthMutations.login),
        variables: {
          'input': {'email': email, 'password': password},
        },
        // Never read from or write to cache for auth mutations — a stale
        // cached result from a previous attempt would cause login to silently
        // succeed or fail without hitting the server.
        fetchPolicy: FetchPolicy.noCache,
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    return AuthSession.fromJson(result.data!['login'] as Map<String, dynamic>);
  }

  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(AuthMutations.register),
        variables: {
          'input': {'username': username, 'email': email, 'password': password},
        },
        // Never read from or write to cache for auth mutations.
        fetchPolicy: FetchPolicy.noCache,
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    return AuthSession.fromJson(
      result.data!['register'] as Map<String, dynamic>,
    );
  }
}

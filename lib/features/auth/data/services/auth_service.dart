import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/config/graphql_config.dart';
import 'package:music_app_frontend/core/network/mutations.dart';
import 'package:music_app_frontend/core/network/queries.dart';
import 'package:music_app_frontend/features/auth/domain/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

  GraphQLClient get _client => GraphQLConfig.clientToQuery();

  /// Create a client with authentication header
  GraphQLClient _getAuthClient(String token) {
    final HttpLink httpLink = HttpLink(GraphQLConfig.httpEndpoint);

    final AuthLink authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );

    final Link link = authLink.concat(httpLink);

    return GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    // ── DEVELOPMENT BYPASS (Remove before production) ────────────────────────
    if (email == 'test@example.com' && password == 'password123') {
      final fakeToken = 'dev_bypass_token_12345';
      final fakeUser = User(
        id: 'dev-1',
        username: 'TestUser',
        email: email,
        profileImageUrl: 'https://via.placeholder.com/150',
      );

      await saveToken(fakeToken);

      return {
        'token': fakeToken,
        'user': fakeUser,
      };
    }
    // ────────────────────────────────────────────────────────────────────────

    final result = await _client.mutate(
      MutationOptions(
        document: gql(AuthMutations.login),
        variables: {
          'email': email,
          'password': password,
        },
      ),
    );

    if (result.hasException) {
      throw Exception(_handleError(result.exception!));
    }

    final data = result.data!['login'];
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);

    await saveToken(token);

    return {
      'token': token,
      'user': user,
    };
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(AuthMutations.register),
        variables: {
          'email': email,
          'password': password,
        },
      ),
    );

    if (result.hasException) {
      throw Exception(_handleError(result.exception!));
    }

    final data = result.data!['register'];
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);

    await saveToken(token);

    return {
      'token': token,
      'user': user,
    };
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<User?> getMe(String token) async {
    // ── DEVELOPMENT BYPASS ──────────────────────────────────────────────────
    if (token == 'dev_bypass_token_12345') {
      return User(
        id: 'dev-1',
        username: 'TestUser',
        email: 'test@example.com',
        profileImageUrl: 'https://via.placeholder.com/150',
      );
    }
    // ────────────────────────────────────────────────────────────────────────

    final authClient = _getAuthClient(token);
    
    final result = await authClient.query(
      QueryOptions(
        document: gql(UserQueries.getMe),
        fetchPolicy: FetchPolicy.noCache,
      ),
    );

    if (result.hasException) {
      return null;
    }

    if (result.data?['me'] == null) {
      return null;
    }

    return User.fromJson(result.data!['me'] as Map<String, dynamic>);
  }

  String _handleError(OperationException exception) {
    if (exception.graphqlErrors.isNotEmpty) {
      return exception.graphqlErrors.first.message;
    }
    if (exception.linkException != null) {
      return 'Network error. Please check your connection.';
    }
    return 'An unexpected error occurred.';
  }
}

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/core/network/graphql_error_parser.dart';
import 'package:music_app_frontend/core/network/queries/index.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';

class FriendService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery(
    authenticated: true,
  );

  Future<List<User>> searchUsers(String search) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FriendQueries.searchUsers),
        variables: {'search': search},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    final data = result.data?['searchUsers'] as List<dynamic>? ?? [];
    return data
        .map((json) => User.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<User>> fetchMyFriends({int limit = 20, int offset = 0}) {
    return _fetchUserList(
      query: FriendQueries.myFriends,
      rootKey: 'myFriends',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<User>> fetchIncomingRequests({int limit = 20, int offset = 0}) {
    return _fetchUserList(
      query: FriendQueries.incomingFriendRequests,
      rootKey: 'incomingFriendRequests',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<User>> fetchOutgoingRequests({int limit = 20, int offset = 0}) {
    return _fetchUserList(
      query: FriendQueries.outgoingFriendRequests,
      rootKey: 'outgoingFriendRequests',
      limit: limit,
      offset: offset,
    );
  }

  Future<bool> sendFriendRequest(String userId) {
    return _runAction(
      mutation: FriendQueries.sendFriendRequest,
      rootKey: 'sendFriendRequest',
      userId: userId,
    );
  }

  Future<bool> acceptFriendRequest(String userId) {
    return _runAction(
      mutation: FriendQueries.acceptFriendRequest,
      rootKey: 'acceptFriendRequest',
      userId: userId,
    );
  }

  Future<bool> rejectFriendRequest(String userId) {
    return _runAction(
      mutation: FriendQueries.rejectFriendRequest,
      rootKey: 'rejectFriendRequest',
      userId: userId,
    );
  }

  Future<bool> cancelFriendRequest(String userId) {
    return _runAction(
      mutation: FriendQueries.cancelFriendRequest,
      rootKey: 'cancelFriendRequest',
      userId: userId,
    );
  }

  Future<List<User>> _fetchUserList({
    required String query,
    required String rootKey,
    required int limit,
    required int offset,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(query),
        variables: {'limit': limit, 'offset': offset},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    final data = result.data?[rootKey] as List<dynamic>? ?? [];
    return data
        .map((json) => User.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<bool> _runAction({
    required String mutation,
    required String rootKey,
    required String userId,
  }) async {
    final result = await _client.mutate(
      MutationOptions(document: gql(mutation), variables: {'userId': userId}),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    return result.data?[rootKey] as bool? ?? false;
  }
}

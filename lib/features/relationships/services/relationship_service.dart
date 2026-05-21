import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/core/network/graphql_error_parser.dart';
import 'package:music_app_frontend/core/network/queries/index.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/relationships/models/follow_counts.dart';
import 'package:music_app_frontend/features/relationships/models/relationship_status.dart';

class RelationshipService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery(
    authenticated: true,
  );

  Future<bool> followUser(String userId) {
    return _runAction(
      mutation: RelationshipQueries.followUser,
      rootKey: 'followUser',
      userId: userId,
    );
  }

  Future<bool> unfollowUser(String userId) {
    return _runAction(
      mutation: RelationshipQueries.unfollowUser,
      rootKey: 'unfollowUser',
      userId: userId,
    );
  }

  Future<List<User>> getMyFollowing() {
    return _fetchUserList(
      query: RelationshipQueries.myFollowing,
      rootKey: 'myFollowing',
    );
  }

  Future<List<User>> getMyFollowers() {
    return _fetchUserList(
      query: RelationshipQueries.myFollowers,
      rootKey: 'myFollowers',
    );
  }

  Future<FollowCounts> getFollowCounts(String userId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(RelationshipQueries.followCounts),
        variables: {'userId': userId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    return FollowCounts.fromJson(
      result.data!['followCounts'] as Map<String, dynamic>,
    );
  }

  Future<RelationshipStatus> getRelationshipStatus(String userId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(RelationshipQueries.relationshipStatus),
        variables: {'userId': userId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    return RelationshipStatus.fromJson(
      result.data!['relationshipStatus'] as Map<String, dynamic>,
    );
  }

  Future<List<User>> _fetchUserList({
    required String query,
    required String rootKey,
  }) async {
    final result = await _client.query(
      QueryOptions(document: gql(query), fetchPolicy: FetchPolicy.networkOnly),
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

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import '../models/reference_material.dart';

class ReferenceMaterialService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery();

  // ─── Queries ───────────────────────────────────────────────────────────────

  static const _getAll = r'''
    query {
      referenceMaterials {
        id
        title
        type
        description
        fileUrl
        songId
        topic
        createdAt
        updatedAt
      }
    }
  ''';

  static const _getOne = r'''
    query GetReference($id: ID!) {
      referenceMaterial(id: $id) {
        id
        title
        type
        description
        fileUrl
        songId
        topic
        createdAt
        updatedAt
      }
    }
  ''';

  // ─── Mutations ─────────────────────────────────────────────────────────────

  static const _create = r'''
    mutation CreateReference($input: CreateReferenceMaterialInput!) {
      createReferenceMaterial(input: $input) {
        id
        title
        type
        description
        fileUrl
        songId
        topic
        createdAt
        updatedAt
      }
    }
  ''';

  static const _update = r'''
    mutation UpdateReference($id: ID!, $input: UpdateReferenceMaterialInput!) {
      updateReferenceMaterial(id: $id, input: $input) {
        id
        title
        type
        description
        fileUrl
        songId
        topic
        createdAt
        updatedAt
      }
    }
  ''';

  static const _delete = r'''
    mutation DeleteReference($id: ID!) {
      deleteReferenceMaterial(id: $id)
    }
  ''';

  // ─── Methods ───────────────────────────────────────────────────────────────

  Future<List<ReferenceMaterial>> fetchAll() async {
    final result = await _client.query(
      QueryOptions(document: gql(_getAll)),
    );
    if (result.hasException) throw result.exception!;
    final list = result.data!['referenceMaterials'] as List;
    return list.map((e) => ReferenceMaterial.fromJson(e)).toList();
  }

  Future<ReferenceMaterial> fetchOne(String id) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(_getOne),
        variables: {'id': id},
      ),
    );
    if (result.hasException) throw result.exception!;
    return ReferenceMaterial.fromJson(result.data!['referenceMaterial']);
  }

  Future<ReferenceMaterial> create(Map<String, dynamic> input) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(_create),
        variables: {'input': input},
      ),
    );
    if (result.hasException) throw result.exception!;
    return ReferenceMaterial.fromJson(result.data!['createReferenceMaterial']);
  }

  Future<ReferenceMaterial> update(String id, Map<String, dynamic> input) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(_update),
        variables: {'id': id, 'input': input},
      ),
    );
    if (result.hasException) throw result.exception!;
    return ReferenceMaterial.fromJson(result.data!['updateReferenceMaterial']);
  }

  Future<bool> delete(String id) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(_delete),
        variables: {'id': id},
      ),
    );
    if (result.hasException) throw result.exception!;
    return result.data!['deleteReferenceMaterial'] as bool;
  }
}
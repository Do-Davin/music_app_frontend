import 'dart:io';
import 'dart:convert';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import '../models/reference_material.dart';

class ReferenceMaterialService {
  final GraphQLClient client;
  
  // Extract base URL from GraphQLConfig
  static String get baseUrl {
    final endpoint = GraphQLConfig.httpEndpoint;
    return endpoint.replaceAll('/graphql', '');
  }

  ReferenceMaterialService(this.client);

  // Query all reference materials
  Future<List<ReferenceMaterial>> fetchAll({String? type}) async {
    const String query = r'''
      query GetReferenceMaterials($type: String) {
        referenceMaterials(type: $type) {
          _id
          title
          type
          description
          filePath
          fileName
          fileSize
          mimeType
          songId
          topic
          createdAt
          updatedAt
        }
      }
    ''';

    final result = await client.query(
      QueryOptions(
        document: gql(query),
        variables: type != null ? {'type': type} : {},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    final List data = result.data?['referenceMaterials'] ?? [];
    return data.map((json) => ReferenceMaterial.fromJson(json)).toList();
  }

  // Create with file upload using multipart
  Future<ReferenceMaterial> create({
    required String title,
    required String type,
    String? description,
    File? file,
    String? songId,
    String? topic,
  }) async {
    if (file != null) {
      return await _createWithMultipart(
        title: title,
        type: type,
        description: description,
        file: file,
        songId: songId,
        topic: topic,
      );
    } else {
      return await _createWithoutFile(
        title: title,
        type: type,
        description: description,
        songId: songId,
        topic: topic,
      );
    }
  }

  // Create using GraphQL multipart request
  Future<ReferenceMaterial> _createWithMultipart({
    required String title,
    required String type,
    String? description,
    required File file,
    String? songId,
    String? topic,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(GraphQLConfig.httpEndpoint));

    // GraphQL operation
    final operations = {
      'query': r'''
        mutation CreateReferenceMaterial($input: CreateReferenceMaterialInput!) {
          createReferenceMaterial(input: $input) {
            _id
            title
            type
            description
            filePath
            fileName
            fileSize
            mimeType
            songId
            topic
            createdAt
            updatedAt
          }
        }
      ''',
      'variables': {
        'input': {
          'title': title,
          'type': type,
          'description': description,
          'songId': songId,
          'topic': topic,
          'file': null,
        },
      },
    };

    // Map file to variable
    final map = {
      '0': ['variables.input.file'],
    };

    request.fields['operations'] = jsonEncode(operations);
    request.fields['map'] = jsonEncode(map);

    // Add file
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    request.files.add(
      await http.MultipartFile.fromPath(
        '0',
        file.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final json = jsonDecode(responseBody);

    if (json['errors'] != null) {
      throw Exception(json['errors'][0]['message']);
    }

    return ReferenceMaterial.fromJson(json['data']['createReferenceMaterial']);
  }

  // Create without file (fallback)
  Future<ReferenceMaterial> _createWithoutFile({
    required String title,
    required String type,
    String? description,
    String? songId,
    String? topic,
  }) async {
    const String mutation = r'''
      mutation CreateReferenceMaterial($input: CreateReferenceMaterialInput!) {
        createReferenceMaterial(input: $input) {
          _id
          title
          type
          description
          filePath
          fileName
          fileSize
          mimeType
          songId
          topic
          createdAt
          updatedAt
        }
      }
    ''';

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          'input': {
            'title': title,
            'type': type,
            'description': description,
            'songId': songId,
            'topic': topic,
          },
        },
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    return ReferenceMaterial.fromJson(result.data!['createReferenceMaterial']);
  }

  // Update with optional file replacement
  Future<ReferenceMaterial> update({
    required String id,
    String? title,
    String? type,
    String? description,
    File? file,
    String? songId,
    String? topic,
  }) async {
    if (file != null) {
      return await _updateWithMultipart(
        id: id,
        title: title,
        type: type,
        description: description,
        file: file,
        songId: songId,
        topic: topic,
      );
    } else {
      return await _updateWithoutFile(
        id: id,
        title: title,
        type: type,
        description: description,
        songId: songId,
        topic: topic,
      );
    }
  }

  Future<ReferenceMaterial> _updateWithMultipart({
    required String id,
    String? title,
    String? type,
    String? description,
    required File file,
    String? songId,
    String? topic,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(GraphQLConfig.httpEndpoint));

    final operations = {
      'query': r'''
        mutation UpdateReferenceMaterial($id: ID!, $input: UpdateReferenceMaterialInput!) {
          updateReferenceMaterial(id: $id, input: $input) {
            _id
            title
            type
            description
            filePath
            fileName
            fileSize
            mimeType
            songId
            topic
            createdAt
            updatedAt
          }
        }
      ''',
      'variables': {
        'id': id,
        'input': {
          if (title != null) 'title': title,
          if (type != null) 'type': type,
          if (description != null) 'description': description,
          if (songId != null) 'songId': songId,
          if (topic != null) 'topic': topic,
          'file': null,
        },
      },
    };

    final map = {
      '0': ['variables.input.file'],
    };

    request.fields['operations'] = jsonEncode(operations);
    request.fields['map'] = jsonEncode(map);

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    request.files.add(
      await http.MultipartFile.fromPath(
        '0',
        file.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final json = jsonDecode(responseBody);

    if (json['errors'] != null) {
      throw Exception(json['errors'][0]['message']);
    }

    return ReferenceMaterial.fromJson(json['data']['updateReferenceMaterial']);
  }

  Future<ReferenceMaterial> _updateWithoutFile({
    required String id,
    String? title,
    String? type,
    String? description,
    String? songId,
    String? topic,
  }) async {
    const String mutation = r'''
      mutation UpdateReferenceMaterial($id: ID!, $input: UpdateReferenceMaterialInput!) {
        updateReferenceMaterial(id: $id, input: $input) {
          _id
          title
          type
          description
          filePath
          fileName
          fileSize
          mimeType
          songId
          topic
          createdAt
          updatedAt
        }
      }
    ''';

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          'id': id,
          'input': {
            if (title != null) 'title': title,
            if (type != null) 'type': type,
            if (description != null) 'description': description,
            if (songId != null) 'songId': songId,
            if (topic != null) 'topic': topic,
          },
        },
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    return ReferenceMaterial.fromJson(result.data!['updateReferenceMaterial']);
  }

  // Delete reference material
  Future<bool> delete(String id) async {
    const String mutation = r'''
      mutation DeleteReferenceMaterial($id: ID!) {
        deleteReferenceMaterial(id: $id)
      }
    ''';

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    return result.data?['deleteReferenceMaterial'] ?? false;
  }
}
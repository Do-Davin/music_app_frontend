import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reference_material.dart';

class ReferenceMaterialService {
  // Always build a fresh authenticated client so the latest token is used.
  GraphQLClient get _client => GraphQLConfig.clientToQuery(authenticated: true);

  /// Read the stored access token for use in raw HTTP requests (multipart).
  Future<String?> _readToken() async {
    const key = 'access_token';
    try {
      const storage = FlutterSecureStorage();
      return await storage.read(key: key);
    } on MissingPluginException {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  // Full selection set shared by all operations
  static const String _materialFields = '''
    _id
    title
    type
    description
    filePath
    fileUrl
    fileName
    fileSize
    mimeType
    songId
    topic
    createdAt
    updatedAt
  ''';

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
          fileUrl
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

    final result = await _client.query(
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
      return _createWithMultipart(
        title: title,
        type: type,
        description: description,
        file: file,
        songId: songId,
        topic: topic,
      );
    } else {
      return _createWithoutFile(
        title: title,
        type: type,
        description: description,
        songId: songId,
        topic: topic,
      );
    }
  }

  // Create using GraphQL multipart request (includes Authorization header)
  Future<ReferenceMaterial> _createWithMultipart({
    required String title,
    required String type,
    String? description,
    required File file,
    String? songId,
    String? topic,
  }) async {
    final token = await _readToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(GraphQLConfig.httpEndpoint),
    );

    // Attach Bearer token so the backend JwtAuthGuard accepts the request
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final operations = {
      'query': '''
        mutation CreateReferenceMaterial(\$input: CreateReferenceMaterialInput!) {
          createReferenceMaterial(input: \$input) {
            $_materialFields
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
    final json = jsonDecode(responseBody) as Map<String, dynamic>;

    if (json['errors'] != null) {
      final errors = json['errors'] as List;
      throw Exception(errors[0]['message']);
    }

    return ReferenceMaterial.fromJson(
      json['data']['createReferenceMaterial'] as Map<String, dynamic>,
    );
  }

  // Create without file using GraphQL client (token handled by AuthLink)
  Future<ReferenceMaterial> _createWithoutFile({
    required String title,
    required String type,
    String? description,
    String? songId,
    String? topic,
  }) async {
    const String mutation = '''
      mutation CreateReferenceMaterial(\$input: CreateReferenceMaterialInput!) {
        createReferenceMaterial(input: \$input) {
          $_materialFields
        }
      }
    ''';

    final result = await _client.mutate(
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

    return ReferenceMaterial.fromJson(
      result.data!['createReferenceMaterial'] as Map<String, dynamic>,
    );
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
      return _updateWithMultipart(
        id: id,
        title: title,
        type: type,
        description: description,
        file: file,
        songId: songId,
        topic: topic,
      );
    } else {
      return _updateWithoutFile(
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
    final token = await _readToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(GraphQLConfig.httpEndpoint),
    );

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final operations = {
      'query': '''
        mutation UpdateReferenceMaterial(\$id: ID!, \$input: UpdateReferenceMaterialInput!) {
          updateReferenceMaterial(id: \$id, input: \$input) {
            $_materialFields
          }
        }
      ''',
      'variables': {
        'id': id,
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
    final json = jsonDecode(responseBody) as Map<String, dynamic>;

    if (json['errors'] != null) {
      final errors = json['errors'] as List;
      throw Exception(errors[0]['message']);
    }

    return ReferenceMaterial.fromJson(
      json['data']['updateReferenceMaterial'] as Map<String, dynamic>,
    );
  }

  Future<ReferenceMaterial> _updateWithoutFile({
    required String id,
    String? title,
    String? type,
    String? description,
    String? songId,
    String? topic,
  }) async {
    const String mutation = '''
      mutation UpdateReferenceMaterial(\$id: ID!, \$input: UpdateReferenceMaterialInput!) {
        updateReferenceMaterial(id: \$id, input: \$input) {
          $_materialFields
        }
      }
    ''';

    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          'id': id,
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

    return ReferenceMaterial.fromJson(
      result.data!['updateReferenceMaterial'] as Map<String, dynamic>,
    );
  }

  // Delete reference material
  Future<bool> delete(String id) async {
    const String mutation = r'''
      mutation DeleteReferenceMaterial($id: ID!) {
        deleteReferenceMaterial(id: $id)
      }
    ''';

    final result = await _client.mutate(
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

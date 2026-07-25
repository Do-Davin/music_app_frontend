import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
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
    cloudinaryResourceType
    fileName
    fileSize
    mimeType
    songId
    topic
    createdAt
    updatedAt
  ''';

  /// Extracts a human-readable message from a GraphQL error list.
  /// Strips the "Exception: " prefix that [Exception.toString()] adds.
  static String _extractErrorMessage(List<dynamic> errors) {
    final raw = errors[0]['message']?.toString() ?? 'Unknown error';
    // Strip wrapper added by Dart's Exception class
    if (raw.startsWith('Exception: ')) return raw.substring('Exception: '.length);
    return raw;
  }

  /// Throws a [ReferenceMaterialException] with a clean message.
  static Never _throwFromErrors(List<dynamic> errors) {
    throw ReferenceMaterialException(_extractErrorMessage(errors));
  }

  /// Safely parses the HTTP response body as JSON.
  /// Throws [ReferenceMaterialException] with a clear message if the server
  /// returned a non-JSON body (e.g. 502 HTML error page).
  static Map<String, dynamic> _parseJsonResponse(
    String body,
    int statusCode,
  ) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      throw ReferenceMaterialException(
        'Server error (HTTP $statusCode). Please try again.',
      );
    }
  }

  // ────────────────────────────────────────────────────────────────
  //  READ
  // ────────────────────────────────────────────────────────────────

  Future<List<ReferenceMaterial>> fetchAll({
    String? type,
    String? songId,
  }) async {
    const String query = r'''
      query GetReferenceMaterials($type: String, $songId: String) {
        referenceMaterials(type: $type, songId: $songId) {
          _id
          title
          type
          description
          filePath
          fileUrl
          cloudinaryResourceType
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

    // Only include variables that are non-null — avoids sending explicit nulls
    // which some GraphQL servers treat differently from omitted fields.
    final variables = <String, dynamic>{};
    if (type != null) variables['type'] = type;
    if (songId != null) variables['songId'] = songId;

    final result = await _client.query(
      QueryOptions(
        document: gql(query),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) throw result.exception!;

    final List data = result.data?['referenceMaterials'] ?? [];
    return data
        .map((json) => ReferenceMaterial.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ────────────────────────────────────────────────────────────────
  //  CREATE
  // ────────────────────────────────────────────────────────────────

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
    }
    return _createWithoutFile(
      title: title,
      type: type,
      description: description,
      songId: songId,
      topic: topic,
    );
  }

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

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Build the input map — only include non-null optional fields so the
    // backend's `if (input.X !== undefined)` guards behave correctly.
    final inputMap = <String, dynamic>{
      'title': title,
      'type': type,
      'file': null, // placeholder — replaced by multipart map below
    };
    if (description != null) inputMap['description'] = description;
    if (songId != null) inputMap['songId'] = songId;
    if (topic != null) inputMap['topic'] = topic;

    final operations = {
      'query': '''
        mutation CreateReferenceMaterial(\$input: CreateReferenceMaterialInput!) {
          createReferenceMaterial(input: \$input) {
            $_materialFields
          }
        }
      ''',
      'variables': {'input': inputMap},
    };

    request.fields['operations'] = jsonEncode(operations);
    request.fields['map'] = jsonEncode({
      '0': ['variables.input.file'],
    });

    // Read eagerly to avoid temporary-path issues on physical devices.
    final fileBytes = await file.readAsBytes();
    final fileName = p.basename(file.path);
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    request.files.add(
      http.MultipartFile.fromBytes(
        '0',
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamed = await request.send().timeout(
      const Duration(minutes: 3),
      onTimeout: () => throw ReferenceMaterialException(
        'Upload timed out. Check your connection and try again.',
      ),
    );
    final responseBody = await streamed.stream.bytesToString();
    final json = _parseJsonResponse(responseBody, streamed.statusCode);

    if (json['errors'] != null) _throwFromErrors(json['errors'] as List);

    final data = json['data']?['createReferenceMaterial'];
    if (data == null) {
      throw const ReferenceMaterialException('Server returned no data for create.');
    }
    return ReferenceMaterial.fromJson(data as Map<String, dynamic>);
  }

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

    final inputMap = <String, dynamic>{'title': title, 'type': type};
    if (description != null) inputMap['description'] = description;
    if (songId != null) inputMap['songId'] = songId;
    if (topic != null) inputMap['topic'] = topic;

    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'input': inputMap},
      ),
    );

    if (result.hasException) throw result.exception!;

    return ReferenceMaterial.fromJson(
      result.data!['createReferenceMaterial'] as Map<String, dynamic>,
    );
  }

  // ────────────────────────────────────────────────────────────────
  //  UPDATE
  // ────────────────────────────────────────────────────────────────

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
    }
    return _updateWithoutFile(
      id: id,
      title: title,
      type: type,
      description: description,
      songId: songId,
      topic: topic,
    );
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

    // Only include fields that were provided by the caller.
    final inputMap = <String, dynamic>{'file': null};
    if (title != null) inputMap['title'] = title;
    if (type != null) inputMap['type'] = type;
    if (description != null) inputMap['description'] = description;
    if (songId != null) inputMap['songId'] = songId;
    if (topic != null) inputMap['topic'] = topic;

    final operations = {
      'query': '''
        mutation UpdateReferenceMaterial(\$id: ID!, \$input: UpdateReferenceMaterialInput!) {
          updateReferenceMaterial(id: \$id, input: \$input) {
            $_materialFields
          }
        }
      ''',
      'variables': {'id': id, 'input': inputMap},
    };

    request.fields['operations'] = jsonEncode(operations);
    request.fields['map'] = jsonEncode({
      '0': ['variables.input.file'],
    });

    final fileBytes = await file.readAsBytes();
    final fileName = p.basename(file.path);
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    request.files.add(
      http.MultipartFile.fromBytes(
        '0',
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamed = await request.send().timeout(
      const Duration(minutes: 3),
      onTimeout: () => throw ReferenceMaterialException(
        'Upload timed out. Check your connection and try again.',
      ),
    );
    final responseBody = await streamed.stream.bytesToString();
    final json = _parseJsonResponse(responseBody, streamed.statusCode);

    if (json['errors'] != null) _throwFromErrors(json['errors'] as List);

    final data = json['data']?['updateReferenceMaterial'];
    if (data == null) {
      throw const ReferenceMaterialException('Server returned no data for update.');
    }
    return ReferenceMaterial.fromJson(data as Map<String, dynamic>);
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

    // Only include fields that were provided by the caller.
    final inputMap = <String, dynamic>{};
    if (title != null) inputMap['title'] = title;
    if (type != null) inputMap['type'] = type;
    if (description != null) inputMap['description'] = description;
    if (songId != null) inputMap['songId'] = songId;
    if (topic != null) inputMap['topic'] = topic;

    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'id': id, 'input': inputMap},
      ),
    );

    if (result.hasException) throw result.exception!;

    return ReferenceMaterial.fromJson(
      result.data!['updateReferenceMaterial'] as Map<String, dynamic>,
    );
  }

  // ────────────────────────────────────────────────────────────────
  //  DELETE
  // ────────────────────────────────────────────────────────────────

  Future<bool> delete(String id) async {
    const String mutation = r'''
      mutation DeleteReferenceMaterial($id: ID!) {
        deleteReferenceMaterial(id: $id)
      }
    ''';

    final result = await _client.mutate(
      MutationOptions(document: gql(mutation), variables: {'id': id}),
    );

    if (result.hasException) throw result.exception!;

    return result.data?['deleteReferenceMaterial'] ?? false;
  }
}

/// Typed exception for clean error messages in the UI layer.
class ReferenceMaterialException implements Exception {
  final String message;
  const ReferenceMaterialException(this.message);

  @override
  String toString() => message;
}

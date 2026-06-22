import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/core/network/graphql_error_parser.dart';
import 'package:music_app_frontend/core/network/queries/index.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery(
    authenticated: true,
  );

  Future<User> fetchMe() async {
    final result = await _client.query(
      QueryOptions(
        document: gql(UserQueries.getMe),
        fetchPolicy: FetchPolicy.noCache,
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    return User.fromJson(result.data!['me'] as Map<String, dynamic>);
  }

  Future<bool> isUsernameAvailable({
    required String username,
    required String currentUserId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(UserQueries.searchUsers),
        variables: {'search': username},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    final users = result.data?['searchUsers'] as List<dynamic>? ?? [];
    final normalizedUsername = username.trim().toLowerCase();

    return users.every((json) {
      final user = User.fromJson(json as Map<String, dynamic>);
      final isSameUsername =
          user.username.trim().toLowerCase() == normalizedUsername;
      return !isSameUsername || user.id == currentUserId;
    });
  }

  Future<User> updateUsername(String username) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(UserMutations.updateUsername),
        variables: {'newUsername': username},
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    return User.fromJson(
      result.data!['updateUsername'] as Map<String, dynamic>,
    );
  }

  Future<User> switchToProfessionalAccount() async {
    final result = await _client.mutate(
      MutationOptions(document: gql(UserMutations.switchToProfessionalAccount)),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    return User.fromJson(
      result.data!['switchToProfessionalAccount'] as Map<String, dynamic>,
    );
  }

  /// Upload a profile image to POST /users/me/profile-image.
  ///
  /// [imageBytes] — raw bytes of the image file.
  /// [filename]   — original filename, used for Content-Disposition and MIME
  ///                type detection.
  ///
  /// The backend multipart field name is `image` (as declared by
  /// `FileInterceptor('image', …)` in users.controller.ts). After a successful
  /// upload we call [fetchMe] to get the authoritative full user document with
  /// the new [User.profileImageUrl].
  Future<User> uploadProfileImage({
    required List<int> imageBytes,
    required String filename,
  }) async {
    final token = await _readToken();
    final url = Uri.parse(
      '${GraphQLConfig.serverBaseUrl}/users/me/profile-image',
    );

    final request = http.MultipartRequest('POST', url);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final mimeType = lookupMimeType(filename) ?? 'image/jpeg';
    request.files.add(
      http.MultipartFile.fromBytes(
        'image', // backend FileInterceptor('image', …) expects this field name
        imageBytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200 && streamed.statusCode != 201) {
      final decoded = _tryDecode(body);
      final message = decoded is Map
          ? (decoded['message'] ?? 'Upload failed').toString()
          : 'Image upload failed (${streamed.statusCode})';
      throw Exception(message);
    }

    // The upload response includes _id, username, email, profileType, and
    // profileImageUrl — enough for User.fromJson. Parsing directly avoids a
    // second network round-trip. meProvider is still invalidated by the caller
    // so the full user (practiceGoals, practiceStreak) syncs in the background.
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response from server');
    }
    return User.fromJson(decoded);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}

// Convenience wrapper for callers that already have a File handle.
extension UserServiceFileUpload on UserService {
  Future<User> uploadProfileImageFile(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return uploadProfileImage(
      imageBytes: bytes,
      filename: p.basename(imageFile.path),
    );
  }
}

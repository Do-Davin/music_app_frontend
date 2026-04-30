import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/features/auth/data/services/token_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GraphQLConfig {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Auto-detects the correct host based on platform:
  /// - Android emulator → 10.0.2.2 (maps to host machine's localhost)
  /// - iOS simulator / macOS / Windows / Linux / Web → localhost
  static String get _host {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) {
      // Pull the 'ip' key from your .env file
      // Fallback to 10.0.2.2 if the .env key is missing
      return dotenv.get('ip', fallback: '10.0.2.2');
    }
    return 'localhost';
  }

  static String get httpEndpoint => 'http://$_host:3000/graphql';

  static Link _buildLink({bool authenticated = false}) {
    final httpLink = HttpLink(httpEndpoint);

    if (!authenticated) {
      return httpLink;
    }

    final authLink = AuthLink(
      getToken: () async {
        String? token;
        try {
          token = await _secureStorage.read(
            key: TokenStorageService.accessTokenKey,
          );
        } on MissingPluginException {
          final prefs = await SharedPreferences.getInstance();
          token = prefs.getString(TokenStorageService.accessTokenKey);
        }

        if (token == null || token.isEmpty) {
          return null;
        }

        return 'Bearer $token';
      },
    );

    return authLink.concat(httpLink);
  }

  static ValueNotifier<GraphQLClient> initClient() {
    return ValueNotifier(
      GraphQLClient(
        link: _buildLink(),
        cache: GraphQLCache(store: InMemoryStore()),
      ),
    );
  }

  static GraphQLClient clientToQuery({bool authenticated = false}) {
    return GraphQLClient(
      link: _buildLink(authenticated: authenticated),
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }
}

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
  static const String _dartDefineGraphqlUrl = String.fromEnvironment(
    'GRAPHQL_URL',
  );

  /// Auto-detects the correct host based on platform:
  /// - Android emulator → 10.0.2.2 (maps to host machine's localhost)
  /// - iOS real device / simulator → .env ip, not localhost
  /// - macOS / Windows / Linux / Web → .env ip or localhost
  static String get _host {
    final envHost = dotenv.maybeGet('ip');
    if (envHost != null && envHost.isNotEmpty) return envHost;

    if (kIsWeb) return 'localhost';
    if (Platform.isIOS) {
      throw StateError(
        'Missing .env ip for iOS GraphQL endpoint. Add ip=<your Mac LAN IP> to .env.',
      );
    }
    if (Platform.isAndroid) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static String get httpEndpoint {
    if (_dartDefineGraphqlUrl.isNotEmpty) return _dartDefineGraphqlUrl;

    final envGraphqlUrl = dotenv.maybeGet('GRAPHQL_URL');
    if (envGraphqlUrl != null && envGraphqlUrl.isNotEmpty) {
      return envGraphqlUrl;
    }

    return 'http://$_host:3000/graphql';
  }

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

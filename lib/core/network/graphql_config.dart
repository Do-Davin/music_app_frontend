import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb;
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
  static bool _hasLoggedEndpoint = false;

  static String get httpEndpoint {
    final endpoint = _resolveHttpEndpoint();
    _logEndpoint(endpoint);
    return endpoint.url;
  }

  /// The base server URL (scheme + host + port), derived from [httpEndpoint].
  /// Used to rewrite file URLs returned by the backend so they point to the
  /// correct host on the current device (avoids localhost vs 10.0.2.2 mismatch).
  static String get serverBaseUrl {
    final uri = Uri.tryParse(httpEndpoint);
    if (uri == null) return '';
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  static _ResolvedEndpoint _resolveHttpEndpoint() {
    final dartDefineUrl = _dartDefineGraphqlUrl.trim();
    if (dartDefineUrl.isNotEmpty) {
      return _ResolvedEndpoint(dartDefineUrl, 'dart-define');
    }

    final envGraphqlUrl = dotenv.maybeGet('GRAPHQL_URL')?.trim();
    if (envGraphqlUrl != null && envGraphqlUrl.isNotEmpty) {
      return _ResolvedEndpoint(envGraphqlUrl, '.env GRAPHQL_URL');
    }

    final deprecatedIp = dotenv.maybeGet('ip')?.trim();
    if (deprecatedIp != null && deprecatedIp.isNotEmpty) {
      return _ResolvedEndpoint(
        'http://$deprecatedIp:3000/graphql',
        'deprecated .env ip',
        warning:
            'The .env "ip" variable is deprecated. Use GRAPHQL_URL=http://$deprecatedIp:3000/graphql instead.',
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return const _ResolvedEndpoint(
        'http://10.0.2.2:3000/graphql',
        'Android emulator fallback',
      );
    }

    return const _ResolvedEndpoint(
      'http://localhost:3000/graphql',
      'localhost fallback',
    );
  }

  static void _logEndpoint(_ResolvedEndpoint endpoint) {
    if (!kDebugMode || _hasLoggedEndpoint) return;

    _hasLoggedEndpoint = true;
    debugPrint(
      'GraphQL endpoint: ${endpoint.url} (source: ${endpoint.source})',
    );
    if (endpoint.warning != null) {
      debugPrint('GraphQL config warning: ${endpoint.warning}');
    }
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
        defaultPolicies: _defaultPolicies(),
      ),
    );
  }

  static GraphQLClient clientToQuery({bool authenticated = false}) {
    return GraphQLClient(
      link: _buildLink(authenticated: authenticated),
      cache: GraphQLCache(store: InMemoryStore()),
      defaultPolicies: _defaultPolicies(authenticated: authenticated),
    );
  }

  static DefaultPolicies _defaultPolicies({bool authenticated = false}) {
    if (!authenticated) {
      return DefaultPolicies();
    }

    return DefaultPolicies(
      query: Policies(fetch: FetchPolicy.noCache),
      watchQuery: Policies(fetch: FetchPolicy.noCache),
    );
  }
}

class _ResolvedEndpoint {
  final String url;
  final String source;
  final String? warning;

  const _ResolvedEndpoint(this.url, this.source, {this.warning});
}

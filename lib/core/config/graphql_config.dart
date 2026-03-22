import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLConfig {
  /// Auto-detects the correct host based on platform:
  /// - Android emulator → 10.0.2.2 (maps to host machine's localhost)
  /// - iOS simulator / macOS / Windows / Linux / Web → localhost
  static String get _host {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static String get httpEndpoint => 'http://$_host:3000/graphql';

  static ValueNotifier<GraphQLClient> initClient() {
    final HttpLink httpLink = HttpLink(httpEndpoint);

    return ValueNotifier(
      GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(store: InMemoryStore()),
      ),
    );
  }

  static GraphQLClient clientToQuery() {
    final HttpLink httpLink = HttpLink(httpEndpoint);

    return GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }
}

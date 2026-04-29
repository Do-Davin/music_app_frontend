import 'package:graphql_flutter/graphql_flutter.dart';

String parseGraphQlException(OperationException exception) {
  if (exception.graphqlErrors.isNotEmpty) {
    return exception.graphqlErrors.map((error) => error.message).join('\n');
  }

  if (exception.linkException != null) {
    return exception.linkException.toString();
  }

  return 'Request failed';
}

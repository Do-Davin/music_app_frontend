import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/config/graphql_config.dart';
import 'package:music_app_frontend/core/network/mutations.dart';
import 'package:music_app_frontend/features/auth/domain/models/forgotpassword_model.dart';

class ForgotPasswordService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery();

  /// Step 1: Send reset code to email
  Future<ForgotPasswordModel> sendResetCode(String email) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(AuthMutations.forgotPassword),
          variables: {'email': email},
        ),
      );

      if (result.hasException) {
        throw Exception(_handleError(result.exception!));
      }

      final success = result.data?['forgotPassword']?['success'] ?? false;
      if (!success) {
        throw Exception(result.data?['forgotPassword']?['message'] ?? 'Failed to send reset code');
      }

      return ForgotPasswordModel(
        email: email,
        codeSent: true,
        codeVerified: false,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to send reset code: $e');
    }
  }

  /// Step 2: Verify the passcode entered by user
  Future<ForgotPasswordModel> verifyCode(String email, String code) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(AuthMutations.verifyResetCode),
          variables: {'email': email, 'code': code},
        ),
      );

      if (result.hasException) {
        throw Exception(_handleError(result.exception!));
      }

      final success = result.data?['verifyResetCode']?['success'] ?? false;
      if (!success) {
        throw Exception(result.data?['verifyResetCode']?['message'] ?? 'Invalid code');
      }

      return ForgotPasswordModel(
        email: email,
        codeSent: true,
        codeVerified: true,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to verify code: $e');
    }
  }

  /// Step 3: Reset password with new password
  Future<void> resetPassword(String email, String newPassword, String code) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(AuthMutations.resetPassword),
          variables: {
            'email': email,
            'password': newPassword,
            'code': code,
          },
        ),
      );

      if (result.hasException) {
        throw Exception(_handleError(result.exception!));
      }

      final success = result.data?['resetPassword']?['success'] ?? false;
      if (!success) {
        throw Exception(result.data?['resetPassword']?['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to reset password: $e');
    }
  }

  /// Resend reset code to email
  Future<void> resendCode(String email) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(AuthMutations.forgotPassword),
          variables: {'email': email},
        ),
      );

      if (result.hasException) {
        throw Exception(_handleError(result.exception!));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to resend code: $e');
    }
  }

  String _handleError(OperationException exception) {
    if (exception.graphqlErrors.isNotEmpty) {
      return exception.graphqlErrors.first.message;
    }
    if (exception.linkException != null) {
      return 'Network error. Please check your connection.';
    }
    return 'An unexpected error occurred.';
  }
}

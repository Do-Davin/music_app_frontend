import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/core/network/graphql_error_parser.dart';
import 'package:music_app_frontend/core/network/queries/index.dart';
import 'package:music_app_frontend/features/auth/data/models/forgot_password_model.dart';

class ForgotPasswordService {
  final GraphQLClient _client = GraphQLConfig.clientToQuery();

  /// Step 1: Send reset code to email
  Future<ForgotPasswordModel> sendResetCode(String email) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(AuthMutations.sendResetCode),
        variables: {
          'input': {'email': email},
        },
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    return ForgotPasswordModel.fromSendResetCodeJson(
      result.data!['sendResetCode'] as Map<String, dynamic>,
    );
  }

  /// Step 2: Verify the passcode entered by user
  Future<ForgotPasswordModel> verifyCode(String email, String code) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(AuthMutations.verifyCode),
        variables: {
          'input': {'email': email, 'code': code},
        },
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    return ForgotPasswordModel.fromVerifyCodeJson(
      result.data!['verifyCode'] as Map<String, dynamic>,
      email: email,
      code: code,
    );
  }

  /// Step 3: Reset password with new password
  Future<ForgotPasswordModel> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(AuthMutations.resetPassword),
        variables: {
          'input': {'email': email, 'code': code, 'newPassword': newPassword},
        },
      ),
    );

    if (result.hasException) {
      throw Exception(parseGraphQlException(result.exception!));
    }

    return ForgotPasswordModel.fromResetPasswordJson(
      result.data!['resetPassword'] as Map<String, dynamic>,
      email: email,
      code: code,
    );
  }

  /// Resend reset code to email
  Future<void> resendCode(String email) async {
    await sendResetCode(email);
  }
}

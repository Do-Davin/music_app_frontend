// ─────────────────────────────────────────────────────────────────────────────
// TIER 1 — DATA LAYER
// Path: lib/features/auth/data/services/forgot_password_service.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:music_app_frontend/features/auth/data/models/forgot_password_model.dart';

class ForgotPasswordService {
  /// Step 1: Send reset code to email
  Future<ForgotPasswordModel> sendResetCode(String email) async {
    try {
      // TODO: Replace with real API call e.g:
      // final response = await http.post(
      //   Uri.parse('https://your-api.com/auth/forgot-password'),
      //   body: jsonEncode({'email': email}),
      // );

      // ── Simulated API response ─────────────────────────────────────────
      await Future.delayed(const Duration(milliseconds: 600));

      return ForgotPasswordModel(
        email: email,
        codeSent: true, // ← API confirmed code was sent
        codeVerified: false,
      );
    } catch (e) {
      throw Exception('Failed to send reset code: $e');
    }
  }

  /// Step 2: Verify the passcode entered by user
  Future<ForgotPasswordModel> verifyCode(String email, String code) async {
    try {
      // TODO: Replace with real API call e.g:
      // final response = await http.post(
      //   Uri.parse('https://your-api.com/auth/verify-code'),
      //   body: jsonEncode({'email': email, 'code': code}),
      // );

      // ── Simulated API response ─────────────────────────────────────────
      await Future.delayed(const Duration(milliseconds: 600));

      return ForgotPasswordModel(
        email: email,
        codeSent: true,
        codeVerified: true, // ← API confirmed code is correct
      );
    } catch (e) {
      throw Exception('Failed to verify code: $e');
    }
  }

  /// Step 3: Reset password with new password
  Future<void> resetPassword(String email, String newPassword) async {
    try {
      // TODO: Replace with real API call e.g:
      // final response = await http.post(
      //   Uri.parse('https://your-api.com/auth/reset-password'),
      //   body: jsonEncode({'email': email, 'password': newPassword}),
      // );

      // ── Simulated API response ─────────────────────────────────────────
      await Future.delayed(const Duration(milliseconds: 600));
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  /// Resend reset code to email
  Future<void> resendCode(String email) async {
    try {
      // TODO: Replace with real API call
      await Future.delayed(const Duration(milliseconds: 400));
    } catch (e) {
      throw Exception('Failed to resend code: $e');
    }
  }
}

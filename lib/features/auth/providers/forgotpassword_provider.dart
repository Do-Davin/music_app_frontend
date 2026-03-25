// ─────────────────────────────────────────────────────────────────────────────
// TIER 2 — DOMAIN LAYER
// Path: lib/features/auth/domain/providers/forgot_password_provider.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/auth/services/forgotpassword_service.dart';

// ── Expose ForgotPasswordService as a provider ────────────────────────────────
final forgotPasswordServiceProvider = Provider<ForgotPasswordService>(
  (ref) => ForgotPasswordService(),
);

// ─────────────────────────────────────────────────────────────────────────────
// State class — tracks every possible state in the forgot password flow
// ─────────────────────────────────────────────────────────────────────────────
class ForgotPasswordState {
  final bool isLoading; // true while waiting for API
  final String? errorMessage; // not null when something goes wrong
  final bool codeSent; // true after Step 1 success
  final bool codeVerified; // true after Step 2 success
  final bool passwordReset; // true after Step 3 success
  final String email; // carried across all 3 steps

  const ForgotPasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.codeSent = false,
    this.codeVerified = false,
    this.passwordReset = false,
    this.email = '',
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? codeSent,
    bool? codeVerified,
    bool? passwordReset,
    String? email,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // null clears the error
      codeSent: codeSent ?? this.codeSent,
      codeVerified: codeVerified ?? this.codeVerified,
      passwordReset: passwordReset ?? this.passwordReset,
      email: email ?? this.email,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier — manages state, calls Tier 1 service
// ─────────────────────────────────────────────────────────────────────────────
class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  final ForgotPasswordService _service;

  ForgotPasswordNotifier(this._service) : super(const ForgotPasswordState());

  /// Step 1: Send reset code
  Future<void> sendResetCode(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _service.sendResetCode(email); // ← calls Tier 1
      state = state.copyWith(
        isLoading: false,
        codeSent: result.codeSent,
        email: result.email,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Step 2: Verify passcode
  Future<void> verifyCode(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _service.verifyCode(
        state.email,
        code,
      ); // ← calls Tier 1
      state = state.copyWith(
        isLoading: false,
        codeVerified: result.codeVerified,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Step 3: Reset password
  Future<void> resetPassword(String newPassword) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.resetPassword(state.email, newPassword); // ← calls Tier 1
      state = state.copyWith(isLoading: false, passwordReset: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Resend code
  Future<void> resendCode() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.resendCode(state.email); // ← calls Tier 1
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Reset entire state (e.g. when going back to login)
  void reset() {
    state = const ForgotPasswordState();
  }
}

// ── Expose ForgotPasswordNotifier to the widget tree ─────────────────────────
final forgotPasswordProvider =
    StateNotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(
      (ref) => ForgotPasswordNotifier(
        ref.read(forgotPasswordServiceProvider), // inject Tier 1 into Tier 2
      ),
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/auth/data/services/forgot_password_service.dart';

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
  final String? successMessage; // not null on successful mutation
  final bool codeSent; // true after Step 1 success
  final bool codeVerified; // true after Step 2 success
  final bool passwordReset; // true after Step 3 success
  final String email; // carried across all 3 steps
  final String code; // verified code reused by reset password

  const ForgotPasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.codeSent = false,
    this.codeVerified = false,
    this.passwordReset = false,
    this.email = '',
    this.code = '',
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool? codeSent,
    bool? codeVerified,
    bool? passwordReset,
    String? email,
    String? code,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // null clears the error
      successMessage: successMessage,
      codeSent: codeSent ?? this.codeSent,
      codeVerified: codeVerified ?? this.codeVerified,
      passwordReset: passwordReset ?? this.passwordReset,
      email: email ?? this.email,
      code: code ?? this.code,
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
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final result = await _service.sendResetCode(email); // ← calls Tier 1
      state = state.copyWith(
        isLoading: false,
        codeSent: result.codeSent,
        email: result.email,
        codeVerified: false,
        passwordReset: false,
        code: '',
        successMessage: result.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _normalizeError(e),
        successMessage: null,
      );
    }
  }

  /// Step 2: Verify passcode
  Future<void> verifyCode(String code) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final result = await _service.verifyCode(
        state.email,
        code,
      ); // ← calls Tier 1
      final isValid = result.codeVerified;
      state = state.copyWith(
        isLoading: false,
        codeVerified: isValid,
        code: result.code,
        errorMessage: isValid ? null : result.message,
        successMessage: isValid ? result.message : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _normalizeError(e),
        successMessage: null,
      );
    }
  }

  /// Step 3: Reset password
  Future<void> resetPassword(String newPassword) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final result = await _service.resetPassword(
        state.email,
        state.code,
        newPassword,
      ); // ← calls Tier 1
      state = state.copyWith(
        isLoading: false,
        passwordReset: result.passwordReset,
        errorMessage: result.passwordReset ? null : result.message,
        successMessage: result.passwordReset ? result.message : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _normalizeError(e),
        successMessage: null,
      );
    }
  }

  /// Resend code
  Future<void> resendCode() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      await _service.resendCode(state.email); // ← calls Tier 1
      state = state.copyWith(
        isLoading: false,
        codeSent: true,
        successMessage: 'Code sent successfully.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _normalizeError(e),
        successMessage: null,
      );
    }
  }

  /// Reset entire state (e.g. when going back to login)
  void reset() {
    state = const ForgotPasswordState();
  }

  String _normalizeError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ') ? message.substring(11) : message;
  }
}

// ── Expose ForgotPasswordNotifier to the widget tree ─────────────────────────
final forgotPasswordProvider =
    StateNotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(
      (ref) => ForgotPasswordNotifier(
        ref.read(forgotPasswordServiceProvider), // inject Tier 1 into Tier 2
      ),
    );

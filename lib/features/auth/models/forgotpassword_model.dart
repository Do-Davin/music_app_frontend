// ─────────────────────────────────────────────────────────────────────────────
// TIER 1 — DATA LAYER
// Path: lib/features/auth/data/services/forgot_password_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class ForgotPasswordModel {
  final String email;
  final bool codeSent;
  final bool codeVerified;

  const ForgotPasswordModel({
    required this.email,
    this.codeSent = false,
    this.codeVerified = false,
  });

  ForgotPasswordModel copyWith({
    String? email,
    bool? codeSent,
    bool? codeVerified,
  }) {
    return ForgotPasswordModel(
      email: email ?? this.email,
      codeSent: codeSent ?? this.codeSent,
      codeVerified: codeVerified ?? this.codeVerified,
    );
  }
}
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

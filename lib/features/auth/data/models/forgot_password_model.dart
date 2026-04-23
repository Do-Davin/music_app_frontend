class ForgotPasswordModel {
  final String email;
  final String message;
  final String code;
  final bool codeSent;
  final bool codeVerified;
  final bool passwordReset;

  const ForgotPasswordModel({
    required this.email,
    this.message = '',
    this.code = '',
    this.codeSent = false,
    this.codeVerified = false,
    this.passwordReset = false,
  });

  factory ForgotPasswordModel.fromSendResetCodeJson(Map<String, dynamic> json) {
    return ForgotPasswordModel(
      email: json['email'] as String,
      message: json['message'] as String? ?? 'Reset code sent to email',
      codeSent: true,
    );
  }

  factory ForgotPasswordModel.fromVerifyCodeJson(
    Map<String, dynamic> json, {
    required String email,
    required String code,
  }) {
    final isValid = json['valid'] as bool? ?? false;

    return ForgotPasswordModel(
      email: email,
      code: isValid ? code : '',
      message: json['message'] as String? ?? '',
      codeSent: true,
      codeVerified: isValid,
    );
  }

  factory ForgotPasswordModel.fromResetPasswordJson(
    Map<String, dynamic> json, {
    required String email,
    required String code,
  }) {
    final success = json['success'] as bool? ?? false;

    return ForgotPasswordModel(
      email: email,
      code: code,
      message: json['message'] as String? ?? '',
      codeSent: true,
      codeVerified: success,
      passwordReset: success,
    );
  }

  ForgotPasswordModel copyWith({
    String? email,
    String? message,
    String? code,
    bool? codeSent,
    bool? codeVerified,
    bool? passwordReset,
  }) {
    return ForgotPasswordModel(
      email: email ?? this.email,
      message: message ?? this.message,
      code: code ?? this.code,
      codeSent: codeSent ?? this.codeSent,
      codeVerified: codeVerified ?? this.codeVerified,
      passwordReset: passwordReset ?? this.passwordReset,
    );
  }
}

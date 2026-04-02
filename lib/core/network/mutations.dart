class AuthMutations {
  static const String login = '''
    mutation Login(\$email: String!, \$password: String!) {
      login(email: \$email, password: \$password) {
        token
        user {
          _id
          username
          email
          profileImageUrl
        }
      }
    }
  ''';

  static const String register = '''
    mutation Register(\$email: String!, \$password: String!) {
      register(email: \$email, password: \$password) {
        token
        user {
          _id
          username
          email
          profileImageUrl
        }
      }
    }
  ''';

  static const String forgotPassword = '''
    mutation ForgotPassword(\$email: String!) {
      forgotPassword(email: \$email) {
        message
        success
      }
    }
  ''';

  static const String verifyResetCode = '''
    mutation VerifyResetCode(\$email: String!, \$code: String!) {
      verifyResetCode(email: \$email, code: \$code) {
        message
        success
      }
    }
  ''';

  static const String resetPassword = '''
    mutation ResetPassword(\$email: String!, \$password: String!, \$code: String!) {
      resetPassword(email: \$email, password: \$password, code: \$code) {
        message
        success
      }
    }
  ''';
}

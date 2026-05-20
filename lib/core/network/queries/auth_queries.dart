class AuthMutations {
  static const String login = '''
    mutation Login(\$input: LoginInput!) {
      login(input: \$input) {
        accessToken
        refreshToken
        user {
          _id
          username
          email
          profileImageUrl
          practiceGoals {
            dailyMinutes
            weeklyDays
          }
          practiceStreak {
            currentStreak
            longestStreak
          }
        }
      }
    }
  ''';

  static const String register = '''
    mutation Register(\$input: RegisterInput!) {
      register(input: \$input) {
        accessToken
        refreshToken
        user {
          _id
          username
          email
          profileImageUrl
          practiceGoals {
            dailyMinutes
            weeklyDays
          }
          practiceStreak {
            currentStreak
            longestStreak
          }
        }
      }
    }
  ''';

  static const String sendResetCode = '''
    mutation SendResetCode(\$input: SendResetCodeInput!) {
      sendResetCode(input: \$input) {
        message
        email
      }
    }
  ''';

  static const String verifyCode = '''
    mutation VerifyCode(\$input: VerifyCodeInput!) {
      verifyCode(input: \$input) {
        valid
        message
      }
    }
  ''';

  static const String resetPassword = '''
    mutation ResetPassword(\$input: ResetPasswordInput!) {
      resetPassword(input: \$input) {
        success
        message
      }
    }
  ''';
}

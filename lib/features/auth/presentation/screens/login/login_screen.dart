import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/forgot_password/forgot_password_screen.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/register/register_screen.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _fullEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).state = true;
    }
  }

  void _onForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _onCreateAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),

                const AuthLogo(),

                const SizedBox(height: 20),

                Text(
                  'Start your music journey',
                  style: AppTextStyles.header,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 50),

                Text('Sign in to continue', style: AppTextStyles.body),

                const SizedBox(height: 30),

                AppTextField(
                  controller: _fullEmailController,
                  hint: 'Email',
                  prefixIcon: Icons.person_outline,
                ),

                const SizedBox(height: 20),

                AppPasswordField(
                  controller: _passwordController,
                  hint: 'Password',
                ),

                const SizedBox(height: 20),

                AppPrimaryButton(label: 'Sign In', onPressed: _onSignIn),

                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _onForgotPassword,
                  child: Text(
                    'Forgot Password?',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: _onCreateAccount,
                      child: Text(
                        'Create account',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

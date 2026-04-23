import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/providers/auth_provider.dart';
import 'package:music_app_frontend/features/auth/screens/forgot_password/forgot_password_screen.dart';
import 'package:music_app_frontend/features/auth/screens/register/register_screen.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _fullEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    FocusScope.of(context).unfocus();

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
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 100,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        const AuthLogo(),

                        const SizedBox(height: 28),

                        Text(
                          'Welcome back',
                          style: AppTextStyles.header.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Sign in to continue your music journey',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 15,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 36),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login',
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'Enter your email and password',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 24),

                              AppTextField(
                                controller: _fullEmailController,
                                hint: 'Email',
                                prefixIcon: Icons.email_outlined,
                              ),

                              const SizedBox(height: 18),

                              AppPasswordField(
                                controller: _passwordController,
                                hint: 'Password',
                              ),

                              const SizedBox(height: 14),

                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _onForgotPassword,
                                  child: Text(
                                    'Forgot Password?',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              AppPrimaryButton(
                                label: 'Sign In',
                                onPressed: _onSignIn,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            GestureDetector(
                              onTap: _onCreateAccount,
                              child: Text(
                                'Create account',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Text(
                            'Practice smarter. Play better.',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

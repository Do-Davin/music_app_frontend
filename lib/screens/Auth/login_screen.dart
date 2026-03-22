import 'package:flutter/material.dart';
import 'package:music_app_frontend/constants/app_colors.dart';
import 'package:music_app_frontend/constants/app_text_styles.dart';
import 'package:music_app_frontend/screens/Auth/ForgotPasswordGroup/forgotpassword_screen.dart';
import 'package:music_app_frontend/screens/Auth/register_screen.dart';
import 'package:music_app_frontend/widgets/app_text_field.dart';
import 'package:music_app_frontend/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formkey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    debugPrint('Sign In pressed');
    debugPrint('Full Name: ${_fullNameController.text}');
    debugPrint('Password: ${_passwordController.text}');
  }

  void _onForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  void _onCreateAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _onGoogleSignIn() {
    debugPrint('Google Sign In pressed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              _buildLogoSection(),

              const Spacer(flex: 1),
              _buildHeadlineSection(),
              
              const Spacer(flex: 1),
              _buildFormSection(),
              
              const Spacer(flex: 1),
              _buildDivider(),
              
              const SizedBox(height: 16),
              _buildGoogleSignIn(),
              
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Image.asset('assets/images/Logo.png', fit: BoxFit.contain),
    );
  }

  Widget _buildHeadlineSection() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Start your music journey\nWith ',
                style: AppTextStyles.header.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              TextSpan(
                text: 'VibeFLow',
                style: AppTextStyles.header.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your music journey starts here, Sign in to listen.',
          style: AppTextStyles.body.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppTextField(
          controller: _fullNameController,
          hint: 'Full name',
          prefixIcon: Icons.person_outline,
        ),

        const SizedBox(height: 12),

        AppPasswordField(controller: _passwordController, hint: 'Password'),

        const SizedBox(height: 16),

        AppPrimaryButton(label: 'Sign In', onPressed: _onSignIn),

        const SizedBox(height: 12),

        Center(
          child: GestureDetector(
            onTap: _onForgotPassword,
            child: Text(
              'Forgot Password?',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: AppTextStyles.body.copyWith(color: AppColors.onSurface),
            ),
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
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.primary.withOpacity(0.5),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.primary.withOpacity(0.5),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignIn() {
    return Center(
      child: GestureDetector(
        onTap: _onGoogleSignIn,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.onSurface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'assets/images/Google.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
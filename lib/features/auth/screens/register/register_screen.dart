import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/screens/login/login_screen.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onCreateAccount() {
    // TODO: Call API / auth service, then navigate to HomeScreen
    debugPrint('Create Account pressed');
    debugPrint('Email: ${_emailController.text}');
    debugPrint('Password: ${_passwordController.text}');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _onTermsTap() {
    // TODO: Open Terms page / URL
    debugPrint('Terms tapped');
  }

  void _onPrivacyPolicyTap() {
    // TODO: Open Privacy Policy page / URL
    debugPrint('Privacy Policy tapped');
  }

  void _onLoginTap() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    final double sectionGap = screenHeight * 0.03;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AuthLogo(height: 210),

                  _buildHeadlineSection(),

                  SizedBox(height: sectionGap),

                  _buildFormSection(),

                  SizedBox(height: sectionGap),

                  _buildTermsSection(),

                  const SizedBox(height: 14),

                  _buildLoginRow(),

                  SizedBox(height: sectionGap),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadlineSection() {
    return Column(
      children: [
        Text(
          'Create Your Account',
          style: AppTextStyles.header.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Fill in your details to get started with VibeFlow.',
          style: AppTextStyles.body.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _emailController,
          hint: 'Email Address',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 12),

        AppPasswordField(controller: _passwordController, hint: 'Password'),

        const SizedBox(height: 6),

        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Must be 8 + characters',
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(height: 12),

        AppPasswordField(
          controller: _confirmPasswordController,
          hint: 'Confirm Password',
        ),

        const SizedBox(height: 20),

        AppPrimaryButton(label: 'Create Account', onPressed: _onCreateAccount),
      ],
    );
  }

  Widget _buildTermsSection() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTextStyles.body.copyWith(color: AppColors.onSurface),
        children: [
          const TextSpan(text: 'By registering, you agree to our '),
          WidgetSpan(
            child: GestureDetector(
              onTap: _onTermsTap,
              child: Text(
                'Terms',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const TextSpan(text: ' and '),
          WidgetSpan(
            child: GestureDetector(
              onTap: _onPrivacyPolicyTap,
              child: Text(
                'Privacy Policy',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _buildLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTextStyles.body.copyWith(color: AppColors.onSurface),
        ),
        GestureDetector(
          onTap: _onLoginTap,
          child: Text(
            'Login',
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

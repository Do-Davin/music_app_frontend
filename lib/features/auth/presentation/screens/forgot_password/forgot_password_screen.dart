import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/forgot_password/verify_account_screen.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendResetCode() {
    // 1. Call API to send code to email  ← TODO
    // 2. On API success → navigate and pass the email forward
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerifyAccountScreen(email: _emailController.text),
      ),
    );
  }

  void _onBackToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double logoHeight = screenHeight * 0.25;
    final double sectionGap = screenHeight * 0.04;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: sectionGap),

                _buildLogoSection(logoHeight),

                SizedBox(height: sectionGap),

                _buildHeadlineSection(),

                SizedBox(height: sectionGap),

                AppTextField(
                  controller: _emailController,
                  hint: 'Email Address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: sectionGap * 0.8),

                AppPrimaryButton(
                  label: 'Send Reset Code',
                  onPressed: _onSendResetCode,
                ),

                SizedBox(height: sectionGap),

                GestureDetector(
                  onTap: _onBackToLogin,
                  child: Text(
                    'Back to login',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(double height) {
    return SizedBox(
      height: height,
      width: MediaQuery.of(context).size.width,
      child: Image.asset('assets/images/Logo.png', fit: BoxFit.fitWidth),
    );
  }

  Widget _buildHeadlineSection() {
    return Column(
      children: [
        Text(
          'Forgot Password',
          style: AppTextStyles.header.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          "No worries! Enter your registered email address.\nand we'll send you a secure link to create a new\npassword and get you back into the link flow.",
          style: AppTextStyles.body.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

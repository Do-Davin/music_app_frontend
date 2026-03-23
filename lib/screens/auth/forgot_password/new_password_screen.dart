import 'package:flutter/material.dart';
import 'package:music_app_frontend/constants/app_colors.dart';
import 'package:music_app_frontend/constants/app_text_styles.dart';
import 'package:music_app_frontend/widgets/widgets.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  final String email;

  const CreateNewPasswordScreen({super.key, required this.email});

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onResetPassword() {
    // TODO: Call API to reset password, then navigate on success
    debugPrint('Reset Password pressed');
    debugPrint('Email           : ${widget.email}');
    debugPrint('New Password    : ${_newPasswordController.text}');
    debugPrint('Confirm Password: ${_confirmPasswordController.text}');

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _onBackToLogin() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    final double sectionGap = screenHeight * 0.022;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5),

                _buildLogoSection(),

                SizedBox(height: 5),

                _buildHeadlineSection(),

                SizedBox(height: sectionGap),

                _buildLabel('Email Address'),
                const SizedBox(height: 8),
                _buildReadOnlyEmailField(),

                SizedBox(height: sectionGap),

                _buildLabel('New Password'),
                const SizedBox(height: 8),
                AppPasswordField(
                  controller: _newPasswordController,
                  hint: '######',
                ),

                SizedBox(height: sectionGap),

                _buildLabel('Confirm New Password'),
                const SizedBox(height: 8),
                AppPasswordField(
                  controller: _confirmPasswordController,
                  hint: '######',
                ),

                const SizedBox(height: 8),

                _buildHintBox(),

                SizedBox(height: sectionGap * 1.2),

                AppPrimaryButton(
                  label: 'Reset Password',
                  onPressed: _onResetPassword,
                ),

                SizedBox(height: sectionGap),

                Center(
                  child: GestureDetector(
                    onTap: _onBackToLogin,
                    child: Text(
                      'Back to login',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: sectionGap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Image.asset(
      'assets/images/Logo.png',
      height: 270,
    );
  }

  Widget _buildHeadlineSection() {
    return Column(
      children: [
        Text(
          'Create New Password',
          style: AppTextStyles.header.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your account has been verified. Please\nset a strong new password below.',
          style: AppTextStyles.body.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        color: AppColors.onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildReadOnlyEmailField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.email,
              style: AppTextStyles.body.copyWith(color: AppColors.onSurface),
            ),
          ),
          Icon(Icons.lock_outline, color: AppColors.primary, size: 18),
        ],
      ),
    );
  }

  Widget _buildHintBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Minimum 8 characters, at least one number and one symbol.',
        style: AppTextStyles.body.copyWith(
          color: AppColors.onSurface.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
    );
  }
}
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

    // ── Tighter values because this screen has more fields ────────────────
    final double logoHeight = screenHeight * 0.17;  // smaller logo
    final double sectionGap = screenHeight * 0.022; // tighter gaps

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // SingleChildScrollView = safety net on very small devices
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: sectionGap),

                // ── Logo ──────────────────────────────────────────────────
                _buildLogoSection(logoHeight),

                SizedBox(height: sectionGap),

                // ── Headline ──────────────────────────────────────────────
                _buildHeadlineSection(),

                SizedBox(height: sectionGap),

                // ── Email Address (read-only) ──────────────────────────────
                _buildLabel('Email Address'),
                const SizedBox(height: 8),
                _buildReadOnlyEmailField(),

                SizedBox(height: sectionGap),

                // ── New Password ───────────────────────────────────────────
                _buildLabel('New Password'),
                const SizedBox(height: 8),
                AppPasswordField(
                  controller: _newPasswordController,
                  hint: '######',
                ),

                SizedBox(height: sectionGap),

                // ── Confirm New Password ───────────────────────────────────
                _buildLabel('Confirm New Password'),
                const SizedBox(height: 8),
                AppPasswordField(
                  controller: _confirmPasswordController,
                  hint: '######',
                ),

                const SizedBox(height: 8),

                // ── Hint box ──────────────────────────────────────────────
                _buildHintBox(),

                SizedBox(height: sectionGap * 1.2),

                // ── Reset Password Button ─────────────────────────────────
                AppPrimaryButton(
                  label: 'Reset Password',
                  onPressed: _onResetPassword,
                ),

                SizedBox(height: sectionGap),

                // ── Back to Login ─────────────────────────────────────────
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
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
          color: AppColors.onSurface.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
    );
  }
}
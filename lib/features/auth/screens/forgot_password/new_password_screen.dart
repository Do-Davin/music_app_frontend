// ─────────────────────────────────────────────────────────────────────────────
// TIER 3 — PRESENTATION LAYER
// Path: lib/features/auth/presentation/screens/forgot_password/new_password_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/providers/forgotpassword_provider.dart';

import 'package:music_app_frontend/shared/widgets/widgets.dart';

class CreateNewPasswordScreen extends ConsumerStatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  ConsumerState<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState
    extends ConsumerState<CreateNewPasswordScreen> {
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

  Future<void> _onResetPassword() async {
    // ── Basic validation: check passwords match ────────────────────────────
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
      return;
    }

    // ── Call Tier 2 provider ───────────────────────────────────────────────
    await ref
        .read(forgotPasswordProvider.notifier)
        .resetPassword(_newPasswordController.text.trim());

    // ── Check state after API call ────────────────────────────────────────
    final state = ref.read(forgotPasswordProvider);

    if (!mounted) return;

    if (state.passwordReset) {
      // ── Success: clear state + go all the way back to LoginScreen ────────
      ref.read(forgotPasswordProvider.notifier).reset();
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _onBackToLogin() {
    ref.read(forgotPasswordProvider.notifier).reset(); // clear state
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // ── Watch Tier 2 provider ──────────────────────────────────────────────
    final forgotState = ref.watch(forgotPasswordProvider);

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
                const SizedBox(height: 5),

                const AuthLogo(),

                const SizedBox(height: 5),

                _buildHeadlineSection(),

                SizedBox(height: sectionGap),

                // ── Email label + read-only field ─────────────────────────
                _buildLabel('Email Address'),
                const SizedBox(height: 8),
                _buildReadOnlyEmailField(forgotState.email),

                SizedBox(height: sectionGap),

                // ── New Password ──────────────────────────────────────────
                _buildLabel('New Password'),
                const SizedBox(height: 8),
                AppPasswordField(
                  controller: _newPasswordController,
                  hint: '######',
                ),

                SizedBox(height: sectionGap),

                // ── Confirm New Password ──────────────────────────────────
                _buildLabel('Confirm New Password'),
                const SizedBox(height: 8),
                AppPasswordField(
                  controller: _confirmPasswordController,
                  hint: '######',
                ),

                const SizedBox(height: 8),

                _buildHintBox(),

                // ── Error message from API ────────────────────────────────
                if (forgotState.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    forgotState.errorMessage!,
                    style: AppTextStyles.body.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],

                SizedBox(height: sectionGap * 1.2),

                // ── Reset Password Button ─────────────────────────────────
                forgotState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : AppPrimaryButton(
                        label: 'Reset Password',
                        onPressed: _onResetPassword,
                      ),

                SizedBox(height: sectionGap),

                // ── Back to login ─────────────────────────────────────────
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

  // ── Read-only email field (email comes from provider state now) ────────────
  Widget _buildReadOnlyEmailField(String email) {
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
              email, // ← comes from provider state, not widget constructor
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

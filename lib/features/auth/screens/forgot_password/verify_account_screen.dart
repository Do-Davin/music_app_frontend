// ─────────────────────────────────────────────────────────────────────────────
// TIER 3 — PRESENTATION LAYER
// Path: lib/features/auth/presentation/screens/forgot_password/verify_account_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/providers/forgotpassword_provider.dart';
import 'package:music_app_frontend/features/auth/screens/forgot_password/new_password_screen.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

class VerifyAccountScreen extends ConsumerStatefulWidget {
  const VerifyAccountScreen({super.key});

  @override
  ConsumerState<VerifyAccountScreen> createState() =>
      _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends ConsumerState<VerifyAccountScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _onSubmitCode() async {
    // ── Call Tier 2 provider ───────────────────────────────────────────────
    await ref
        .read(forgotPasswordProvider.notifier)
        .verifyCode(_passcodeController.text.trim());

    // ── Check state after API call ────────────────────────────────────────
    final state = ref.read(forgotPasswordProvider);

    if (!mounted) return;

    if (state.codeVerified) {
      // ── Success: navigate to CreateNewPasswordScreen ──────────────────
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateNewPasswordScreen(),
        ),
      );
    }
  }

  Future<void> _onResendCode() async {
    // ── Call Tier 2 provider ───────────────────────────────────────────────
    await ref.read(forgotPasswordProvider.notifier).resendCode();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  const AuthLogo(),

                  const SizedBox(height: 15),

                  _buildHeadlineSection(),

                  SizedBox(height: sectionGap * 0.6),

                  // ── "Code sent successfully" banner ──────────────────────
                  if (forgotState.codeSent)
                    Center(
                      child: Text(
                        'Code send successfully.',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  SizedBox(height: sectionGap * 0.8),

                  // ── Email label + read-only field ─────────────────────────
                  _buildLabel('Email Address'),
                  const SizedBox(height: 8),
                  _buildReadOnlyEmailField(forgotState.email),

                  SizedBox(height: sectionGap * 0.6),

                  // ── Passcode field ────────────────────────────────────────
                  _buildLabel('Passcode'),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _passcodeController,
                    hint: '######',
                    prefixIcon: Icons.lock_outline,
                    keyboardType: TextInputType.number,
                  ),

                  // ── Error message from API ────────────────────────────────
                  if (forgotState.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      forgotState.errorMessage!,
                      style: AppTextStyles.body.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  SizedBox(height: sectionGap),

                  // ── Submit Code Button ────────────────────────────────────
                  forgotState.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : AppPrimaryButton(
                          label: 'Submit Code',
                          onPressed: _onSubmitCode,
                        ),

                  SizedBox(height: sectionGap * 0.8),

                  // ── Resend Code ───────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _onResendCode,
                      child: Text(
                        'Resend Code',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: sectionGap * 0.6),

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
      ),
    );
  }

  Widget _buildHeadlineSection() {
    return Column(
      children: [
        Text(
          'Verify Your Account',
          style: AppTextStyles.header.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          "We've sent a 6-digit verification code to the\nemail address below. Please enter it to verify\nyour ownership.",
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
}

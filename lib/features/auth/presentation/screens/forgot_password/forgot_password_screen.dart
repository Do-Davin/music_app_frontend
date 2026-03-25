// ─────────────────────────────────────────────────────────────────────────────
// TIER 3 — PRESENTATION LAYER
// Path: lib/features/auth/presentation/screens/forgot_password/forgot_password_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/forgotpassword_provider.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/forgot_password/verify_account_screen.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSendResetCode() async {
    // ── Call Tier 2 provider ───────────────────────────────────────────────
    await ref
        .read(forgotPasswordProvider.notifier)
        .sendResetCode(_emailController.text.trim());

    // ── Check state after API call ────────────────────────────────────────
    final state = ref.read(forgotPasswordProvider);

    if (!mounted) return;

    if (state.codeSent) {
      // ── Success: navigate to VerifyAccountScreen ──────────────────────
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VerifyAccountScreen(),
        ),
      );
    }
  }

  void _onBackToLogin() {
    ref.read(forgotPasswordProvider.notifier).reset(); // clear state
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // ── Watch Tier 2 provider ──────────────────────────────────────────────
    final forgotState = ref.watch(forgotPasswordProvider);

    final double screenHeight = MediaQuery.of(context).size.height;
    final double sectionGap = screenHeight * 0.04;

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
                  SizedBox(height: sectionGap),

                  const AuthLogo(),

                  SizedBox(height: sectionGap),

                  _buildHeadlineSection(),

                  SizedBox(height: sectionGap),

                  // ── Email field ──────────────────────────────────────────
                  AppTextField(
                    controller: _emailController,
                    hint: 'Email Address',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  // ── Error message from API ───────────────────────────────
                  if (forgotState.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      forgotState.errorMessage!,
                      style: AppTextStyles.body.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  SizedBox(height: sectionGap * 0.8),

                  // ── Send Reset Code Button ───────────────────────────────
                  // Shows loading spinner while API is running
                  forgotState.isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.primary)
                      : AppPrimaryButton(
                          label: 'Send Reset Code',
                          onPressed: _onSendResetCode,
                        ),

                  SizedBox(height: sectionGap),

                  // ── Back to login ────────────────────────────────────────
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
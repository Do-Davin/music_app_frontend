import 'package:flutter/material.dart';
import 'package:music_app_frontend/constants/app_colors.dart';
import 'package:music_app_frontend/constants/app_text_styles.dart';
import 'package:music_app_frontend/screens/Auth/ForgotPasswordGroup/newpassword_screen.dart';
import 'package:music_app_frontend/widgets/widgets.dart';

class VerifyAccountScreen extends StatefulWidget {
  /// The email passed from ForgotPasswordScreen
  final String email;

  const VerifyAccountScreen({super.key, required this.email});

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _codeSentSuccess = true;

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  // ── Submit Code → navigate to CreateNewPasswordScreen ─────────────────────
  void _onSubmitCode() {
    // TODO: Call verify API with widget.email + _passcodeController.text
    // On success → navigate to CreateNewPasswordScreen
    debugPrint('Submit Code pressed');
    debugPrint('Email    : ${widget.email}');
    debugPrint('Passcode : ${_passcodeController.text}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNewPasswordScreen(
          email: widget.email, // ← pass email forward
        ),
      ),
    );
  }

  void _onResendCode() {
    // TODO: Call resend-code API
    setState(() => _codeSentSuccess = true);
    debugPrint('Resend Code pressed');
  }

  void _onBackToLogin() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double logoHeight = screenHeight * 0.22;
    final double sectionGap = screenHeight * 0.03;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
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

                SizedBox(height: sectionGap * 0.6),

                // ── "Code send successfully." ─────────────────────────────
                if (_codeSentSuccess) _buildSuccessBanner(),

                SizedBox(height: sectionGap * 0.8),

                // ── Email Address (read-only) ──────────────────────────────
                _buildLabel('Email Address'),
                const SizedBox(height: 8),
                _buildReadOnlyEmailField(),

                SizedBox(height: sectionGap * 0.6),

                // ── Passcode ──────────────────────────────────────────────
                _buildLabel('Passcode'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _passcodeController,
                  hint: '######',
                  prefixIcon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                ),

                SizedBox(height: sectionGap),

                // ── Submit Code Button ────────────────────────────────────
                AppPrimaryButton(
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

  Widget _buildSuccessBanner() {
    return Center(
      child: Text(
        'Code send successfully.',
        style: AppTextStyles.body.copyWith(
          color: Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
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
}
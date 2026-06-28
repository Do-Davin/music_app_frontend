import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/forgot_password_provider.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

class VerifyAccountScreen extends ConsumerStatefulWidget {
  const VerifyAccountScreen({super.key});

  @override
  ConsumerState<VerifyAccountScreen> createState() =>
      _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends ConsumerState<VerifyAccountScreen> {
  final TextEditingController _passcodeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Timer? _timer;
  int _secondsRemaining = 60; // 1 minute

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _onSubmitCode() async {
    FocusScope.of(context).unfocus();

    if (_secondsRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The verification code has expired. Please request a new code.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(forgotPasswordProvider.notifier)
        .verifyCode(_passcodeController.text.trim());

    final state = ref.read(forgotPasswordProvider);

    if (!mounted) return;

    if (state.codeVerified) {
      _timer?.cancel();
      context.push(Routes.newPassword);
    }
  }

  Future<void> _onResendCode() async {
    if (_secondsRemaining > 0) return;
    await ref.read(forgotPasswordProvider.notifier).resendCode();
    _startTimer();
  }

  void _onBackToLogin() {
    ref.read(forgotPasswordProvider.notifier).reset();
    context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final forgotState = ref.watch(forgotPasswordProvider);
    //final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            // duration: const Duration(milliseconds: 200),
            // curve: Curves.easeOut,
            // padding: EdgeInsets.only(bottom: bottomInset),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      const AuthLogo(),

                      const SizedBox(height: 28),

                      Text(
                        'Verify your account',
                        style: AppTextStyles.header.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Enter the 6-digit code sent to your email',
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
                              'Verification Code',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Check your inbox and enter the code below',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  color: _secondsRemaining > 0
                                      ? AppColors.primary
                                      : Colors.redAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _secondsRemaining > 0
                                      ? 'Code expires in: ${_formatTime(_secondsRemaining)}'
                                      : 'Verification code expired',
                                  style: AppTextStyles.body.copyWith(
                                    color: _secondsRemaining > 0
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            if (forgotState.codeSent) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.30),
                                  ),
                                ),
                                child: Text(
                                  'Code sent successfully.',
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            Text(
                              'Email Address',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            _buildReadOnlyEmailField(forgotState.email),

                            const SizedBox(height: 18),

                            Text(
                              'Passcode',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            AppTextField(
                              controller: _passcodeController,
                              hint: '######',
                              prefixIcon: Icons.lock_outline,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter the verification code';
                                }
                                if (value.trim().length != 6) {
                                  return 'Code must be 6 digits';
                                }
                                return null;
                              },
                            ),

                            if (forgotState.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                forgotState.errorMessage!,
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

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
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      GestureDetector(
                        onTap: _secondsRemaining > 0 ? null : _onResendCode,
                        child: Text(
                          'Resend Code',
                          style: AppTextStyles.body.copyWith(
                            color: _secondsRemaining > 0
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: _secondsRemaining > 0
                                ? TextDecoration.none
                                : TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      GestureDetector(
                        onTap: _onBackToLogin,
                        child: Text(
                          'Back',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        'Practice smarter. Play better.',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
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
    );
  }

  Widget _buildReadOnlyEmailField(String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              email.isEmpty ? 'No email found' : email,
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          Icon(
            Icons.verified_user_outlined,
            color: AppColors.primary,
            size: 18,
          ),
        ],
      ),
    );
  }
}

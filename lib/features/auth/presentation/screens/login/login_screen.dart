import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _fullEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Timer? _lockoutTimer;
  
  // Maps normalized email to the DateTime when its lockout expires.
  final Map<String, DateTime> _lockouts = {};

  @override
  void initState() {
    super.initState();
    _fullEmailController.addListener(_onEmailChanged);
  }

  bool _wasLockedOut = false;

  void _onEmailChanged() {
    final isNowLocked = _isLockedOut;
    // Only rebuild the UI if the locked out state actually changes for the currently typed email
    if (_wasLockedOut != isNowLocked) {
      setState(() {
        _wasLockedOut = isNowLocked;
      });
    }
  }

  @override
  void dispose() {
    _fullEmailController.removeListener(_onEmailChanged);
    _lockoutTimer?.cancel();
    _fullEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startLockoutTimer(int seconds, String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return;

    setState(() {
      _lockouts[normalizedEmail] = DateTime.now().add(Duration(seconds: seconds));
    });

    // Start a single periodic timer if not already running to tick down all active lockouts
    if (_lockoutTimer == null || !_lockoutTimer!.isActive) {
      _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        
        // Remove expired lockouts
        _lockouts.removeWhere((email, expiry) => now.isAfter(expiry));

        if (_lockouts.isEmpty) {
          timer.cancel();
          _lockoutTimer = null;
        }

        // Trigger rebuild to update countdown text in UI
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  String _formatLockoutTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  int get _lockoutSecondsRemaining {
    final currentEmail = _fullEmailController.text.trim().toLowerCase();
    if (!_lockouts.containsKey(currentEmail)) return 0;
    final expiry = _lockouts[currentEmail]!;
    final diff = expiry.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  bool get _isLockedOut => _lockoutSecondsRemaining > 0;

  void _onSignIn() {
    FocusScope.of(context).unfocus();

    if (_isLockedOut) return;

    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .login(
            email: _fullEmailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    }
  }

  void _onForgotPassword() {
    context.push(Routes.forgotPassword);
  }

  void _onCreateAccount() {
    context.push(Routes.register);
  }

  /// Try to parse lockoutSeconds from the error message returned by the backend.
  int? _parseLockoutSeconds(String errorMessage) {
    try {
      final decoded = jsonDecode(errorMessage) as Map<String, dynamic>;
      return decoded['lockoutSeconds'] as int?;
    } catch (_) {
      return null;
    }
  }

  /// Clean the error message for display by removing JSON.
  String _cleanErrorMessage(String errorMessage) {
    try {
      final decoded = jsonDecode(errorMessage) as Map<String, dynamic>;
      return decoded['message'] as String? ?? errorMessage;
    } catch (_) {
      return errorMessage;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!mounted) return;

      final previousError = previous?.errorMessage;
      final nextError = next.errorMessage;
      final becameAuthenticated =
          next.isAuthenticated && !(previous?.isAuthenticated ?? false);

      if (nextError != null && nextError != previousError) {
        // Clear the password field so the user can re-enter
        _passwordController.clear();
        // Check if it contains lockout info
        final lockoutSeconds = _parseLockoutSeconds(nextError);
        if (lockoutSeconds != null && lockoutSeconds > 0) {
          _startLockoutTimer(lockoutSeconds, _fullEmailController.text);
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(_cleanErrorMessage(nextError))),
          );
      }

      if (becameAuthenticated) {
        context.go(Routes.root);
      }
    });

    final authState = ref.watch(authProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 100,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      const AuthLogo(),

                      const SizedBox(height: 28),

                      Text(
                        'Welcome back',
                        style: AppTextStyles.header.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Sign in to continue your music journey',
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
                              'Login',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Enter your email and password',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 24),

                            AppTextField(
                              controller: _fullEmailController,
                              hint: 'Email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                                ).hasMatch(value.trim())) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            AppPasswordField(
                              controller: _passwordController,
                              hint: 'Password',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _onForgotPassword,
                                child: Text(
                                  'Forgot Password?',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                            // Lockout countdown banner
                            if (_isLockedOut) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.30,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_clock,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Account locked. Try again in ${_formatLockoutTime(_lockoutSecondsRemaining)}',
                                        style: AppTextStyles.body.copyWith(
                                          color: Colors.redAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            AppPrimaryButton(
                              label: _isLockedOut
                                  ? 'Locked (${_formatLockoutTime(_lockoutSecondsRemaining)})'
                                  : 'Sign In',
                              isLoading: authState.isLoading,
                              onPressed: _isLockedOut ? null : _onSignIn,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                          GestureDetector(
                            onTap: _onCreateAccount,
                            child: Text(
                              'Create account',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Text(
                          'Practice smarter. Play better.',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
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
}

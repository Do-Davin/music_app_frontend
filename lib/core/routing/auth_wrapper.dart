import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/login/login_screen.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:music_app_frontend/features/onboarding/providers/shared_prefs_provider.dart';
import 'package:music_app_frontend/features/onboarding/providers/splash_provider.dart';

import 'package:music_app_frontend/features/home/screens/main_screen.dart';
import 'package:music_app_frontend/features/onboarding/screens/splash_screen.dart';
import 'package:music_app_frontend/features/onboarding/screens/onboarding_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSplashFinished = ref.watch(splashFinishedProvider);
    final isFirstLaunch = ref.watch(isFirstLaunchProvider);
    final authState = ref.watch(authProvider);

    final Widget child;
    if (!isSplashFinished) {
      child = const SplashScreen(key: ValueKey('splash'));
    } else if (isFirstLaunch) {
      child = const OnboardingScreen(key: ValueKey('onboarding'));
    } else if (authState.isValidatingSession) {
      child = const SplashScreen(key: ValueKey('splash'));
    } else if (authState.isAuthenticated) {
      child = const MainScreen(key: ValueKey('main'));
    } else {
      child = const LoginScreen(key: ValueKey('login'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: child,
    );
  }
}

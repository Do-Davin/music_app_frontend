import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/auth/providers/auth_provider.dart';
import 'package:music_app_frontend/features/onboarding/providers/shared_prefs_provider.dart';
import 'package:music_app_frontend/features/onboarding/providers/splash_provider.dart';
import 'package:music_app_frontend/features/auth/screens/login/login_screen.dart';
import 'package:music_app_frontend/features/home/screens/main_screen.dart';
import 'package:music_app_frontend/features/onboarding/screens/splash_screen.dart';
import 'package:music_app_frontend/features/onboarding/screens/onboarding_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSplashFinished = ref.watch(splashFinishedProvider);
    if (!isSplashFinished) {
      return const SplashScreen();
    }

    final isFirstLaunch = ref.watch(isFirstLaunchProvider);
    if (isFirstLaunch) {
      return const OnboardingScreen();
    }

    final isLoggedIn = ref.watch(authProvider);
    return isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}

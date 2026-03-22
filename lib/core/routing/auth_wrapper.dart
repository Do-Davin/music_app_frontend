import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/auth/data/auth_provider.dart';
import 'package:music_app_frontend/features/onboarding/data/shared_prefs_provider.dart';
import 'package:music_app_frontend/features/onboarding/data/splash_provider.dart';
import 'package:music_app_frontend/features/auth/presentation/login/login_screen.dart';
import 'package:music_app_frontend/features/home/presentation/main_screen.dart';
import 'package:music_app_frontend/features/onboarding/presentation/splash_screen.dart';
import 'package:music_app_frontend/features/onboarding/presentation/onboarding_screen.dart';

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

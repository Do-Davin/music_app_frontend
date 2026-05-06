import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/config/app_config.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/routing/auth_wrapper.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/forgot_password/forgot_password_screen.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/forgot_password/new_password_screen.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/forgot_password/verify_account_screen.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/login/login_screen.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/register/register_screen.dart';
import 'package:music_app_frontend/features/home/screens/main_screen.dart';
import 'package:music_app_frontend/features/onboarding/screens/onboarding_screen.dart';
import 'package:music_app_frontend/features/playlist/screens/no_playlists_screen.dart';
import 'package:music_app_frontend/features/playlist/screens/liked_songs_screen.dart';
import 'package:music_app_frontend/features/song/screens/no_results_screen.dart';
import 'package:music_app_frontend/features/onboarding/screens/splash_screen.dart';
import 'package:music_app_frontend/shared/screens/stateless_status_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app_frontend/features/onboarding/providers/shared_prefs_provider.dart';
import 'package:music_app_frontend/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: AppTheme.dark,
      home: const AuthWrapper(),
      routes: {
        Routes.splash: (_) => const SplashScreen(),
        Routes.onboarding: (_) => const OnboardingScreen(),
        Routes.main: (_) => const MainScreen(),
        Routes.login: (_) => const LoginScreen(),
        Routes.register: (_) => const RegisterScreen(),
        Routes.forgotPassword: (_) => const ForgotPasswordScreen(),
        Routes.verifyAccount: (_) => const VerifyAccountScreen(),
        Routes.newPassword: (_) => const CreateNewPasswordScreen(),
        Routes.status: (_) => const StatelessStatusScreen(
          icon: Icons.signal_wifi_off,
          appBarTitle: 'Library',
          title: 'No Internet Connection',
          subtitle:
              'You\'re offline. Some content may not be available. Check your connection and try again.',
          iconColor: AppColors.error, // red for error
          iconBackgroundColor: Color(0x33FF5252), // transparent red bg
          highlightWord: 'Internet',
        ),
        Routes.noPlaylists: (_) => const NoPlaylistsScreen(),
        Routes.noResults: (_) => const NoResultsScreen(),
        Routes.likedSongs: (_) => const LikedSongsScreen(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/config/app_config.dart';
import 'package:music_app_frontend/core/config/routes.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/routing/auth_wrapper.dart';
import 'package:music_app_frontend/features/home/presentation/screens/main_screen.dart';
import 'package:music_app_frontend/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:music_app_frontend/features/playlist/presentation/screens/no_playlists_screen.dart';
import 'package:music_app_frontend/features/song/presentation/screens/no_results_screen.dart';
import 'package:music_app_frontend/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:music_app_frontend/shared/screens/stateless_status_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app_frontend/features/onboarding/presentation/providers/shared_prefs_provider.dart';
import 'package:music_app_frontend/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  await sharedPreferences
      .clear(); // Temporarily for development REMOVE After launch App

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
      },
    );
  }
}

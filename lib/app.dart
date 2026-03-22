import 'package:flutter/material.dart';
import 'package:music_app_frontend/config/routes.dart';
import 'package:music_app_frontend/config/app_config.dart';
import 'package:music_app_frontend/screens/main_screen.dart';
import 'package:music_app_frontend/screens/onboarding_screen.dart';
import 'package:music_app_frontend/screens/splash_screen.dart';
import 'package:music_app_frontend/screens/stateless_status_screen.dart';
import 'package:music_app_frontend/theme/app_theme.dart';
import 'package:music_app_frontend/constants/app_colors.dart';
import 'package:music_app_frontend/screens/playlists/no_playlists_screen.dart';
import 'package:music_app_frontend/screens/songs/no_results_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: AppTheme.dark,
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (_) => const SplashScreen(),
        Routes.onboarding: (_) => const OnboardingScreen(),
        Routes.main: (_) => const MainScreen(),

        // lib/app.dart  (only the Routes.status entry changes)
        Routes.status: (_) => const StatelessStatusScreen(
          icon: Icons.signal_wifi_off,
          appBarTitle: 'Library', // NEW
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:music_app_frontend/config/app_config.dart';
import 'package:music_app_frontend/config/routes.dart';
import 'package:music_app_frontend/constants/app_colors.dart';
import 'package:music_app_frontend/constants/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: AppConfig.onboardingDurationSeconds), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.onboarding);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.music_note,
                size: 64,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ChordCraft',
              style: AppTextStyles.header.copyWith(
                fontSize: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text('Your music, your way', style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}

// lib/screens/songs/no_results_screen.dart

import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/shared/screens/stateless_status_screen.dart';

class NoResultsScreen extends StatelessWidget {
  const NoResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StatelessStatusScreen(
      appBarTitle: 'Search',
      icon: Icons.search,
      // Blue magnifier to match Figma
      iconColor: Color(0xFF2196F3),
      iconBackgroundColor: AppColors.statusIconBrown,
      title: 'No Results Found',
      highlightWord: 'Results',
      badge: '0 results found',
      subtitle:
          "We couldn't find any songs, chords, or artists matching your search. Try different keywords.",
    );
  }
}

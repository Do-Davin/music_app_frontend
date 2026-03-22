// lib/screens/playlists/no_playlists_screen.dart

import 'package:flutter/material.dart';
import 'package:music_app_frontend/constants/app_colors.dart';
import 'package:music_app_frontend/screens/stateless_status_screen.dart';

class NoPlaylistsScreen extends StatelessWidget {
  const NoPlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StatelessStatusScreen(
      appBarTitle: 'My Playlists',
      icon: Icons.music_note,
      // Purple to match Figma's purple music note
      iconColor: Color(0xFF9C27B0),
      iconBackgroundColor: AppColors.statusIconBrown,
      title: 'No Playlists Yet',
      highlightWord: 'Playlists',
      subtitle:
          'Create your own playlist to start organizing your music for practice or performance',
    );
  }
}

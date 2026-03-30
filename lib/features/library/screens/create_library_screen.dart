import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';

class CreateLibrarySheet extends StatelessWidget {
  const CreateLibrarySheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Background matches app surface color, not transparent/default
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              // withValues() instead of deprecated withOpacity()
              color: Colors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 30),

          _buildActionItem(
            icon: Icons.music_note,
            iconColor: AppColors.primary, // orange from AppColors
            title: 'Playlist',
            subtitle: 'Create a playlist with a song',
          ),
          _buildActionItem(
            icon: Icons.people_outline,
            iconColor: AppColors.warning, // amber/yellow from AppColors
            title: 'Collaborative playlist',
            subtitle: 'Create a playlist together',
          ),
          _buildActionItem(
            icon: Icons.bolt,
            iconColor: Colors
                .purpleAccent, // purple has no AppColors equivalent, kept as is
            title: 'Jam',
            subtitle: 'Listen together from anywhere',
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            // Surface color instead of hardcoded Colors.white10
            backgroundColor: AppColors.surface,
            child: Icon(icon, color: iconColor),
          ),

          const SizedBox(width: 15),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AppTextStyles instead of hardcoded TextStyle
              Text(
                title,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: AppTextStyles.body.copyWith(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

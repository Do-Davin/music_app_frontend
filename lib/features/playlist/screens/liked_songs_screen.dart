import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/core/constants/mock_data.dart';

class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final songs = MockData.likedSongs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        title: Text(
          'Liked Songs',
          style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: songs.length,
        separatorBuilder: (_, __) => Divider(
          color: Colors.white.withValues(alpha: 0.10),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final song = songs[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                song.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              song.title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              song.artist,
              style: AppTextStyles.body.copyWith(
                color: AppColors.hint,
                fontSize: 13,
              ),
            ),
            trailing: const Icon(Icons.more_vert, color: AppColors.hint),
          );
        },
      ),
    );
  }
}


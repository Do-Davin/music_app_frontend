import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/playlist/services/liked_songs_service.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/shared/widgets/app_empty_state_widget.dart';

class LikedSongsScreen extends StatelessWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final future = LikedSongsService().fetchLikedSongs();

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
      body: FutureBuilder<List<Song>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return AppEmptyStateWidget(
              icon: Icons.favorite_border_rounded,
              title: 'Could not load Liked Songs',
              subtitle: 'Please login and try again.',
              iconColor: AppColors.primary,
            );
          }

          final songs = snapshot.data ?? [];
          if (songs.isEmpty) {
            return AppEmptyStateWidget(
              icon: Icons.favorite_border_rounded,
              title: 'No liked songs yet',
              subtitle: 'Like some songs and they will show up here.',
              iconColor: AppColors.primary,
            );
          }

          return ListView.separated(
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
                    song.coverImageUrl ?? '',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: AppColors.hint,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  song.title,
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
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
          );
        },
      ),
    );
  }
}


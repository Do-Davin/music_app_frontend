import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/playlist/services/liked_songs_service.dart';
import 'package:music_app_frontend/shared/widgets/app_empty_state_widget.dart';
import 'package:music_app_frontend/features/playlist/screens/playlist_detail_screen.dart';

class LikedSongsScreen extends ConsumerWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = LikedSongsService().fetchLikedSongsPlaylist();

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
      body: FutureBuilder<LikedSongsPlaylistResponse>(
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

          final songs = snapshot.data?.songs ?? [];
          final playlist = snapshot.data?.playlist;
          if (songs.isEmpty || playlist == null) {
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
            separatorBuilder: (context, index) => Divider(
              color: Colors.white.withValues(alpha: 0.10),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final song = songs[index];
              return SongTile(
                song: song,
                index: index,
                playlist: playlist,
                isPlaylistOwner: true,
              );
            },
          );
        },
      ),
    );
  }
}

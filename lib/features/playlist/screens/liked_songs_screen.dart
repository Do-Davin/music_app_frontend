import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/core/routing/app_router.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/playlist/services/liked_songs_service.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/providers/song_provider.dart';

class LikedSongsScreen extends ConsumerStatefulWidget {
  const LikedSongsScreen({super.key});

  @override
  ConsumerState<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends ConsumerState<LikedSongsScreen> {
  /// Tracks which song IDs currently have an in-progress unlike mutation.
  final Set<String> _unlikingIds = {};

  Future<void> _unlike(Song song) async {
    if (_unlikingIds.contains(song.id)) return;

    setState(() => _unlikingIds.add(song.id));

    try {
      final service = ref.read(likedSongsServiceProvider);
      await service.toggleLikeSong(song.id);

      // Refresh the screen's data source and Home's liked-songs section.
      ref.invalidate(likedSongsProvider);
      ref.read(myPlaylistsProvider.notifier).refreshPlaylists();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _unlikingIds.remove(song.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final likedSongsAsync = ref.watch(likedSongsProvider);

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
      body: likedSongsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => _buildError(error),
        data: (songs) => songs.isEmpty ? _buildEmpty() : _buildSongList(songs),
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load Liked Songs',
              style: AppTextStyles.subtitle.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().replaceAll('Exception: ', ''),
              style: AppTextStyles.body.copyWith(
                color: AppColors.hint,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.invalidate(likedSongsProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No liked songs yet',
              style: AppTextStyles.subtitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Songs you like will appear here.\nTap the heart on any song to save it.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.hint,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList(List<Song> songs) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(likedSongsProvider),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: songs.length,
        separatorBuilder: (context, index) =>
            Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
        itemBuilder: (context, index) {
          final song = songs[index];
          return _buildSongTile(song);
        },
      ),
    );
  }

  Widget _buildSongTile(Song song) {
    final isUnliking = _unlikingIds.contains(song.id);
    final bool hasImage =
        song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surface,
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(song.coverImageUrl!),
                  fit: BoxFit.cover,
                  onError: (e, st) {},
                )
              : null,
        ),
        child: !hasImage
            ? const Icon(Icons.music_note, color: AppColors.hint, size: 24)
            : null,
      ),
      title: Text(
        song.title,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (song.isYoutube)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.smart_display,
                color: Color(0xFFFF0000),
                size: 13,
              ),
            ),
          Expanded(
            child: Text(
              song.artist,
              style: AppTextStyles.body.copyWith(
                color: AppColors.hint,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: SizedBox(
        width: 36,
        height: 36,
        child: isUnliking
            ? const Padding(
                padding: EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              )
            : IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.error,
                  size: 22,
                ),
                tooltip: 'Unlike',
                onPressed: () => _unlike(song),
              ),
      ),
      onTap: () {
        context.push(
          Routes.songById(song.id),
          extra: SongPlayerRouteData(song: song, category: 'Liked Songs'),
        );
      },
    );
  }
}

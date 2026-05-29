import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/core/routing/app_router.dart';
import 'package:music_app_frontend/shared/widgets/favorite_icon_button.dart';
import 'package:go_router/go_router.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistByIdProvider(playlistId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: playlistAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load playlist', style: AppTextStyles.body),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(playlistByIdProvider(playlistId)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (playlist) => _PlaylistDetailContent(playlist: playlist),
      ),
    );
  }
}

class _PlaylistDetailContent extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistDetailContent({required this.playlist});

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  int get _totalDuration {
    return playlist.songs?.fold<int>(0, (sum, s) => sum + (s.duration ?? 0)) ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    final songs = playlist.songs ?? [];
    final songCount = songs.length;

    return CustomScrollView(
      slivers: [
        // ── Sliver App Bar with playlist art ──────────────────────────────
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Cover art or gradient placeholder
                if (playlist.coverImageUrl != null &&
                    playlist.coverImageUrl!.isNotEmpty)
                  Image.network(
                    playlist.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildGradientPlaceholder(),
                  )
                else
                  _buildGradientPlaceholder(),
                // Gradient overlay so text is readable
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.9),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Playlist info header ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  style: AppTextStyles.header.copyWith(fontSize: 26),
                ),
                if (playlist.description != null &&
                    playlist.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    playlist.description!,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.hint,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.music_note,
                      color: AppColors.hint,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$songCount song${songCount != 1 ? 's' : ''}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.hint,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.access_time,
                      color: AppColors.hint,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_totalDuration),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.hint,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (playlist.isPublic)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Public',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Play all button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: songs.isEmpty ? null : () {},
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Songs',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // ── Song list ─────────────────────────────────────────────────────
        songs.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.queue_music, color: AppColors.hint, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'No songs yet',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.hint,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = songs[index];
                  return _SongTile(song: song, index: index);
                }, childCount: songs.length),
              ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  Widget _buildGradientPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3A2000), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.library_music, color: AppColors.primary, size: 80),
      ),
    );
  }
}

class _SongTile extends ConsumerWidget {
  final Song song;
  final int index;

  const _SongTile({required this.song, required this.index});

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasImage =
        song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
        width: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                _formatDuration(song.duration),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.hint,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FavoriteIconButton(
              songId: song.id,
              initialIsFavorite: song.isFavorite,
              iconSize: 20,
              onToggle: () {
                // Could refresh playlist here if needed, or just let the UI update
                // since the heart icon state changes immediately
              },
            ),
          ],
        ),
      ),
      onTap: () {
        context.push(
          Routes.songById(song.id),
          extra: SongPlayerRouteData(song: song, category: 'PLAYLIST'),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart';

/// "My Playlists" section with title row, amber + button, and a dark card list.
///
/// All data is provided/controlled by the caller — this widget is purely
/// presentational so the screen can keep reusing the existing
/// [myPlaylistsProvider] and dialog flow.
class ProfilePlaylistsSection extends StatelessWidget {
  const ProfilePlaylistsSection({
    super.key,
    required this.playlists,
    required this.onCreate,
    required this.onOpen,
    required this.onDelete,
    this.isLoading = false,
    this.errorWidget,
  });

  final List<Playlist> playlists;
  final VoidCallback onCreate;
  final ValueChanged<Playlist> onOpen;
  final ValueChanged<Playlist> onDelete;
  final bool isLoading;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(onCreate: onCreate),
        const SizedBox(height: 12),
        if (errorWidget != null)
          errorWidget!
        else if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          )
        else if (playlists.isEmpty)
          _EmptyState(onCreate: onCreate)
        else
          Column(
            children: [
              for (final p in playlists)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlaylistRow(
                    playlist: p,
                    onTap: () => onOpen(p),
                    onDelete: () => onDelete(p),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'My Playlists',
          style: AppTextStyles.subtitle.copyWith(
            color: AppColors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Material(
          color: AppColors.primary.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Create Playlist',
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: onCreate,
          ),
        ),
      ],
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({
    required this.playlist,
    required this.onTap,
    required this.onDelete,
  });

  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  int get _songCount =>
      playlist.songs?.length ?? playlist.songIds?.length ?? 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              _Thumbnail(coverImageUrl: playlist.coverImageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      playlist.name,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_songCount song${_songCount == 1 ? '' : 's'}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.hint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                iconSize: 20,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.hint,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.coverImageUrl});

  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    final hasUrl = coverImageUrl != null && coverImageUrl!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: hasUrl
          ? Image.network(
              coverImageUrl!,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _ThumbnailPlaceholder(),
            )
          : const _ThumbnailPlaceholder(),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.queue_music,
        color: AppColors.primary,
        size: 26,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.library_music_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No playlists yet',
            style: AppTextStyles.body.copyWith(
              color: AppColors.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first playlist to organize your practice.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onCreate,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Create playlist',
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

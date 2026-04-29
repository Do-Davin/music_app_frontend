import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/core/routing/navigation_provider.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:music_app_frontend/features/profile/models/profile_model.dart';
import 'package:music_app_frontend/features/profile/providers/profile_provider.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileState.when(
          // ── LOADING: show spinner while API is running ─────────────────
          loading: () => const ProfileSkeletonLoader(),

          // ── ERROR: show error widget if API fails ──────────────────────
          error: (error, _) => AppErrorWidget(
            message: 'Failed to load profile. Please try again.',
            retryButtonText: 'Retry',
            onRetry: () => ref.read(profileProvider.notifier).fetchProfile(),
          ),

          // ── DATA: show profile content when loaded ─────────────────────
          data: (profile) => _ProfileContent(profile: profile),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final ProfileModel profile;
  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _buildProfileHeader(),
          const SizedBox(height: 20),
          _buildProfileActions(context, ref),
          const SizedBox(height: 32),
          _buildPlaylistsSection(context, ref),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: CircleAvatar(
            radius: 64,
            backgroundColor: AppColors.surface,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? const Icon(Icons.person, size: 64, color: AppColors.primary)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.name,
          style: AppTextStyles.header.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          style: AppTextStyles.body.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${profile.followers} Followers , ${profile.following} Following',
          style: AppTextStyles.body.copyWith(color: AppColors.onSurface),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileActions(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => debugPrint('Edit Profile pressed'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Edit profile',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, Routes.practiceSession),
            icon: const Icon(Icons.fitness_center, color: AppColors.primary),
            label: Text(
              'Practice sessions',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context: context,
                title: 'Log Out',
                message: 'Are you sure you want to log out of your account?',
                confirmText: 'Log Out',
                cancelText: 'Cancel',
              );

              if (!confirmed) return;

              await ref.read(authProvider.notifier).logout();
              ref.read(navigationIndexProvider.notifier).state = 0;
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Log out',
              style: AppTextStyles.body.copyWith(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Playlists',
          style: AppTextStyles.header.copyWith(
            color: AppColors.onSurface,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 16),

        // ── EMPTY STATE: shown when playlist list is empty ───────────────
        if (profile.playlists.isEmpty)
          AppEmptyStateWidget(
            icon: Icons.queue_music,
            title: 'No Playlists Yet',
            subtitle: 'Create a playlist to organize your music',
            buttonLabel: 'Create Playlist',
            onButtonPressed: () => debugPrint('Create playlist tapped'),
          )
        else
          ...profile.playlists.map(
            (playlist) => _buildPlaylistItem(context, ref, playlist),
          ),
      ],
    );
  }

  Widget _buildPlaylistItem(
    BuildContext context,
    WidgetRef ref,
    PlaylistItem playlist,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: playlist.thumbnailUrl != null
                ? Image.network(
                    playlist.thumbnailUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              playlist.title,
              style: AppTextStyles.body.copyWith(color: AppColors.onSurface),
            ),
          ),

          // ── DELETE button → triggers confirm dialog ────────────────────
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              // Show confirm dialog before deleting
              final confirmed = await showConfirmDialog(
                context: context,
                title: 'Delete Playlist',
                message:
                    'Are you sure you want to delete "${playlist.title}"? This cannot be undone.',
                confirmText: 'Delete',
                cancelText: 'Cancel',
              );

              if (confirmed) {
                // Show success snackbar after delete
                if (context.mounted) {
                  showSuccessSnackbar(
                    context,
                    message: '"${playlist.title}" deleted successfully.',
                    undoLabel: 'Undo',
                    onUndo: () => debugPrint('Undo delete tapped'),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/profile/data/services/profile_service.dart';
import 'package:music_app_frontend/features/profile/presentation/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Watch the profile provider ─────────────────────────────────────────
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileState.when(
          // ── Loading state ─────────────────────────────────────────────────
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),

          // ── Error state ───────────────────────────────────────────────────
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.primary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load profile',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(profileProvider.notifier).fetchProfile(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    'Retry',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.background,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Data state ────────────────────────────────────────────────────
          data: (profile) => _ProfileContent(profile: profile),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProfileContent  –  the actual UI rendered when data is loaded
// ─────────────────────────────────────────────────────────────────────────────
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

          // ── Avatar + Name + Email + Followers ───────────────────────────
          _buildProfileHeader(),

          const SizedBox(height: 20),

          // ── Edit Profile Button ─────────────────────────────────────────
          _buildEditProfileButton(context),

          const SizedBox(height: 32),

          // ── Playlists Section ───────────────────────────────────────────
          _buildPlaylistsSection(context),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Avatar + Name + Email + Followers ──────────────────────────────────────
  Widget _buildProfileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        Center(
          child: CircleAvatar(
            radius: 64,
            backgroundColor: AppColors.surface,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? const Icon(
                    Icons.person,
                    size: 64,
                    color: AppColors.primary,
                  )
                : null,
          ),
        ),

        const SizedBox(height: 16),

        // Name
        Text(
          profile.name,
          style: AppTextStyles.header.copyWith(
            color: AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // Email
        Text(
          profile.email,
          style: AppTextStyles.body.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Followers / Following
        Text(
          '${profile.followers} Followers , ${profile.following} Following',
          style: AppTextStyles.body.copyWith(
            color: AppColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Edit Profile outlined button ───────────────────────────────────────────
  Widget _buildEditProfileButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          // TODO: Navigator.push to EditProfileScreen
          debugPrint('Edit Profile pressed');
        },
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
    );
  }

  // ── Playlists section ──────────────────────────────────────────────────────
  Widget _buildPlaylistsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Playlists',
          style: AppTextStyles.header.copyWith(
            color: AppColors.onSurface,
            fontSize: 20,
          ),
        ),

        const SizedBox(height: 16),

        // List or empty state
        if (profile.playlists.isEmpty)
          Center(
            child: Text(
              'No playlists yet.',
              style: AppTextStyles.body.copyWith(color: AppColors.onSurface),
            ),
          )
        else
          ...profile.playlists.map(
            (playlist) => _buildPlaylistItem(context, playlist),
          ),
      ],
    );
  }

  // ── Single playlist row ────────────────────────────────────────────────────
  Widget _buildPlaylistItem(BuildContext context, PlaylistItem playlist) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () {
          // TODO: Navigate to PlaylistDetailScreen
          debugPrint('Playlist tapped: ${playlist.title}');
        },
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

            // Playlist title
            Expanded(
              child: Text(
                playlist.title,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
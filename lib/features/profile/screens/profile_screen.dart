import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';

import 'package:music_app_frontend/core/routing/navigation_provider.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/friends/providers/friend_provider.dart';
import 'package:music_app_frontend/features/friends/screens/friends_screen.dart'
    show FriendsFilter;
import 'package:music_app_frontend/features/playlist/models/playlist.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/profile/providers/profile_provider.dart';
import 'package:music_app_frontend/features/profile/widgets/profile_account_tools.dart';
import 'package:music_app_frontend/features/profile/widgets/profile_action_buttons.dart';
import 'package:music_app_frontend/features/profile/widgets/profile_header_card.dart';
import 'package:music_app_frontend/features/profile/widgets/profile_playlists_section.dart';
import 'package:music_app_frontend/features/profile/widgets/profile_stats_card.dart';
import 'package:music_app_frontend/features/profile/widgets/profile_sheets.dart';
import 'package:music_app_frontend/features/relationships/providers/relationship_provider.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meState = ref.watch(meProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: meState.when(
          skipLoadingOnRefresh: false,
          loading: () => const ProfileSkeletonLoader(),
          error: (error, _) => AppErrorWidget(
            message: 'Failed to load profile. Please try again.',
            retryButtonText: 'Retry',
            onRetry: () {
              ref.invalidate(meProvider);
              ref.invalidate(profileProvider);
            },
          ),
          data: (user) => _ProfileContent(user: user),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.user});

  final User user;

  // System playlists managed by the backend — hidden from the profile list.
  static const _systemPlaylistNames = {'My Uploading', 'Liked Songs'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(myFriendsProvider);
    final followCountsAsync = ref.watch(followCountsProvider(user.id));
    final playlistsAsync = ref.watch(myPlaylistsProvider);
    final switchState = ref.watch(switchToProfessionalAccountProvider);

    final friendsCount = friendsAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );
    final followers = followCountsAsync.maybeWhen(
      data: (c) => c.followers,
      orElse: () => 0,
    );
    final following = followCountsAsync.maybeWhen(
      data: (c) => c.following,
      orElse: () => 0,
    );

    final visiblePlaylists = playlistsAsync.maybeWhen(
      data: (all) =>
          all.where((p) => !_systemPlaylistNames.contains(p.name)).toList(),
      orElse: () => const <Playlist>[],
    );

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: () async {
        ref.invalidate(meProvider);
        ref.invalidate(profileProvider);
        ref.invalidate(myFriendsProvider);
        ref.invalidate(followCountsProvider(user.id));
        await ref.read(myPlaylistsProvider.notifier).refreshPlaylists();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TitleRow(),
            const SizedBox(height: 20),
            ProfileHeaderCard(
              username: user.username.trim().isEmpty
                  ? 'No username'
                  : user.username,
              email: user.email.trim().isEmpty ? 'No email' : user.email,
              profileType: user.profileType,
              avatarUrl: user.effectiveAvatarUrl,
            ),
            const SizedBox(height: 16),
            ProfileStatsCard(
              stats: [
                ProfileStat(
                  label: 'Friends',
                  value: friendsCount,
                  isLoading: friendsAsync.isLoading,
                  onTap: () => context.push(
                    Routes.friends,
                    extra: FriendsFilter.myFriends,
                  ),
                ),
                ProfileStat(
                  label: 'Followers',
                  value: followers,
                  isLoading: followCountsAsync.isLoading,
                  onTap: () => context.push(Routes.followers),
                ),
                ProfileStat(
                  label: 'Following',
                  value: following,
                  isLoading: followCountsAsync.isLoading,
                  onTap: () => context.push(Routes.following),
                ),
                ProfileStat(
                  label: 'Playlists',
                  value: visiblePlaylists.length,
                  isLoading: playlistsAsync.isLoading,
                  // No dedicated "all playlists" route — section below covers it.
                ),
              ],
            ),
            const SizedBox(height: 18),
            ProfileActionButtons(
              onEditProfile: () => _openEditProfile(context, ref),
            ),
            const SizedBox(height: 28),
            _buildPlaylistsSection(context, ref, playlistsAsync),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Account',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ProfileAccountTools(
              profileType: user.profileType,
              onAccountType: () => showAccountTypeSheet(
                context,
                currentUser: user,
                isSwitching: switchState.isLoading,
                onSwitchToProfessional: () =>
                    _switchToProfessionalAccount(context, ref),
              ),
              onPrivacy: () => showPrivacyVisibilitySheet(context),
            ),
            const SizedBox(height: 24),
            _LogoutRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Playlist>> playlistsAsync,
  ) {
    return playlistsAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => ProfilePlaylistsSection(
        playlists: const [],
        isLoading: true,
        onCreate: () => _openCreatePlaylistSheet(context, ref),
        onOpen: (_) {},
        onDelete: (_) {},
      ),
      error: (_, _) => ProfilePlaylistsSection(
        playlists: const [],
        onCreate: () => _openCreatePlaylistSheet(context, ref),
        onOpen: (_) {},
        onDelete: (_) {},
        errorWidget: AppErrorWidget(
          message: 'Failed to load playlists. Please try again.',
          retryButtonText: 'Retry',
          onRetry: () =>
              ref.read(myPlaylistsProvider.notifier).loadPlaylists(),
        ),
      ),
      data: (playlists) {
        final visible = playlists
            .where((p) => !_systemPlaylistNames.contains(p.name))
            .toList();

        return ProfilePlaylistsSection(
          playlists: visible,
          onCreate: () => _openCreatePlaylistSheet(context, ref),
          onOpen: (p) async {
            await context.push(Routes.playlistById(p.id));
            if (context.mounted) {
              ref.read(myPlaylistsProvider.notifier).refreshPlaylists();
            }
          },
          onDelete: (p) => _confirmDeletePlaylist(context, ref, p),
        );
      },
    );
  }

  void _openEditProfile(BuildContext context, WidgetRef ref) {
    ref.read(usernameUpdateProvider.notifier).clear();
    showEditProfileSheet(context, currentUser: user);
  }

  Future<void> _confirmDeletePlaylist(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete Playlist',
      message:
          'Are you sure you want to delete "${playlist.name}"? This cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );

    if (!confirmed || !context.mounted) return;

    await ref.read(myPlaylistsProvider.notifier).deletePlaylist(playlist.id);

    if (!context.mounted) return;
    showSuccessSnackbar(
      context,
      message: '"${playlist.name}" deleted successfully.',
    );
  }

  void _openCreatePlaylistSheet(BuildContext context, WidgetRef ref) {
    showNewPlaylistSheet(context, ref);
  }

  Future<void> _switchToProfessionalAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Switch to Professional',
      message:
          'Professional accounts can be followed by other users. Other users will see Follow instead of Add Friend.',
      confirmText: 'Switch',
      cancelText: 'Cancel',
    );

    if (!confirmed) return;

    ref.read(switchToProfessionalAccountProvider.notifier).clear();
    final updatedUser = await ref
        .read(switchToProfessionalAccountProvider.notifier)
        .switchToProfessionalAccount();

    if (!context.mounted) return;

    if (updatedUser == null) {
      final error = ref.read(switchToProfessionalAccountProvider).error;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(_normalizeAccountSwitchError(error))),
        );
      return;
    }

    ref.invalidate(profileProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Switched to Professional Account')),
      );
  }

  String _normalizeAccountSwitchError(Object? error) {
    final message = error?.toString();
    if (message == null || message.isEmpty) {
      return 'Could not switch account type';
    }

    return message.startsWith('Exception: ') ? message.substring(11) : message;
  }
}

class _TitleRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Profile',
          style: AppTextStyles.header.copyWith(
            color: AppColors.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        // TODO: wire a settings icon here when a real settings route is added.
      ],
    );
  }
}

class _LogoutRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
        icon: const Icon(Icons.logout, size: 18),
        label: Text(
          'Log out',
          style: AppTextStyles.body.copyWith(
            color: AppColors.error,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

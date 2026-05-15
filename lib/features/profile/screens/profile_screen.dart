import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/core/routing/navigation_provider.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/friends/providers/friend_provider.dart';
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
          skipLoadingOnRefresh: false,
          // ── LOADING: show spinner while API is running ─────────────────
          loading: () => const ProfileSkeletonLoader(),

          // ── ERROR: show error widget if API fails ──────────────────────
          error: (error, _) => AppErrorWidget(
            message: 'Failed to load profile. Please try again.',
            retryButtonText: 'Retry',
            onRetry: () {
              ref.invalidate(meProvider);
              ref.invalidate(profileProvider);
            },
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
    final friendsState = ref.watch(myFriendsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _buildProfileHeader(ref, friendsState),
          const SizedBox(height: 20),
          _buildProfileActions(context, ref),
          const SizedBox(height: 32),
          _buildPlaylistsSection(context, ref),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    WidgetRef ref,
    AsyncValue<List<User>> friendsState,
  ) {
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
        _buildFriendshipStat(ref, friendsState),
      ],
    );
  }

  Widget _buildFriendshipStat(
    WidgetRef ref,
    AsyncValue<List<User>> friendsState,
  ) {
    return friendsState.when(
      skipLoadingOnRefresh: false,
      data: (friends) => Text(
        '${friends.length} ${friends.length == 1 ? 'Friend' : 'Friends'}',
        style: AppTextStyles.body.copyWith(color: AppColors.onSurface),
        textAlign: TextAlign.center,
      ),
      loading: () => Text(
        'Loading friends...',
        style: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 14),
        textAlign: TextAlign.center,
      ),
      error: (error, _) => TextButton.icon(
        onPressed: () => ref.invalidate(myFriendsProvider),
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Retry friends'),
      ),
    );
  }

  Widget _buildProfileActions(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showUsernameDialog(context, ref),
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

  void _showUsernameDialog(BuildContext context, WidgetRef ref) {
    final currentUser = ref
        .read(meProvider)
        .maybeWhen(data: (user) => user, orElse: () => null);

    if (currentUser == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Profile is still loading.')),
        );
      return;
    }

    ref.read(usernameUpdateProvider.notifier).clear();

    showDialog<void>(
      context: context,
      builder: (_) => _UsernameDialog(currentUser: currentUser),
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

class _UsernameDialog extends ConsumerStatefulWidget {
  const _UsernameDialog({required this.currentUser});

  final User currentUser;

  @override
  ConsumerState<_UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends ConsumerState<_UsernameDialog> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUser.username);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(usernameUpdateProvider);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        'Change username',
        style: AppTextStyles.subtitle.copyWith(color: AppColors.onSurface),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usernames must be unique.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.hint,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _controller,
              enabled: !updateState.isLoading,
              autofocus: true,
              style: AppTextStyles.body.copyWith(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Username',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.hint,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.card,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
              ),
              validator: _validateUsername,
            ),
            if (updateState.hasError) ...[
              const SizedBox(height: 10),
              Text(
                _normalizeError(updateState.error!),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.error,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: updateState.isLoading
              ? null
              : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        SizedBox(
          width: 120,
          child: AppPrimaryButton(
            label: 'Save',
            isLoading: updateState.isLoading,
            onPressed: _save,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedUser = await ref
        .read(usernameUpdateProvider.notifier)
        .updateUsername(
          currentUser: widget.currentUser,
          username: _controller.text,
        );

    if (!mounted || updatedUser == null) return;

    ref.invalidate(profileProvider);
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Username updated.')));
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (username.length > 30) {
      return 'Username cannot be longer than 30 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Use only letters, numbers, and underscores';
    }
    return null;
  }

  String _normalizeError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ') ? message.substring(11) : message;
  }
}

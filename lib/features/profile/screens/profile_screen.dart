import 'dart:async';

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
import 'package:music_app_frontend/features/profile/models/profile_model.dart';
import 'package:music_app_frontend/features/profile/providers/profile_provider.dart';
import 'package:music_app_frontend/features/relationships/models/follow_counts.dart';
import 'package:music_app_frontend/features/relationships/providers/relationship_provider.dart';
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
    final currentUser = ref
        .watch(meProvider)
        .maybeWhen(data: (user) => user, orElse: () => null);
    final switchState = ref.watch(switchToProfessionalAccountProvider);
    final followCountsState =
        currentUser?.profileType == User.professionalProfileType
        ? ref.watch(followCountsProvider(currentUser!.id))
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          _buildProfileHeader(
            context,
            ref,
            friendsState,
            currentUser: currentUser,
            followCountsState: followCountsState,
          ),
          const SizedBox(height: 20),
          _buildProfileActions(
            context,
            ref,
            currentUser: currentUser,
            isSwitchingAccount: switchState.isLoading,
          ),
          const SizedBox(height: 32),
          _buildPlaylistsSection(context, ref),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<User>> friendsState, {
    required User? currentUser,
    required AsyncValue<FollowCounts>? followCountsState,
  }) {
    final isProfessionalAccount =
        currentUser?.profileType == User.professionalProfileType;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ProfileCardContainer(
          isProfessional: isProfessionalAccount,
          child: Column(
            children: [
              CircleAvatar(
                radius: 64,
                backgroundColor: colorScheme.surface,
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
              const SizedBox(height: 16),
              Text(
                profile.name,
                style: AppTextStyles.header.copyWith(
                  color: AppColors.onSurface,
                ),
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
              if (isProfessionalAccount) ...[
                const SizedBox(height: 14),
                _buildProfessionalBadge(),
              ],
              const SizedBox(height: 18),
              _buildProfileStats(
                context,
                ref,
                friendsState,
                currentUser: currentUser,
                followCountsState: followCountsState,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStats(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<User>> friendsState, {
    required User? currentUser,
    required AsyncValue<FollowCounts>? followCountsState,
  }) {
    final isProfessionalAccount =
        currentUser?.profileType == User.professionalProfileType;

    return friendsState.when(
      skipLoadingOnRefresh: false,
      data: (friends) {
        if (!isProfessionalAccount) {
          return Text(
            _formatCount(friends.length, 'Friend', 'Friends'),
            style: AppTextStyles.body.copyWith(color: AppColors.onSurface),
            textAlign: TextAlign.center,
          );
        }

        final counts = followCountsState?.maybeWhen(
          data: (counts) => counts,
          orElse: () => const FollowCounts(),
        );

        final isLoadingCounts = followCountsState?.isLoading ?? false;
        final hasCountsError = followCountsState?.hasError ?? false;
        final followers = counts?.followers ?? 0;
        final following = counts?.following ?? 0;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    value: friends.length,
                    label: 'Friends',
                  ),
                ),
                _buildStatDivider(),
                Expanded(
                  child: _buildStatColumn(
                    value: followers,
                    label: 'Followers',
                    onTap: () => context.push(Routes.followers),
                  ),
                ),
                _buildStatDivider(),
                Expanded(
                  child: _buildStatColumn(
                    value: following,
                    label: 'Following',
                    onTap: () => context.push(Routes.following),
                  ),
                ),
              ],
            ),
            if (isLoadingCounts || hasCountsError) ...[
              const SizedBox(height: 12),
              Text(
                isLoadingCounts ? 'Loading follows...' : 'Follows unavailable',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.hint,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
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

  String _formatCount(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
  }

  Widget _buildProfessionalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: AppColors.primary, size: 16),
          const SizedBox(width: 6),
          Text(
            'Professional Account',
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required int value,
    required String label,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTextStyles.subtitle.copyWith(
              color: onTap == null ? AppColors.onSurface : AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: content,
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 42, color: AppColors.inputBorder);
  }

  Widget _buildProfileActions(
    BuildContext context,
    WidgetRef ref, {
    required User? currentUser,
    required bool isSwitchingAccount,
  }) {
    final isPersonalAccount =
        currentUser?.profileType == User.personalProfileType;

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
        if (isPersonalAccount) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isSwitchingAccount
                  ? null
                  : () => _switchToProfessionalAccount(context, ref),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: isSwitchingAccount
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      'Switch to Professional',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
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

class _ProfileCardContainer extends StatelessWidget {
  const _ProfileCardContainer({
    required this.isProfessional,
    required this.child,
  });

  final bool isProfessional;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isProfessional) {
      return _ProfessionalShineCard(child: child);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: child,
    );
  }
}

class _ProfessionalShineCard extends StatefulWidget {
  const _ProfessionalShineCard({required this.child});

  final Widget child;

  @override
  State<_ProfessionalShineCard> createState() => _ProfessionalShineCardState();
}

class _ProfessionalShineCardState extends State<_ProfessionalShineCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _shineTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener(_handleAnimationStatus);

    _controller.forward();
  }

  @override
  void dispose() {
    _shineTimer?.cancel();
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    _controller.reset();
    _shineTimer?.cancel();
    _shineTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final position = -1.3 + (value * 2.6);
        final opacityScale = value < 0.5 ? value * 2 : (1 - value) * 2;
        final peakAlpha = (0.04 * opacityScale.clamp(0.0, 1.0)).toDouble();

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.45),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  color: AppColors.card,
                  child: child,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(position - 0.45, position - 0.45),
                          end: Alignment(position + 0.45, position + 0.45),
                          colors: [
                            AppColors.primary.withValues(alpha: 0),
                            AppColors.primary.withValues(alpha: peakAlpha),
                            AppColors.primary.withValues(alpha: 0),
                          ],
                          stops: const [0.20, 0.50, 0.80],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: widget.child,
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
    final hasUpdateError = updateState.hasError;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        'Change username',
        style: AppTextStyles.subtitle.copyWith(color: AppColors.onSurface),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        child: SingleChildScrollView(
          child: Form(
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
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) {
                    if (hasUpdateError) {
                      ref.read(usernameUpdateProvider.notifier).clear();
                    }
                  },
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
                      borderSide: BorderSide(
                        color: hasUpdateError
                            ? AppColors.error
                            : AppColors.inputBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: hasUpdateError
                            ? AppColors.error
                            : AppColors.primary,
                      ),
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
                    softWrap: true,
                  ),
                ],
              ],
            ),
          ),
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
    final message = error.toString().toLowerCase();

    if (message.contains('already taken') ||
        message.contains('already exists') ||
        message.contains('duplicate')) {
      return 'Username already taken';
    }

    if (message.contains('at least 3') ||
        message.contains('at least three') ||
        message.contains('too short')) {
      return 'Username must be at least 3 characters';
    }

    return 'Could not update username';
  }
}

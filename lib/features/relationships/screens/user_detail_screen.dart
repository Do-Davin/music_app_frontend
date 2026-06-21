import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/friends/providers/friend_provider.dart';
import 'package:music_app_frontend/features/relationships/models/relationship_status.dart';
import 'package:music_app_frontend/features/relationships/providers/relationship_provider.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  const UserDetailScreen({super.key, required this.user});

  final User user;

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(friendActionsProvider, (previous, next) {
      if (!mounted) return;
      if (next.hasError && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_normalizeError(next.error!))));
      }
    });

    ref.listen<AsyncValue<void>>(relationshipActionsProvider, (previous, next) {
      if (!mounted) return;
      if (next.hasError && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_normalizeError(next.error!))));
      }
    });

    final currentUserId = ref
        .watch(meProvider)
        .maybeWhen(data: (u) => u.id, orElse: () => null);
    final isSelf = currentUserId != null && widget.user.id == currentUserId;

    final user = widget.user;
    final profileType = user.profileType.trim();
    final isProfessional = profileType == User.professionalProfileType;
    final colorScheme = Theme.of(context).colorScheme;

    final isAnyActionLoading =
        ref.watch(friendActionsProvider).isLoading ||
        ref.watch(relationshipActionsProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Text(
          'Profile',
          style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            children: [
              // ── Profile card ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: colorScheme.surface,
                      backgroundImage:
                          user.profileImageUrl != null &&
                              user.profileImageUrl!.isNotEmpty
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child:
                          user.profileImageUrl == null ||
                              user.profileImageUrl!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 64,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.username,
                      style: AppTextStyles.header.copyWith(
                        color: AppColors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (profileType.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ProfileTypeBadge(profileType: profileType),
                    ],
                    // Follow counts — professional accounts only, display-only.
                    // FollowListScreen only supports the authenticated user's
                    // lists, so counts are not made tappable here.
                    if (isProfessional) ...[
                      const SizedBox(height: 20),
                      _buildFollowCounts(user.id),
                    ],
                  ],
                ),
              ),

              // ── Relationship actions (hidden for own profile) ─────────────
              if (!isSelf) ...[
                const SizedBox(height: 20),
                _buildRelationshipSection(isAnyActionLoading),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Follow counts ──────────────────────────────────────────────────────────

  Widget _buildFollowCounts(String userId) {
    final countsAsync = ref.watch(followCountsProvider(userId));
    return countsAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => Text(
        'Loading counts...',
        style: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 13),
        textAlign: TextAlign.center,
      ),
      error: (_, _) => Text(
        'Counts unavailable',
        style: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 13),
        textAlign: TextAlign.center,
      ),
      data: (counts) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CountItem(value: counts.followers, label: 'Followers'),
          Container(
            width: 1,
            height: 32,
            color: AppColors.inputBorder,
            margin: const EdgeInsets.symmetric(horizontal: 24),
          ),
          _CountItem(value: counts.following, label: 'Following'),
        ],
      ),
    );
  }

  // ── Relationship status and action buttons ─────────────────────────────────

  Widget _buildRelationshipSection(bool isAnyActionLoading) {
    final statusAsync = ref.watch(relationshipStatusProvider(widget.user.id));
    return statusAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox(
        height: 52,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (_, _) => Center(
        child: TextButton.icon(
          onPressed: () =>
              ref.invalidate(relationshipStatusProvider(widget.user.id)),
          icon: const Icon(Icons.refresh, color: AppColors.primary, size: 16),
          label: Text(
            'Retry',
            style: AppTextStyles.body.copyWith(color: AppColors.primary),
          ),
        ),
      ),
      data: (status) => _buildActionButtons(status, isAnyActionLoading),
    );
  }

  Widget _buildActionButtons(
    RelationshipStatus status,
    bool isAnyActionLoading,
  ) {
    // While any mutation is in-flight, replace buttons with a spinner to
    // prevent duplicate taps and give clear feedback.
    if (isAnyActionLoading) {
      return const SizedBox(
        height: 52,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (status.isFriend) {
      return _disabledOutlinedButton(
        icon: Icons.people,
        label: 'Friends',
        color: AppColors.primary,
      );
    }

    if (status.hasOutgoingFriendRequest) {
      return _outlinedButton(
        label: 'Cancel Request',
        color: AppColors.hint,
        onPressed: () => _cancelFriendRequest(),
      );
    }

    if (status.hasIncomingFriendRequest) {
      return Row(
        children: [
          Expanded(
            child: _primaryButton(
              label: 'Accept',
              onPressed: () => _acceptFriendRequest(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _outlinedButton(
              label: 'Reject',
              color: AppColors.error,
              onPressed: () => _rejectFriendRequest(),
            ),
          ),
        ],
      );
    }

    if (status.canAddFriend) {
      return _outlinedButton(
        label: 'Add Friend',
        color: AppColors.primary,
        onPressed: () => _sendFriendRequest(),
      );
    }

    if (status.isFollowing) {
      return _outlinedButton(
        label: 'Following',
        color: AppColors.primary,
        onPressed: () => _confirmUnfollow(),
      );
    }

    if (status.canFollow) {
      return _outlinedButton(
        label: 'Follow',
        color: AppColors.primary,
        onPressed: () => _followUser(),
      );
    }

    return const SizedBox.shrink();
  }

  // ── Action methods ─────────────────────────────────────────────────────────

  Future<void> _sendFriendRequest() async {
    await ref
        .read(friendActionsProvider.notifier)
        .sendFriendRequest(widget.user.id);
  }

  Future<void> _cancelFriendRequest() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Cancel Request',
      message: 'Cancel your friend request to ${widget.user.username}?',
      confirmText: 'Cancel Request',
      cancelText: 'Keep',
    );
    if (!confirmed || !mounted) return;
    await ref
        .read(friendActionsProvider.notifier)
        .cancelFriendRequest(widget.user.id);
  }

  Future<void> _acceptFriendRequest() async {
    await ref
        .read(friendActionsProvider.notifier)
        .acceptFriendRequest(widget.user.id);
    // acceptFriendRequest in FriendActionsNotifier does not invalidate
    // relationshipStatusProvider — do it here to refresh the action button.
    if (mounted) ref.invalidate(relationshipStatusProvider(widget.user.id));
  }

  Future<void> _rejectFriendRequest() async {
    await ref
        .read(friendActionsProvider.notifier)
        .rejectFriendRequest(widget.user.id);
    // Same gap as accept — invalidate explicitly.
    if (mounted) ref.invalidate(relationshipStatusProvider(widget.user.id));
  }

  Future<void> _followUser() async {
    // RelationshipActionsNotifier.followUser already invalidates
    // relationshipStatusProvider(userId) and followCountsProvider(userId).
    await ref
        .read(relationshipActionsProvider.notifier)
        .followUser(widget.user.id);
  }

  Future<void> _confirmUnfollow() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Unfollow User',
      message: 'Stop following ${widget.user.username}?',
      confirmText: 'Unfollow',
      cancelText: 'Cancel',
    );
    if (!confirmed || !mounted) return;
    await ref
        .read(relationshipActionsProvider.notifier)
        .unfollowUser(widget.user.id);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _normalizeError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ') ? message.substring(11) : message;
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _outlinedButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _disabledOutlinedButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return OutlinedButton.icon(
      onPressed: null,
      icon: Icon(icon, size: 18, color: color.withValues(alpha: 0.55)),
      label: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: color.withValues(alpha: 0.55),
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────

class _CountItem extends StatelessWidget {
  const _CountItem({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: AppTextStyles.subtitle.copyWith(
            color: AppColors.onSurface,
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
    );
  }
}

class _ProfileTypeBadge extends StatelessWidget {
  const _ProfileTypeBadge({required this.profileType});

  final String profileType;

  @override
  Widget build(BuildContext context) {
    final isProfessional = profileType == User.professionalProfileType;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isProfessional ? AppColors.primary : AppColors.inputBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isProfessional) ...[
            const Icon(Icons.verified, color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            isProfessional ? 'Professional Account' : profileType,
            style: AppTextStyles.body.copyWith(
              color: isProfessional ? AppColors.primary : AppColors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

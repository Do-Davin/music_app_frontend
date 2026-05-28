import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/relationships/providers/relationship_provider.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

enum FollowListMode { followers, following }

class FollowListScreen extends ConsumerWidget {
  const FollowListScreen({super.key, required this.mode});

  final FollowListMode mode;

  String get _title {
    return switch (mode) {
      FollowListMode.followers => 'Followers',
      FollowListMode.following => 'Following',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersState = switch (mode) {
      FollowListMode.followers => ref.watch(myFollowersProvider),
      FollowListMode.following => ref.watch(myFollowingProvider),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Text(
          _title,
          style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () => _refresh(ref),
        child: usersState.when(
          skipLoadingOnRefresh: false,
          data: (users) => _buildUsers(users),
          loading: () => const AppLoadingWidget(message: 'Loading users...'),
          error: (error, _) => AppErrorWidget(
            message: 'Failed to load ${_title.toLowerCase()}.',
            retryButtonText: 'Retry',
            onRetry: () => _invalidate(ref),
          ),
        ),
      ),
    );
  }

  Widget _buildUsers(List<User> users) {
    if (users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 520,
            child: AppEmptyStateWidget(
              icon: mode == FollowListMode.followers
                  ? Icons.people_outline
                  : Icons.person_add_alt_1_outlined,
              title: 'No $_title Yet',
              subtitle: mode == FollowListMode.followers
                  ? 'Users who follow you will appear here'
                  : 'Users you follow will appear here',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _UserRow(
        user: users[index],
        onTap: () => context.push(Routes.userDetail, extra: users[index]),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    _invalidate(ref);
    await switch (mode) {
      FollowListMode.followers => ref.read(myFollowersProvider.future),
      FollowListMode.following => ref.read(myFollowingProvider.future),
    };
  }

  void _invalidate(WidgetRef ref) {
    switch (mode) {
      case FollowListMode.followers:
        ref.invalidate(myFollowersProvider);
      case FollowListMode.following:
        ref.invalidate(myFollowingProvider);
    }
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onTap});

  final User user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profileType = user.profileType.trim();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.surface,
          backgroundImage:
              user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
              ? NetworkImage(user.profileImageUrl!)
              : null,
          child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
              ? const Icon(Icons.person, color: AppColors.primary)
              : null,
        ),
        title: Text(
          user.username,
          style: AppTextStyles.body.copyWith(
            color: AppColors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.email,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.hint,
                  fontSize: 12,
                ),
              ),
              if (profileType.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  profileType,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.hint,
          size: 22,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/friends/providers/friend_provider.dart';
import 'package:music_app_frontend/features/relationships/models/relationship_status.dart';
import 'package:music_app_frontend/features/relationships/providers/relationship_provider.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

enum FriendsFilter { myFriends, incoming, outgoing }

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key, this.initialFilter});

  final FriendsFilter? initialFilter;

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late FriendsFilter _activeFilter;
  String _localFilterText = '';

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter ?? FriendsFilter.myFriends;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Search/filter helpers ──────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    setState(() => _localFilterText = value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _localFilterText = '');
  }

  void _setFilter(FriendsFilter filter) {
    if (_activeFilter == filter) return;
    _searchController.clear();
    setState(() {
      _activeFilter = filter;
      _localFilterText = '';
    });
  }

  List<User> _applyLocalFilter(List<User> users) {
    final q = _localFilterText.toLowerCase().trim();
    if (q.isEmpty) return users;
    return users
        .where(
          (u) =>
              u.username.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q),
        )
        .toList();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Text(
          'Friends',
          style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(myFriendsProvider);
          ref.invalidate(incomingFriendRequestsProvider);
          ref.invalidate(outgoingFriendRequestsProvider);
          if (_localFilterText.isNotEmpty) {
            ref.invalidate(userSearchProvider(_localFilterText));
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildSearchBar(),
            const SizedBox(height: 10),
            _buildFilterRow(),
            const SizedBox(height: 16),
            _buildActiveSection(),
          ],
        ),
      ),
    );
  }

  // ─── Search bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      style: AppTextStyles.body.copyWith(fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Search by username or email',
        hintStyle: AppTextStyles.body.copyWith(
          color: AppColors.hint,
          fontSize: 14,
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, color: AppColors.hint),
                onPressed: _clearSearch,
              ),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  // ─── Filter pill row ────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FriendsFilter.values.map((filter) {
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _setFilter(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.inputBorder,
                  ),
                ),
                child: Text(
                  _filterLabel(filter),
                  style: AppTextStyles.body.copyWith(
                    color: isSelected
                        ? AppColors.background
                        : AppColors.hint,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _filterLabel(FriendsFilter filter) => switch (filter) {
    FriendsFilter.myFriends => 'My Friends',
    FriendsFilter.incoming => 'Incoming',
    FriendsFilter.outgoing => 'Outgoing',
  };

  // ─── Active section dispatcher ──────────────────────────────────────────────

  Widget _buildActiveSection() => switch (_activeFilter) {
    FriendsFilter.myFriends => _buildMyFriendsSection(),
    FriendsFilter.incoming => _buildIncomingSection(),
    FriendsFilter.outgoing => _buildOutgoingSection(),
  };

  // ─── My Friends ─────────────────────────────────────────────────────────────

  Widget _buildMyFriendsSection() {
    return _buildFilterableSection(
      state: ref.watch(myFriendsProvider),
      emptyIcon: Icons.people_outline,
      emptyTitle: 'No Friends Yet',
      emptySubtitle: 'Search for users above to send a friend request',
      trailingBuilder: (_) =>
          const Icon(Icons.people, color: AppColors.primary),
      onRetry: () => ref.invalidate(myFriendsProvider),
      retryMessage: 'Failed to load friends.',
    );
  }

  // ─── Incoming requests ──────────────────────────────────────────────────────

  Widget _buildIncomingSection() {
    final actionState = ref.watch(friendActionsProvider);

    return _buildFilterableSection(
      state: ref.watch(incomingFriendRequestsProvider),
      emptyIcon: Icons.mark_email_unread_outlined,
      emptyTitle: 'No Incoming Requests',
      emptySubtitle: 'Friend requests sent to you will appear here',
      trailingBuilder: (user) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: actionState.isLoading
                ? null
                : () => ref
                      .read(friendActionsProvider.notifier)
                      .acceptFriendRequest(user.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: actionState.isLoading
                ? null
                : () => ref
                      .read(friendActionsProvider.notifier)
                      .rejectFriendRequest(user.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
      onRetry: () => ref.invalidate(incomingFriendRequestsProvider),
      retryMessage: 'Failed to load incoming requests.',
    );
  }

  // ─── Outgoing requests ──────────────────────────────────────────────────────

  Widget _buildOutgoingSection() {
    return _buildFilterableSection(
      state: ref.watch(outgoingFriendRequestsProvider),
      emptyIcon: Icons.outgoing_mail,
      emptyTitle: 'No Outgoing Requests',
      emptySubtitle: 'Requests you send will appear here',
      trailingBuilder: (_) => Text(
        'Pending',
        style: AppTextStyles.body.copyWith(
          color: AppColors.hint,
          fontSize: 13,
        ),
      ),
      onRetry: () => ref.invalidate(outgoingFriendRequestsProvider),
      retryMessage: 'Failed to load outgoing requests.',
    );
  }

  // ─── Shared filterable section ───────────────────────────────────────────────
  //
  // When search text is empty: show the provider list as-is.
  // When search text is not empty:
  //   • Apply local filter to the loaded list.
  //   • If local matches exist → show them with [trailingBuilder].
  //   • If no local matches → fall back to global user search.

  Widget _buildFilterableSection({
    required AsyncValue<List<User>> state,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required Widget Function(User user) trailingBuilder,
    required VoidCallback onRetry,
    required String retryMessage,
  }) {
    if (_localFilterText.isEmpty) {
      return _buildUserList(
        state: state,
        emptyIcon: emptyIcon,
        emptyTitle: emptyTitle,
        emptySubtitle: emptySubtitle,
        trailingBuilder: trailingBuilder,
        onRetry: onRetry,
      );
    }

    // Search text present — check local list first.
    return state.when(
      skipLoadingOnRefresh: false,
      loading: () => _loadingBox(),
      error: (_, _) => _compactError(message: retryMessage, onRetry: onRetry),
      data: (items) {
        final localMatches = _applyLocalFilter(items);
        if (localMatches.isNotEmpty) {
          return _cardList(
            localMatches
                .map((u) => _userTile(u, trailing: trailingBuilder(u)))
                .toList(),
          );
        }
        // No local matches — show global user search results.
        return _buildGlobalSearchFallback();
      },
    );
  }

  // ─── Global search fallback ──────────────────────────────────────────────────
  //
  // Shown when local list has no matches for the current search text.
  // Uses [userSearchProvider] (keyed by [_localFilterText]) and
  // [relationshipStatusProvider] for the correct per-user action button.

  Widget _buildGlobalSearchFallback() {
    final searchState = ref.watch(userSearchProvider(_localFilterText));
    final actionState = ref.watch(friendActionsProvider);
    final relationshipActionState = ref.watch(relationshipActionsProvider);
    final currentUserId = ref
        .watch(meProvider)
        .maybeWhen(data: (u) => u.id, orElse: () => null);

    return searchState.when(
      skipLoadingOnRefresh: false,
      loading: () => _loadingBox(),
      error: (_, _) => _compactError(
        message: 'Failed to search users.',
        onRetry: () => ref.invalidate(userSearchProvider(_localFilterText)),
      ),
      data: (users) {
        final visible =
            users.where((u) => u.id != currentUserId).toList();

        if (visible.isEmpty) {
          return _compactEmptyState(
            icon: Icons.search_off,
            title: 'No Users Found',
            subtitle: 'Try another username or email',
          );
        }

        return _cardList(
          visible
              .map(
                (user) => _userTile(
                  user,
                  trailing: _buildSearchActionButton(
                    user,
                    isFriendActionLoading: actionState.isLoading,
                    isRelationshipActionLoading:
                        relationshipActionState.isLoading,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  // ─── Per-user relationship action button ─────────────────────────────────────

  Widget _buildSearchActionButton(
    User user, {
    required bool isFriendActionLoading,
    required bool isRelationshipActionLoading,
  }) {
    final statusState = ref.watch(relationshipStatusProvider(user.id));
    final isActionLoading =
        isFriendActionLoading || isRelationshipActionLoading;

    return statusState.when(
      skipLoadingOnRefresh: false,
      data: (status) => _relationshipActionButton(
        user: user,
        status: status,
        isActionLoading: isActionLoading,
      ),
      loading: () => const SizedBox(
        width: 64,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      error: (_, _) => TextButton(
        onPressed: null,
        child: Text(
          'Retry',
          style: AppTextStyles.body.copyWith(color: AppColors.hint),
        ),
      ),
    );
  }

  Widget _relationshipActionButton({
    required User user,
    required RelationshipStatus status,
    required bool isActionLoading,
  }) {
    if (status.isFriend) {
      return const TextButton(onPressed: null, child: Text('Friend'));
    }

    if (status.hasOutgoingFriendRequest) {
      return const TextButton(onPressed: null, child: Text('Pending'));
    }

    if (status.hasIncomingFriendRequest) {
      return const TextButton(onPressed: null, child: Text('Respond'));
    }

    if (status.canAddFriend) {
      return TextButton(
        onPressed: isActionLoading
            ? null
            : () => ref
                  .read(friendActionsProvider.notifier)
                  .sendFriendRequest(user.id),
        child: const Text('Add Friend'),
      );
    }

    if (status.isFollowing) {
      return TextButton(
        onPressed: isActionLoading ? null : () => _unfollowUser(user),
        child: const Text('Following'),
      );
    }

    if (status.canFollow) {
      return TextButton(
        onPressed: isActionLoading
            ? null
            : () => ref
                  .read(relationshipActionsProvider.notifier)
                  .followUser(user.id),
        child: const Text('Follow'),
      );
    }

    return const TextButton(onPressed: null, child: Text('Unavailable'));
  }

  // ─── Shared list renderer ────────────────────────────────────────────────────

  Widget _buildUserList({
    required AsyncValue<List<User>> state,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required Widget Function(User user) trailingBuilder,
    required VoidCallback onRetry,
  }) {
    return state.when(
      skipLoadingOnRefresh: false,
      data: (users) {
        if (users.isEmpty) {
          return _compactEmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            subtitle: emptySubtitle,
          );
        }

        return _cardList(
          users
              .map((user) => _userTile(user, trailing: trailingBuilder(user)))
              .toList(),
        );
      },
      loading: () => _loadingBox(),
      error: (_, _) => _compactError(
        message: 'Failed to load this section.',
        onRetry: onRetry,
      ),
    );
  }

  // ─── Action methods ──────────────────────────────────────────────────────────

  Future<void> _unfollowUser(User user) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Unfollow User',
      message: 'Stop following ${user.username}?',
      confirmText: 'Unfollow',
      cancelText: 'Cancel',
    );

    if (!confirmed) return;

    await ref.read(relationshipActionsProvider.notifier).unfollowUser(user.id);
  }

  // ─── Shared tile / list widgets ─────────────────────────────────────────────

  Widget _cardList(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _userTile(User user, {required Widget trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: AppColors.surface,
        backgroundImage:
            user.effectiveAvatarUrl != null &&
                user.effectiveAvatarUrl!.isNotEmpty
            ? NetworkImage(user.effectiveAvatarUrl!)
            : null,
        onBackgroundImageError:
            user.effectiveAvatarUrl != null &&
                user.effectiveAvatarUrl!.isNotEmpty
            ? (_, _) {}
            : null,
        child: user.effectiveAvatarUrl == null ||
                user.effectiveAvatarUrl!.isEmpty
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
      subtitle: Text(
        user.email,
        style: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 12),
      ),
      trailing: trailing,
      onTap: () => context.push(Routes.userDetail, extra: user),
    );
  }

  Widget _compactEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _compactError({
    required String message,
    required VoidCallback onRetry,
  }) {
    return SizedBox(
      height: 180,
      child: AppErrorWidget(
        message: message,
        retryButtonText: 'Retry',
        onRetry: onRetry,
      ),
    );
  }

  Widget _loadingBox() {
    return const SizedBox(
      height: 96,
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  String _normalizeError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ') ? message.substring(11) : message;
  }
}

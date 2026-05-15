import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/friends/providers/friend_provider.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    final actionState = ref.watch(friendActionsProvider);
    final searchState = ref.watch(userSearchProvider);
    final friendsState = ref.watch(myFriendsProvider);
    final incomingState = ref.watch(incomingFriendRequestsProvider);
    final outgoingState = ref.watch(outgoingFriendRequestsProvider);
    final meState = ref.watch(meProvider);

    final currentUserId = meState.maybeWhen(
      data: (user) => user.id,
      orElse: () => null,
    );
    final myFriendUserIds = _idsFrom(friendsState);
    final incomingIds = _idsFrom(incomingState);
    final outgoingIds = _idsFrom(outgoingState);

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
          ref.invalidate(userSearchProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildSearchField(),
            const SizedBox(height: 24),
            _buildSectionTitle('Search Users'),
            _buildSearchResults(
              searchState: searchState,
              currentUserId: currentUserId,
              myFriendUserIds: myFriendUserIds,
              incomingIds: incomingIds,
              outgoingIds: outgoingIds,
              isActionLoading: actionState.isLoading,
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('Incoming Requests'),
            _buildUserList(
              state: incomingState,
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
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('Outgoing Requests'),
            _buildUserList(
              state: outgoingState,
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
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('My Friends'),
            _buildUserList(
              state: friendsState,
              emptyIcon: Icons.people_outline,
              emptyTitle: 'No Friends Yet',
              emptySubtitle: 'Search for users and send a friend request',
              trailingBuilder: (_) =>
                  const Icon(Icons.people, color: AppColors.primary),
              onRetry: () => ref.invalidate(myFriendsProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        ref.read(friendSearchQueryProvider.notifier).state = value;
        setState(() {});
      },
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
                onPressed: () {
                  _searchController.clear();
                  ref.read(friendSearchQueryProvider.notifier).state = '';
                  setState(() {});
                },
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

  Widget _buildSearchResults({
    required AsyncValue<List<User>> searchState,
    required String? currentUserId,
    required Set<String> myFriendUserIds,
    required Set<String> incomingIds,
    required Set<String> outgoingIds,
    required bool isActionLoading,
  }) {
    final query = ref.watch(friendSearchQueryProvider).trim();
    if (query.isEmpty) {
      return _compactEmptyState(
        icon: Icons.person_search_outlined,
        title: 'Search for a User',
        subtitle: 'Type a username or email to send a request',
      );
    }

    return searchState.when(
      skipLoadingOnRefresh: false,
      data: (users) {
        final visibleUsers = users
            .where((user) => user.id != currentUserId)
            .toList();

        if (visibleUsers.isEmpty) {
          return _compactEmptyState(
            icon: Icons.search_off,
            title: 'No Users Found',
            subtitle: 'Try another username or email',
          );
        }

        return _cardList(
          visibleUsers.map((user) {
            final alreadyFriend = myFriendUserIds.contains(user.id);
            final requestSent = outgoingIds.contains(user.id);
            final requestIncoming = incomingIds.contains(user.id);
            final canAdd = !alreadyFriend && !requestSent && !requestIncoming;

            return _userTile(
              user,
              trailing: TextButton(
                onPressed: canAdd && !isActionLoading
                    ? () => ref
                          .read(friendActionsProvider.notifier)
                          .sendFriendRequest(user.id)
                    : null,
                child: Text(
                  alreadyFriend
                      ? 'Friend'
                      : requestSent
                      ? 'Pending'
                      : requestIncoming
                      ? 'Incoming'
                      : 'Add Friend',
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => _loadingBox(),
      error: (error, _) => _compactError(
        message: 'Failed to search users.',
        onRetry: () => ref.invalidate(userSearchProvider),
      ),
    );
  }

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
      error: (error, _) => _compactError(
        message: 'Failed to load this section.',
        onRetry: onRetry,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.subtitle.copyWith(
          color: AppColors.onSurface,
          fontSize: 19,
        ),
      ),
    );
  }

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
      subtitle: Text(
        user.email,
        style: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 12),
      ),
      trailing: trailing,
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

  Set<String> _idsFrom(AsyncValue<List<User>> state) {
    return state.maybeWhen(
      data: (users) => users.map((user) => user.id).toSet(),
      orElse: () => const <String>{},
    );
  }

  String _normalizeError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ') ? message.substring(11) : message;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/friends/services/friend_service.dart';

final friendServiceProvider = Provider<FriendService>((ref) => FriendService());

final friendSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

final userSearchProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  await ref.watch(meProvider.future);

  final search = ref.watch(friendSearchQueryProvider).trim();
  if (search.isEmpty) return const [];

  final service = ref.watch(friendServiceProvider);
  return service.searchUsers(search);
});

final myFriendsProvider = FutureProvider<List<User>>((ref) async {
  await ref.watch(meProvider.future);

  final service = ref.watch(friendServiceProvider);
  return service.fetchMyFriends(limit: 50);
});

final incomingFriendRequestsProvider = FutureProvider<List<User>>((ref) async {
  await ref.watch(meProvider.future);

  final service = ref.watch(friendServiceProvider);
  return service.fetchIncomingRequests();
});

final outgoingFriendRequestsProvider = FutureProvider<List<User>>((ref) async {
  await ref.watch(meProvider.future);

  final service = ref.watch(friendServiceProvider);
  return service.fetchOutgoingRequests();
});

final friendActionsProvider =
    StateNotifierProvider<FriendActionsNotifier, AsyncValue<void>>((ref) {
      return FriendActionsNotifier(ref, ref.watch(friendServiceProvider));
    });

class FriendActionsNotifier extends StateNotifier<AsyncValue<void>> {
  FriendActionsNotifier(this._ref, this._service)
    : super(const AsyncData(null));

  final Ref _ref;
  final FriendService _service;

  Future<void> sendFriendRequest(String userId) async {
    await _run(() async {
      final sent = await _service.sendFriendRequest(userId);
      if (sent) {
        _ref.invalidate(outgoingFriendRequestsProvider);
        _ref.invalidate(userSearchProvider);
      }
    });
  }

  Future<void> acceptFriendRequest(String userId) async {
    await _run(() async {
      final accepted = await _service.acceptFriendRequest(userId);
      if (accepted) {
        _ref.invalidate(incomingFriendRequestsProvider);
        _ref.invalidate(myFriendsProvider);
        _ref.invalidate(userSearchProvider);
      }
    });
  }

  Future<void> rejectFriendRequest(String userId) async {
    await _run(() async {
      final rejected = await _service.rejectFriendRequest(userId);
      if (rejected) {
        _ref.invalidate(incomingFriendRequestsProvider);
        _ref.invalidate(userSearchProvider);
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

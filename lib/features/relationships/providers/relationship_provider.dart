import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/relationships/models/follow_counts.dart';
import 'package:music_app_frontend/features/relationships/models/relationship_status.dart';
import 'package:music_app_frontend/features/relationships/services/relationship_service.dart';

final relationshipServiceProvider = Provider<RelationshipService>(
  (ref) => RelationshipService(),
);

final relationshipStatusProvider = FutureProvider.autoDispose
    .family<RelationshipStatus, String>((ref, userId) async {
      await ref.watch(meProvider.future);

      final service = ref.watch(relationshipServiceProvider);
      return service.getRelationshipStatus(userId);
    });

final followCountsProvider = FutureProvider.autoDispose
    .family<FollowCounts, String>((ref, userId) async {
      await ref.watch(meProvider.future);

      final service = ref.watch(relationshipServiceProvider);
      return service.getFollowCounts(userId);
    });

final myFollowingProvider = FutureProvider<List<User>>((ref) async {
  await ref.watch(meProvider.future);

  final service = ref.watch(relationshipServiceProvider);
  return service.getMyFollowing();
});

final myFollowersProvider = FutureProvider<List<User>>((ref) async {
  await ref.watch(meProvider.future);

  final service = ref.watch(relationshipServiceProvider);
  return service.getMyFollowers();
});

final relationshipActionsProvider =
    StateNotifierProvider<RelationshipActionsNotifier, AsyncValue<void>>((ref) {
      return RelationshipActionsNotifier(
        ref,
        ref.watch(relationshipServiceProvider),
      );
    });

class RelationshipActionsNotifier extends StateNotifier<AsyncValue<void>> {
  RelationshipActionsNotifier(this._ref, this._service)
    : super(const AsyncData(null));

  final Ref _ref;
  final RelationshipService _service;

  Future<void> followUser(String userId) async {
    await _run(() async {
      final followed = await _service.followUser(userId);
      if (followed) {
        _invalidateRelationshipProviders(userId);
      }
    });
  }

  Future<void> unfollowUser(String userId) async {
    await _run(() async {
      final unfollowed = await _service.unfollowUser(userId);
      if (unfollowed) {
        _invalidateRelationshipProviders(userId);
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

  void _invalidateRelationshipProviders(String userId) {
    _ref.invalidate(relationshipStatusProvider(userId));
    _ref.invalidate(followCountsProvider(userId));
    _ref.invalidate(myFollowingProvider);
    _ref.invalidate(myFollowersProvider);
  }
}

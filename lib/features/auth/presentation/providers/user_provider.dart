import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/auth/data/services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final meProvider = FutureProvider<User>((ref) async {
  final service = ref.watch(userServiceProvider);
  return service.fetchMe();
});

final usernameUpdateProvider =
    StateNotifierProvider<UsernameUpdateNotifier, AsyncValue<User?>>((ref) {
      return UsernameUpdateNotifier(ref, ref.watch(userServiceProvider));
    });

final switchToProfessionalAccountProvider =
    StateNotifierProvider<
      SwitchToProfessionalAccountNotifier,
      AsyncValue<User?>
    >((ref) {
      return SwitchToProfessionalAccountNotifier(
        ref,
        ref.watch(userServiceProvider),
      );
    });

class UsernameUpdateNotifier extends StateNotifier<AsyncValue<User?>> {
  UsernameUpdateNotifier(this._ref, this._service)
    : super(const AsyncData(null));

  final Ref _ref;
  final UserService _service;

  Future<User?> updateUsername({
    required User currentUser,
    required String username,
  }) async {
    final normalizedUsername = username.trim();
    state = const AsyncLoading();

    try {
      _validateUsername(normalizedUsername);

      if (normalizedUsername == currentUser.username.trim()) {
        state = AsyncData(currentUser);
        return currentUser;
      }

      final isAvailable = await _service.isUsernameAvailable(
        username: normalizedUsername,
        currentUserId: currentUser.id,
      );

      if (!isAvailable) {
        throw Exception('Username is already taken');
      }

      final updatedUser = await _service.updateUsername(normalizedUsername);
      _ref.invalidate(meProvider);
      state = AsyncData(updatedUser);
      return updatedUser;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  void clear() {
    state = const AsyncData(null);
  }

  void _validateUsername(String username) {
    if (username.length < 3) {
      throw Exception('Username must be at least 3 characters');
    }

    if (username.length > 30) {
      throw Exception('Username cannot be longer than 30 characters');
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      throw Exception('Use only letters, numbers, and underscores');
    }
  }
}

class SwitchToProfessionalAccountNotifier
    extends StateNotifier<AsyncValue<User?>> {
  SwitchToProfessionalAccountNotifier(this._ref, this._service)
    : super(const AsyncData(null));

  final Ref _ref;
  final UserService _service;

  Future<User?> switchToProfessionalAccount() async {
    state = const AsyncLoading();

    try {
      final updatedUser = await _service.switchToProfessionalAccount();
      _ref.invalidate(meProvider);
      state = AsyncData(updatedUser);
      return updatedUser;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  void clear() {
    state = const AsyncData(null);
  }
}

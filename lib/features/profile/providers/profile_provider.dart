import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/profile/models/profile_model.dart';

final profileProvider = FutureProvider<ProfileModel>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    throw StateError('No authenticated user');
  }

  final user = await ref.watch(meProvider.future);
  return user.toProfileModel();
});

extension on User {
  ProfileModel toProfileModel() {
    return ProfileModel(
      name: username,
      email: email,
      avatarUrl: profileImageUrl,
      followers: 0,
      following: 0,
      playlists: const [],
    );
  }
}

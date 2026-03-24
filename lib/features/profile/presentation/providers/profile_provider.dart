import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/profile/data/services/profile_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileNotifier  –  manages and mutates the profile state
// ─────────────────────────────────────────────────────────────────────────────
class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel>> {
  ProfileNotifier() : super(const AsyncValue.loading()) {
    fetchProfile(); // auto-fetch when provider is created
  }

  /// Fetch profile from API
  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Replace with real API call
      await Future.delayed(const Duration(milliseconds: 600));

      state = AsyncValue.data(
        ProfileModel(
          name: 'Kheang Ann',
          email: 'kheangann@gmail.com',
          avatarUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTmXq1tnSCYbI-u3RouvLiSi23pAvpaSgtsOw&s', // TODO: pass real avatar URL from API
          followers: 1,
          following: 1,
          playlists: const [
            PlaylistItem(
              id: '1',
              title: 'playlist by Angsopheary',
              thumbnailUrl: null,
            ),
            PlaylistItem(
              id: '2',
              title: 'playlist by Vvo',
              thumbnailUrl: null,
            ),
          ],
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Call this after editing profile to update the state
  void updateProfile(ProfileModel updated) {
    state = AsyncValue.data(updated);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider  –  expose ProfileNotifier to the widget tree
// ─────────────────────────────────────────────────────────────────────────────
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileModel>>(
  (ref) => ProfileNotifier(),
);
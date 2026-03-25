// ─────────────────────────────────────────────────────────────────────────────
// TIER 1 — DATA LAYER
// Path: lib/features/profile/data/services/profile_service.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:music_app_frontend/features/profile/data/services/profile_model.dart';

class ProfileService {
  /// Fetch user profile from API
  Future<ProfileModel> fetchProfile() async {
    try {
      // TODO: Replace with real HTTP call e.g:
      // final response = await http.get(Uri.parse('https://your-api.com/profile'));
      // final json = jsonDecode(response.body);
      // return ProfileModel.fromJson(json);

      // ── Simulated API response ─────────────────────────────────────────
      await Future.delayed(const Duration(milliseconds: 600));

      return const ProfileModel(
        name: 'Kheang Ann',
        email: 'kheangann@gmail.com',
        avatarUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTmXq1tnSCYbI-u3RouvLiSi23pAvpaSgtsOw&s',
        followers: 1,
        following: 1,
        playlists: [
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
      );
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Update user profile via API
  Future<ProfileModel> updateProfile(ProfileModel updatedProfile) async {
    try {
      // TODO: Replace with real HTTP call e.g:
      // final response = await http.put(
      //   Uri.parse('https://your-api.com/profile'),
      //   body: jsonEncode(updatedProfile.toJson()),
      // );

      // ── Simulated API response ─────────────────────────────────────────
      await Future.delayed(const Duration(milliseconds: 400));
      return updatedProfile;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
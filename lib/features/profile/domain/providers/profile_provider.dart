// ─────────────────────────────────────────────────────────────────────────────
// TIER 2 — DOMAIN LAYER
// Path: lib/features/profile/domain/providers/profile_provider.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/profile/data/services/profile_model.dart';
import 'package:music_app_frontend/features/profile/data/services/profile_service.dart';

// ── Expose ProfileService to Riverpod ─────────────────────────────────────────
final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(),
);

// ── ProfileNotifier: manages state, calls Tier 1 ──────────────────────────────
class ProfileNotifier extends StateNotifier<AsyncValue<ProfileModel>> {
  final ProfileService _service;

  ProfileNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchProfile(); // auto-fetch when provider is first created
  }

  /// Fetch profile → delegates to Tier 1 service
  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _service.fetchProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update profile → delegates to Tier 1 service
  Future<void> updateProfile(ProfileModel updatedProfile) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _service.updateProfile(updatedProfile);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ── Expose ProfileNotifier to the widget tree ─────────────────────────────────
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileModel>>(
  (ref) => ProfileNotifier(
    ref.read(profileServiceProvider), // inject Tier 1 into Tier 2
  ),
);
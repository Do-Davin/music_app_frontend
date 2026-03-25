// ─────────────────────────────────────────────────────────────────────────────
// TIER 1 — DATA LAYER
// Path: lib/features/profile/data/services/profile_model.dart
// ─────────────────────────────────────────────────────────────────────────────

class ProfileModel {
  final String name;
  final String email;
  final String? avatarUrl;
  final int followers;
  final int following;
  final List<PlaylistItem> playlists;

  const ProfileModel({
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.followers,
    required this.following,
    required this.playlists,
  });

  ProfileModel copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    int? followers,
    int? following,
    List<PlaylistItem>? playlists,
  }) {
    return ProfileModel(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      playlists: playlists ?? this.playlists,
    );
  }
}

class PlaylistItem {
  final String id;
  final String title;
  final String? thumbnailUrl;

  const PlaylistItem({
    required this.id,
    required this.title,
    this.thumbnailUrl,
  });
}
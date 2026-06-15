import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/auth/data/services/token_storage_service.dart';

class RecentSongsNotifier extends StateNotifier<List<Song>> {
  static const _baseKey = 'recent_songs';
  String? _userId;

  RecentSongsNotifier() : super([]) {
    _initAndLoad();
  }

  /// Derives a per-user storage key so each account has its own recent list.
  String get _storageKey =>
      _userId != null ? '${_baseKey}_$_userId' : _baseKey;

  /// Extracts the userId from the JWT token to scope recent songs per account.
  Future<void> _initAndLoad() async {
    _userId = await _extractUserId();
    await _loadRecentSongs();
  }

  /// Decodes the JWT access token to extract the user ID (sub claim).
  Future<String?> _extractUserId() async {
    try {
      const tokenService = TokenStorageService();
      final token = await tokenService.readAccessToken();
      if (token == null || token.isEmpty) return null;

      // JWT has 3 parts separated by '.', payload is the second part
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Base64 decode the payload
      String payload = parts[1];
      // Add padding if necessary
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> data = jsonDecode(decoded);
      return data['sub']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadRecentSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];
    if (!mounted) return;
    state = jsonList.map((s) => Song.fromJson(jsonDecode(s))).toList();
  }

  Future<void> addSong(Song song) async {
    // Remove if already exists to move to top
    final newState = [...state];
    newState.removeWhere((s) => s.id == song.id);
    newState.insert(0, song);

    // Limit to 10 recent songs
    if (newState.length > 10) {
      newState.removeLast();
    }

    state = newState;
    await _persist();
  }

  /// Remove a single song from the recent list.
  Future<void> removeSong(String songId) async {
    final newState = [...state];
    newState.removeWhere((s) => s.id == songId);
    state = newState;
    await _persist();
  }

  Future<void> clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Called on logout/account switch to reset state for the next user.
  void reset() {
    state = [];
    _userId = null;
  }

  /// Reload recent songs for the current user (call after login).
  Future<void> reload() async {
    _userId = await _extractUserId();
    await _loadRecentSongs();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }
}

final recentSongsProvider =
    StateNotifierProvider<RecentSongsNotifier, List<Song>>((ref) {
  return RecentSongsNotifier();
});

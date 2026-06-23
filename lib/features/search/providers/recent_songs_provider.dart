import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart' as model;
import 'package:music_app_frontend/features/auth/data/services/token_storage_service.dart';

class RecentItemsNotifier extends StateNotifier<List<dynamic>> {
  static const _baseKey = 'recent_items';
  String? _userId;

  RecentItemsNotifier() : super([]) {
    _initAndLoad();
  }

  /// Derives a per-user storage key so each account has its own recent list.
  String get _storageKey => _userId != null ? '${_baseKey}_$_userId' : _baseKey;

  /// Extracts the userId from the JWT token to scope recent items per account.
  Future<void> _initAndLoad() async {
    _userId = await _extractUserId();
    await _loadRecentItems();
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

  Future<void> _loadRecentItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];
    if (!mounted) return;
    
    final List<dynamic> loadedItems = [];
    for (final s in jsonList) {
      try {
        final Map<String, dynamic> json = jsonDecode(s);
        if (json['item_type'] == 'playlist') {
          loadedItems.add(model.Playlist.fromJson(json));
        } else {
          // Default to Song for backwards compatibility
          loadedItems.add(Song.fromJson(json));
        }
      } catch (e) {
        // Skip invalid items
      }
    }
    state = loadedItems;
  }

  Future<void> addItem(dynamic item) async {
    if (item is! Song && item is! model.Playlist) return;

    final newState = [...state];
    // Remove if already exists to move to top
    final itemId = item is Song ? item.id : (item as model.Playlist).id;
    newState.removeWhere((s) {
      final sId = s is Song ? s.id : (s as model.Playlist).id;
      return sId == itemId;
    });
    
    newState.insert(0, item);

    // Limit to 10 recent items
    if (newState.length > 10) {
      newState.removeLast();
    }

    state = newState;
    await _persist();
  }

  /// Remove a single item from the recent list.
  Future<void> removeItem(String itemId) async {
    final newState = [...state];
    newState.removeWhere((s) {
      final sId = s is Song ? s.id : (s as model.Playlist).id;
      return sId == itemId;
    });
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

  /// Reload recent items for the current user (call after login).
  Future<void> reload() async {
    _userId = await _extractUserId();
    await _loadRecentItems();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((s) {
      if (s is model.Playlist) {
        final json = s.toJson();
        json['item_type'] = 'playlist';
        return jsonEncode(json);
      } else if (s is Song) {
        final json = s.toJson();
        json['item_type'] = 'song';
        return jsonEncode(json);
      }
      return '{}';
    }).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }
}

final recentItemsProvider =
    StateNotifierProvider<RecentItemsNotifier, List<dynamic>>((ref) {
      return RecentItemsNotifier();
    });

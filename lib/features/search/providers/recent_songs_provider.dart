import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app_frontend/features/song/models/song.dart';

class RecentSongsNotifier extends StateNotifier<List<Song>> {
  static const _key = 'recent_songs';

  RecentSongsNotifier() : super([]) {
    _loadRecentSongs();
  }

  Future<void> _loadRecentSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    state = jsonList.map((s) => Song.fromJson(jsonDecode(s))).toList();
  }

  Future<void> addSong(Song song) async {
    // Remove if already exists to move to top
    final newState = [...state];
    newState.removeWhere((s) => s.id == song.id);
    newState.insert(0, song);
    
    // Limit to 5 or something reasonable
    if (newState.length > 5) {
      newState.removeLast();
    }
    
    state = newState;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  Future<void> clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final recentSongsProvider = StateNotifierProvider<RecentSongsNotifier, List<Song>>((ref) {
  return RecentSongsNotifier();
});

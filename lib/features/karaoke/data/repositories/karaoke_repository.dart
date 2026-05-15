import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/karaoke_song.dart';

class KaraokeRepository {
  static const String _storageKey = 'karaoke_songs';

  Future<List<KaraokeSong>> getAllSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) return [];

    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((j) => KaraokeSong.fromJson(j)).toList();
  }

  Future<void> saveSong(KaraokeSong song) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getAllSongs();

    // Replace if exists, otherwise add
    final index = existing.indexWhere((s) => s.id == song.id);
    if (index >= 0) {
      existing[index] = song;
    } else {
      existing.add(song);
    }

    final encoded = jsonEncode(existing.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> deleteSong(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getAllSongs();
    existing.removeWhere((s) => s.id == id);

    final encoded = jsonEncode(existing.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/services/song_service.dart';

final songServiceProvider = Provider<SongService>((ref) => SongService());

final songsProvider = FutureProvider<List<Song>>((ref) async {
  final service = ref.watch(songServiceProvider);
  return service.fetchSongs();
});

final mySongsProvider = FutureProvider<List<Song>>((ref) async {
  final service = ref.watch(songServiceProvider);
  return service.fetchMySongs();
});

final songByIdProvider = FutureProvider.family<Song, String>((ref, id) async {
  final service = ref.watch(songServiceProvider);
  return service.fetchSongById(id);
});

final searchSongsProvider = FutureProvider.family<List<Song>, String>((
  ref,
  query,
) async {
  final cleanQuery = query.trim();
  if (cleanQuery.isEmpty) return [];
  final service = ref.watch(songServiceProvider);
  return service.searchSongs(cleanQuery);
});

/// Debounced search query — updates 400 ms after the user stops typing.
/// Use this provider for the search text field to avoid firing a network
/// request on every keystroke.
final debouncedSearchQueryProvider =
    StateNotifierProvider<DebouncedSearchNotifier, String>(
      (ref) => DebouncedSearchNotifier(),
    );

class DebouncedSearchNotifier extends StateNotifier<String> {
  Timer? _timer;

  DebouncedSearchNotifier() : super('');

  void update(String query) {
    _timer?.cancel();
    if (query.isEmpty) {
      // Clear immediately so the UI reacts right away
      state = '';
      return;
    }
    _timer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) state = query;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

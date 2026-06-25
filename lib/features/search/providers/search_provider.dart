import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/song/providers/song_provider.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart' as model;
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';

// Provider to manage the raw (un-debounced) search query for the text field UI.
final searchQueryProvider = StateProvider<String>((ref) => "");
final searchTabProvider = StateProvider<String>((ref) => "All");

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

final searchAllProvider = FutureProvider.family<List<dynamic>, String>((ref, query) async {
  final cleanQuery = query.trim();
  if (cleanQuery.isEmpty) return [];

  // Fetch both concurrently using watch on their future
  final songsFuture = ref.watch(searchSongsProvider(cleanQuery).future);
  final playlistsFuture = ref.watch(searchPlaylistsProvider(cleanQuery).future);

  List<Song> songs = [];
  List<model.Playlist> playlists = [];

  try {
    songs = await songsFuture;
  } catch (e) {
    debugPrint('Error searching songs: $e');
  }

  try {
    playlists = await playlistsFuture;
  } catch (e) {
    debugPrint('Error searching playlists: $e');
  }

  // Combine lists
  final combined = <dynamic>[...songs, ...playlists];
  final me = ref.watch(meProvider).valueOrNull;

  // Sort: user's own items first
  combined.sort((a, b) {
    final aIsMine = _isItemOwnedByUser(a, me?.id);
    final bIsMine = _isItemOwnedByUser(b, me?.id);
    if (aIsMine && !bIsMine) return -1;
    if (!aIsMine && bIsMine) return 1;
    return 0;
  });

  return combined;
});

bool _isItemOwnedByUser(dynamic item, String? currentUserId) {
  if (currentUserId == null) return false;
  if (item is Song) {
    return item.userId == currentUserId;
  } else if (item is model.Playlist) {
    return item.userId == currentUserId;
  }
  return false;
}

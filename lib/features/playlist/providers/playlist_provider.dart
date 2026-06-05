import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';

final playlistServiceProvider = Provider((ref) => PlaylistService());

final myPlaylistsProvider =
    StateNotifierProvider<MyPlaylistsNotifier, AsyncValue<List<Playlist>>>((
      ref,
    ) {
      return MyPlaylistsNotifier(ref.watch(playlistServiceProvider));
    });

class MyPlaylistsNotifier extends StateNotifier<AsyncValue<List<Playlist>>> {
  final PlaylistService _service;

  MyPlaylistsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    state = const AsyncValue.loading();
    try {
      final playlists = await _service.getMyPlaylists();
      state = AsyncValue.data(playlists);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reload playlists from network without setting loading state first.
  /// This avoids flicker and keeps the current data visible while refreshing.
  Future<void> refreshPlaylists() async {
    try {
      final playlists = await _service.getMyPlaylists();
      if (mounted) {
        state = AsyncValue.data(playlists);
      }
    } catch (e) {
      debugPrint('Error refreshing playlists: $e');
      // Keep current state on error during refresh
    }
  }

  /// Replace a single playlist in the current state with an updated version.
  /// This is used after mutations (add/remove song) to immediately reflect
  /// changes without a full network refetch.
  void updatePlaylist(Playlist updated) {
    state.whenData((playlists) {
      final index = playlists.indexWhere((p) => p.id == updated.id);
      if (index != -1) {
        final newList = [...playlists];
        newList[index] = updated;
        state = AsyncValue.data(newList);
      } else {
        // Playlist not in list yet (e.g. just created), append it
        state = AsyncValue.data([...playlists, updated]);
      }
    });
  }

  Future<void> createPlaylist(String name, {String? description}) async {
    try {
      final newPlaylist = await _service.createPlaylist(
        name,
        description: description,
      );

      final currentPlaylists = state.value ?? [];
      state = AsyncValue.data([...currentPlaylists, newPlaylist]);

      debugPrint('Successfully created playlist: ${newPlaylist.name}');
    } catch (e, st) {
      debugPrint('Error creating playlist: $e');
      debugPrint('$st');
    }
  }

  Future<void> deletePlaylist(String id) async {
    try {
      final success = await _service.removePlaylist(id);
      if (success) {
        state.whenData((playlists) {
          state = AsyncValue.data(playlists.where((p) => p.id != id).toList());
        });
      }
    } catch (e) {
      // Handle error
    }
  }
}

/// Single source of truth: derives playlist details from the master list.
/// When myPlaylistsProvider is updated (via updatePlaylist / refreshPlaylists),
/// any screen watching this provider automatically gets the fresh data.
final playlistByIdProvider = Provider.family<AsyncValue<Playlist>, String>((
  ref,
  id,
) {
  final playlistsAsync = ref.watch(myPlaylistsProvider);
  return playlistsAsync.when(
    data: (playlists) {
      try {
        final playlist = playlists.firstWhere((p) => p.id == id);
        return AsyncValue.data(playlist);
      } catch (_) {
        return AsyncValue.error('Playlist not found', StackTrace.current);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

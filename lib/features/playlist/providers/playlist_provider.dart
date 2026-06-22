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
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final playlists = await _service.getMyPlaylists();
      if (mounted) state = AsyncValue.data(playlists);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
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
  void updatePlaylist(Playlist updated) {
    if (!mounted) return;
    state.whenData((playlists) {
      if (!mounted) return;
      final index = playlists.indexWhere((p) => p.id == updated.id);
      if (index != -1) {
        final newList = [...playlists];
        newList[index] = updated;
        state = AsyncValue.data(newList);
      } else {
        state = AsyncValue.data([...playlists, updated]);
      }
    });
  }

  void removeSongLocally(String playlistId, String songId) {
    if (!mounted) return;
    state.whenData((playlists) {
      if (!mounted) return;
      final index = playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        final p = playlists[index];
        final newSongs = p.songs?.where((s) => s.id != songId).toList();
        final newSongIds = p.songIds?.where((id) => id != songId).toList();
        final updated = p.copyWith(songs: newSongs, songIds: newSongIds);
        final newList = [...playlists];
        newList[index] = updated;
        state = AsyncValue.data(newList);
      }
    });
  }

  Future<Playlist?> createPlaylist(String name, {String? description, bool isPublic = false}) async {
    try {
      final newPlaylist = await _service.createPlaylist(
        name,
        description: description,
        isPublic: isPublic,
      );
      if (!mounted) return newPlaylist;
      final currentPlaylists = state.value ?? [];
      state = AsyncValue.data([...currentPlaylists, newPlaylist]);
      debugPrint('Successfully created playlist: ${newPlaylist.name}');
      return newPlaylist;
    } catch (e, st) {
      debugPrint('Error creating playlist: $e');
      debugPrint('$st');
      return null;
    }
  }

  Future<void> deletePlaylist(String id) async {
    try {
      final success = await _service.removePlaylist(id);
      if (success && mounted) {
        state.whenData((playlists) {
          if (mounted) {
            state = AsyncValue.data(
              playlists.where((p) => p.id != id).toList(),
            );
          }
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
final playlistByIdProvider = FutureProvider.family<Playlist, String>((ref, id) async {
  final playlistsAsync = ref.watch(myPlaylistsProvider);
  final playlist = playlistsAsync.when(
    data: (playlists) {
      try {
        return playlists.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (err, stack) => null,
  );

  if (playlist != null) {
    return playlist;
  }

  // Fetch from backend server if not in the local library lists
  final service = ref.watch(playlistServiceProvider);
  return await service.getPlaylistById(id);
});

final searchPlaylistsProvider =
    FutureProvider.family<List<Playlist>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final service = ref.watch(playlistServiceProvider);
  return service.searchPlaylists(query);
});

final likedSongsPlaylistProvider = FutureProvider<Playlist>((ref) async {
  return ref.watch(playlistServiceProvider).getLikedSongsPlaylist();
});

final isSongInLikedSongsProvider = FutureProvider.family<bool, String>((
  ref,
  songId,
) async {
  return ref.watch(playlistServiceProvider).isSongInLikedSongs(songId);
});

final toggleSongInLikedSongsProvider = FutureProvider.family<bool, String>((
  ref,
  songId,
) async {
  return ref.watch(playlistServiceProvider).toggleSongInLikedSongs(songId);
});

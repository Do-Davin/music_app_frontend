import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist.dart';
import '../services/playlist_service.dart';

final playlistServiceProvider = Provider((ref) => PlaylistService());

final myPlaylistsProvider = StateNotifierProvider<MyPlaylistsNotifier, AsyncValue<List<Playlist>>>((ref) {
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

  Future<void> createPlaylist(String name, {String? description}) async {
    try {
      final newPlaylist = await _service.createPlaylist(name, description: description);
      
      final currentPlaylists = state.value ?? [];
      state = AsyncValue.data([...currentPlaylists, newPlaylist]);
      
      print('Successfully created playlist: ${newPlaylist.name}');
    } catch (e, st) {
      print('Error creating playlist: $e');
      print(st);
      // Optional: you could set state to error here, but usually better to keep 
      // existing list and show a toast.
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

final playlistByIdProvider = FutureProvider.family<Playlist, String>((ref, id) async {
  return ref.watch(playlistServiceProvider).getPlaylistById(id);
});

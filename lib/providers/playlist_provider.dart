import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/models/playlist.dart';
import 'package:music_app_frontend/services/playlist_service.dart';

final playlistServiceProvider =
    Provider<PlaylistService>((ref) => PlaylistService());

final playlistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final service = ref.read(playlistServiceProvider);
  return service.fetchPlaylists();
});

final playlistByIdProvider =
    FutureProvider.family<Playlist, String>((ref, id) async {
  final service = ref.read(playlistServiceProvider);
  return service.fetchPlaylistById(id);
});

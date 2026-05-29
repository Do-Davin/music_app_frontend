import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/services/song_service.dart';

final songServiceProvider = Provider<SongService>((ref) => SongService());

final songsProvider = FutureProvider<List<Song>>((ref) async {
  final service = ref.watch(songServiceProvider);
  return service.fetchSongs();
});

final songByIdProvider = FutureProvider.family<Song, String>((ref, id) async {
  final service = ref.watch(songServiceProvider);
  return service.fetchSongById(id);
});

final searchSongsProvider = FutureProvider.family<List<Song>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];
  final service = ref.watch(songServiceProvider);
  return service.searchSongs(query);
});

final isSongFavoriteProvider = FutureProvider.family<bool, String>((
  ref,
  songId,
) async {
  final service = ref.watch(songServiceProvider);
  return service.isSongFavorite(songId);
});

final myFavoriteSongsProvider = FutureProvider<List<Song>>((ref) async {
  final service = ref.watch(songServiceProvider);
  return service.getMyFavoriteSongs();
});

final toggleFavoriteSongProvider = FutureProvider.family<bool, String>((
  ref,
  songId,
) async {
  final service = ref.watch(songServiceProvider);
  return service.toggleFavoriteSong(songId);
});

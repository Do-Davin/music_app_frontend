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

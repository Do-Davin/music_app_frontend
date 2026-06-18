import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/services/recently_played_service.dart';

class RecentlyPlayedEntry {
  final Song song;
  final DateTime playedAt;

  const RecentlyPlayedEntry({required this.song, required this.playedAt});
}

final recentlyPlayedServiceProvider = Provider<RecentlyPlayedService>(
  (ref) => RecentlyPlayedService(),
);

final recentlyPlayedProvider = FutureProvider<List<RecentlyPlayedEntry>>((
  ref,
) async {
  final service = ref.watch(recentlyPlayedServiceProvider);
  return service.fetchRecentlyPlayed(limit: 20);
});

import 'package:music_app_frontend/features/karaoke/data/models/karaoke_song.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'youtube_parser.dart';

/// Helper to determine if a KaraokeSong matches a Library Song.
bool isSongMatch(KaraokeSong karaoke, Song song) {
  if (karaoke.id == song.id) return true;

  final titleMatches =
      karaoke.title.trim().toLowerCase() == song.title.trim().toLowerCase();
  if (!titleMatches) return false;

  final songUrl = song.audioUrl;
  if (songUrl == null) return false;

  final songIsYoutube = song.isYoutube;
  final karaokeIsYoutube = karaoke.source == SongSource.youtube ||
      karaoke.sourcePath.contains('youtube.com') ||
      karaoke.sourcePath.contains('youtu.be') ||
      extractYoutubeId(karaoke.sourcePath) != null;

  if (songIsYoutube && karaokeIsYoutube) {
    final songYtId = extractYoutubeId(songUrl);
    final karaokeYtId = extractYoutubeId(karaoke.sourcePath);
    if (songYtId != null && karaokeYtId != null) {
      return songYtId == karaokeYtId;
    }
  } else if (!songIsYoutube && !karaokeIsYoutube) {
    final songFilename = songUrl.split('/').last.split('\\').last;
    final karaokeFilename =
        karaoke.sourcePath.split('/').last.split('\\').last;
    if (songFilename.isNotEmpty && karaokeFilename.isNotEmpty) {
      return songFilename == karaokeFilename;
    }
  }

  // Fallback to artist match only if type mismatch or we couldn't extract IDs
  final artistMatches =
      (karaoke.artist?.trim().toLowerCase() ?? '') ==
      song.artist.trim().toLowerCase();
  return artistMatches;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart';
import 'package:music_app_frontend/features/karaoke/data/models/karaoke_song.dart';
import 'package:music_app_frontend/features/karaoke/presentation/controllers/karaoke_controller.dart';
import '../widgets/karaoke_options_sheet.dart';
import 'player_screen.dart';
import 'lyric_editor_screen.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';

class KaraokePlaylistSongsScreen extends ConsumerWidget {
  final Playlist playlist;
  final KaraokeController controller;

  const KaraokePlaylistSongsScreen({
    super.key,
    required this.playlist,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).valueOrNull;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        // Filter: only karaoke songs whose ID is in playlist.songs or playlist.songIds
        final playlistSongs = controller.songs.where((ks) {
          final inSongs = playlist.songs?.any((s) => s.id == ks.id) ?? false;
          final inSongIds = playlist.songIds?.contains(ks.id) ?? false;
          return inSongs || inSongIds;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              playlist.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: playlistSongs.isEmpty
              ? Center(
                  child: Text(
                    'No karaoke songs in this playlist yet.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: playlistSongs.length,
                  itemBuilder: (context, index) {
                    final song = playlistSongs[index];
                    final hasLyrics = song.lyrics.isNotEmpty;
                    
                    final isOwner = me != null && song.userId == me.id;
                    final badgeText = isOwner
                        ? (song.isPublic ? 'Yours • Public' : 'Yours • Private')
                        : (song.isPublic ? 'Public' : 'Private');
                    final badgeColor = isOwner
                        ? (song.isPublic ? AppColors.primary : Colors.orangeAccent)
                        : (song.isPublic ? Colors.blue : Colors.grey);

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: song.source == SongSource.youtube
                                ? Colors.red.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            song.source == SongSource.youtube
                                ? Icons.play_circle_filled
                                : Icons.music_note,
                            color: song.source == SongSource.youtube
                                ? Colors.red
                                : AppColors.primary,
                          ),
                        ),
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                song.title,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: badgeColor.withValues(alpha: 0.4),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          song.artist ?? 'Unknown Artist',
                          style: const TextStyle(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white70),
                          onPressed: () {
                            showKaraokeOptionsSheet(
                              context: context,
                              ref: ref,
                              song: song,
                              controller: controller,
                            );
                          },
                        ),
                        onTap: () {
                          if (hasLyrics) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlayerScreen(song: song, controller: controller),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LyricEditorScreen(song: song, controller: controller),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

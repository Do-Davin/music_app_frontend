import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/karaoke_controller.dart';
import '../../data/models/karaoke_song.dart';
import 'lyric_editor_screen.dart';
import 'player_screen.dart';

class SongListScreen extends StatelessWidget {
  const SongListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<KaraokeController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
          );
        }

        if (controller.songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  'No songs yet\nTap + to add one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.songs.length,
          itemBuilder: (context, index) {
            final song = controller.songs[index];
            return _SongCard(
              song: song,
              onTap: () {
                if (song.lyrics.isEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LyricEditorScreen(
                        song: song,
                        controller: controller, // ← Pass controller
                      ),
                    ),
                  );
                } else {
                  // Has lyrics - go to player
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        song: song,
                        controller: controller, // ← Pass controller
                      ),
                    ),
                  );
                }
              },
              onDelete: () => controller.deleteSong(song.id),
            );
          },
        );
      },
    );
  }
}

class _SongCard extends StatelessWidget {
  final KaraokeSong song;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SongCard({
    required this.song,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasLyrics = song.lyrics.isNotEmpty;

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: song.source == SongSource.youtube
                ? Colors.red.withValues(alpha: 0.2)
                : const Color(0xFF7C4DFF).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            song.source == SongSource.youtube
                ? Icons.play_circle_filled
                : Icons.music_note,
            color: song.source == SongSource.youtube
                ? Colors.red
                : const Color(0xFF7C4DFF),
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (song.artist != null)
              Text(song.artist!, style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  hasLyrics ? Icons.check_circle : Icons.pending,
                  size: 14,
                  color: hasLyrics ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  hasLyrics ? 'Ready to play' : 'Needs lyrics',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasLyrics ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasLyrics)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PLAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    title: const Text(
                      'Delete?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Text(
                      'Delete "${song.title}"?',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          onDelete();
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../data/models/karaoke_song.dart';

class SongCard extends StatelessWidget {
  final KaraokeSong song;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SongCard({
    super.key,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Source icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: song.source == SongSource.youtube
                      ? Colors.red.withValues(alpha: 0.15)
                      : const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    song.source == SongSource.youtube
                        ? Icons.play_circle_filled
                        : Icons.music_note,
                    color: song.source == SongSource.youtube
                        ? Colors.red
                        : const Color(0xFF7C4DFF),
                    size: 28,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (song.artist != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        song.artist!,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: hasLyrics
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hasLyrics ? 'Ready' : 'Needs Lyrics',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: hasLyrics ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${song.lyrics.length} lines',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

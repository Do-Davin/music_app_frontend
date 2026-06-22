import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/features/karaoke/data/models/karaoke_song.dart';
import 'package:music_app_frontend/features/karaoke/presentation/controllers/karaoke_controller.dart';
import 'lyric_editor_screen.dart';
import 'player_screen.dart';

class KaraokeDetailScreen extends StatelessWidget {
  final KaraokeSong song;
  final KaraokeController controller;

  const KaraokeDetailScreen({
    super.key,
    required this.song,
    required this.controller,
  });

  void _showDeleteDialog(BuildContext context, KaraokeSong currentSong) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Delete "${currentSong.title}" from your karaoke list?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              controller.deleteSong(currentSong.id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close detail screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final currentSong = controller.songs.firstWhere(
          (s) => s.id == song.id,
          orElse: () => song,
        );
        final hasLyrics = currentSong.lyrics.isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Karaoke Detail', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Beautiful Cover Artwork / Rotating Disc style placeholder
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.4),
                            const Color(0xFF8E2DE2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1E1E1E),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.mic_none_outlined,
                              size: 80,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Song Info
                  Text(
                    currentSong.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentSong.artist ?? 'Unknown Artist',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: hasLyrics ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasLyrics ? Colors.green : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasLyrics ? Icons.check_circle : Icons.pending_actions_rounded,
                              color: hasLyrics ? Colors.green : Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasLyrics ? 'Ready' : 'No Lyrics',
                              style: TextStyle(
                                color: hasLyrics ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: currentSong.isPublic ? Colors.blue.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: currentSong.isPublic ? Colors.blue : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              currentSong.isPublic ? Icons.public : Icons.lock,
                              color: currentSong.isPublic ? Colors.blue : Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              currentSong.isPublic ? 'Public' : 'Private',
                              style: TextStyle(
                                color: currentSong.isPublic ? Colors.blue : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Sing / Play Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    icon: Icon(hasLyrics ? Icons.play_arrow_rounded : Icons.edit_note, size: 28),
                    label: Text(
                      hasLyrics ? 'Sing Karaoke' : 'Add Lyrics First',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      if (hasLyrics) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(song: currentSong, controller: controller),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LyricEditorScreen(song: currentSong, controller: controller),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  // Option rows for modern UI
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit_rounded, color: Colors.orange),
                          title: const Text('Edit / Adjust Lyrics', style: TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LyricEditorScreen(song: currentSong, controller: controller),
                              ),
                            );
                          },
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        ListTile(
                          leading: Icon(
                            currentSong.isPublic ? Icons.lock_outline : Icons.public,
                            color: Colors.blue,
                          ),
                          title: Text(
                            currentSong.isPublic ? 'Make Private' : 'Make Public',
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
                          onTap: () async {
                            try {
                              await controller.updateSongVisibility(currentSong.id, !currentSong.isPublic);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      !currentSong.isPublic
                                          ? 'Song is now Public'
                                          : 'Song is now Private',
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update visibility: $e')),
                                );
                              }
                            }
                          },
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        ListTile(
                          leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          title: const Text('Remove from Library', style: TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
                          onTap: () => _showDeleteDialog(context, currentSong),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

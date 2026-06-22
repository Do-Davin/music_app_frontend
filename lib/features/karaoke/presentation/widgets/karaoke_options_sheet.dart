import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/features/karaoke/data/models/karaoke_song.dart';
import 'package:music_app_frontend/features/karaoke/presentation/controllers/karaoke_controller.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import '../screens/lyric_editor_screen.dart';
import '../screens/player_screen.dart';

void showKaraokeOptionsSheet({
  required BuildContext context,
  required rp.WidgetRef ref,
  required KaraokeSong song,
  required KaraokeController controller,
}) {
  final me = ref.read(meProvider).valueOrNull;
  final isOwner = me != null && song.userId == me.id;

  // Check if already in own space
  KaraokeSong? matchingOwnSong;
  for (final s in controller.songs) {
    if (s.id == song.id || (s.title.trim().toLowerCase() == song.title.trim().toLowerCase() && s.sourcePath == song.sourcePath)) {
      matchingOwnSong = s;
      break;
    }
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                song.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.artist ?? 'Unknown Artist',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(color: Colors.white24, height: 1),

            // OWNER OPTIONS
            if (isOwner) ...[
              if (song.lyrics.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.mic, color: Colors.purpleAccent),
                  title: const Text('Sing Karaoke', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(song: song, controller: controller),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.orange),
                title: const Text('Edit / Adjust Lyrics', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LyricEditorScreen(song: song, controller: controller),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  song.isPublic ? Icons.lock_outline : Icons.public,
                  color: Colors.blue,
                ),
                title: Text(
                  song.isPublic ? 'Make Private' : 'Make Public',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await controller.updateSongVisibility(song.id, !song.isPublic);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            !song.isPublic
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
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Remove from Library', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteDialog(context, song, controller);
                },
              ),
            ],

            // NON-OWNER OPTIONS
            if (!isOwner) ...[
              if (matchingOwnSong != null) ...[
                if (matchingOwnSong.lyrics.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.mic, color: Colors.purpleAccent),
                    title: const Text('Sing Karaoke', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(song: matchingOwnSong!, controller: controller),
                        ),
                      );
                    },
                  ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.playlist_add, color: Colors.purpleAccent),
                  title: const Text('Add to Karaoke', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    BuildContext? dialogContext;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (c) {
                        dialogContext = c;
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      },
                    );

                    try {
                      final newSong = await controller.addPublicSongToSpace(song);
                      if (dialogContext != null && dialogContext!.mounted) {
                        Navigator.pop(dialogContext!);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to your karaoke space!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (dialogContext != null && dialogContext!.mounted) {
                        Navigator.pop(dialogContext!);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ],
          ],
        ),
      );
    },
  );
}

void _showDeleteDialog(BuildContext context, KaraokeSong song, KaraokeController controller) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Text(
        'Delete "${song.title}" from your karaoke list?',
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            controller.deleteSong(song.id);
            Navigator.pop(ctx); // Close dialog
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

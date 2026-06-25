import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/features/karaoke/data/models/karaoke_song.dart';
import 'package:music_app_frontend/features/karaoke/presentation/controllers/karaoke_controller.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart';
import 'package:music_app_frontend/shared/widgets/success_popup.dart';
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

            ListTile(
              leading: const Icon(Icons.playlist_add, color: AppColors.primary),
              title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddToPlaylistSheetForKaraoke(context, ref, song);
              },
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

void _showAddToPlaylistSheetForKaraoke(BuildContext context, rp.WidgetRef ref, KaraokeSong song) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return rp.Consumer(
        builder: (ctx, ref, _) {
          final playlistsAsync = ref.watch(myPlaylistsProvider);
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add to Playlist',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.add, color: AppColors.primary),
                  title: const Text('Create New Playlist', style: TextStyle(color: Colors.white)),
                  tileColor: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showNewPlaylistAndAddKaraokeSong(context, ref, song);
                  },
                ),
                const SizedBox(height: 12),
                playlistsAsync.when(
                  data: (playlists) {
                    final userPlaylists = playlists.where((p) => p.isKaraoke).toList();
                    if (userPlaylists.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No other playlists yet.', style: TextStyle(color: Colors.grey)),
                      );
                    }
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: userPlaylists.length,
                        itemBuilder: (context, index) {
                          final p = userPlaylists[index];
                          return ListTile(
                            leading: const Icon(Icons.playlist_play, color: AppColors.primary),
                            title: Text(p.name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              '${p.songs?.length ?? p.songIds?.length ?? 0} songs',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                            onTap: () async {
                              Navigator.pop(ctx);
                              _addKaraokeSongToTargetPlaylist(context, ref, p, song);
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _addKaraokeSongToTargetPlaylist(BuildContext context, rp.WidgetRef ref, Playlist targetPlaylist, KaraokeSong song) async {
  final playlistService = ref.read(playlistServiceProvider);
  final myPlaylistsNotifier = ref.read(myPlaylistsProvider.notifier);

  BuildContext? dialogContext;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      dialogContext = ctx;
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    },
  );

  try {
    final updatedPlaylist = await playlistService.addSongToPlaylist(targetPlaylist.id, song.id);
    if (dialogContext != null && dialogContext!.mounted) {
      Navigator.pop(dialogContext!);
    }
    myPlaylistsNotifier.updatePlaylist(updatedPlaylist);
    if (context.mounted) {
      SuccessPopup.show(
        context,
        title: 'Added to "${targetPlaylist.name}"',
        subtitle: '"${song.title}" is now in the playlist',
        icon: Icons.playlist_add_check_rounded,
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
}

void _showNewPlaylistAndAddKaraokeSong(BuildContext context, rp.WidgetRef ref, KaraokeSong song) {
  final playlistService = ref.read(playlistServiceProvider);
  final myPlaylistsNotifier = ref.read(myPlaylistsProvider.notifier);
  final nameCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: nameCtrl,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Playlist Name',
          hintStyle: TextStyle(color: Colors.grey),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(ctx);
            try {
              final newPlaylist = await playlistService.createPlaylist(name, isKaraoke: true);
              final updatedPlaylist = await playlistService.addSongToPlaylist(newPlaylist.id, song.id);
              myPlaylistsNotifier.updatePlaylist(updatedPlaylist);
              if (context.mounted) {
                SuccessPopup.show(
                  context,
                  title: 'Playlist "$name" Created!',
                  subtitle: '"${song.title}" added to it',
                  icon: Icons.library_add_check_rounded,
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
              }
            }
          },
          child: const Text('Create & Add', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

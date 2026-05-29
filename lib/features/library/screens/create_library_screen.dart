import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/song/providers/song_provider.dart';
class CreateLibrarySheet extends ConsumerWidget {
  final BuildContext parentContext;
  const CreateLibrarySheet({super.key, required this.parentContext});

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('New Playlist', style: AppTextStyles.header.copyWith(fontSize: 20)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'Playlist Name',
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.hint),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.body.copyWith(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(myPlaylistsProvider.notifier).createPlaylist(name);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close bottom sheet
              }
            },
            child: Text('Create', style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Show a bottom sheet to choose YouTube or Local MP3, then collect
  /// title + artist and save to the backend as a normal private song.
  void _showAddSongDialog(BuildContext context, WidgetRef ref) {
    Navigator.pop(context); // Close the create-library bottom sheet first safely

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Song',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.link, color: Color(0xFF7C4DFF)),
                title: const Text('YouTube URL', style: TextStyle(color: Colors.white)),
                tileColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showYoutubeInput(parentContext, ref);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.folder, color: Color(0xFF7C4DFF)),
                title: const Text('Local MP3 File', style: TextStyle(color: Colors.white)),
                tileColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLocalInput(parentContext, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showYoutubeInput(BuildContext parentContext, WidgetRef ref) {
    final urlCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('YouTube Song', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(urlCtrl, 'YouTube URL'),
            const SizedBox(height: 12),
            _buildTextField(titleCtrl, 'Song Title'),
            const SizedBox(height: 12),
            _buildTextField(artistCtrl, 'Artist'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = urlCtrl.text.trim();
              final title = titleCtrl.text.trim();
              final artist = artistCtrl.text.trim();
              if (title.isEmpty || artist.isEmpty || url.isEmpty) return;

              final videoId = YoutubePlayer.convertUrlToId(url);
              if (videoId == null) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('Invalid YouTube URL')),
                );
                return;
              }

              Navigator.pop(ctx);
              await _createSongInBackend(
                parentContext, ref,
                title: title,
                artist: artist,
                source: 'youtube',
                sourcePath: videoId,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF)),
            child: const Text('Add Song'),
          ),
        ],
      ),
    );
  }

  void _showLocalInput(BuildContext parentContext, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Local MP3', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(titleCtrl, 'Song Title'),
            const SizedBox(height: 12),
            _buildTextField(artistCtrl, 'Artist'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final artist = artistCtrl.text.trim();
              if (title.isEmpty || artist.isEmpty) return;

              Navigator.pop(ctx);
              await _createSongInBackend(
                parentContext, ref,
                title: title,
                artist: artist,
                source: 'mp3',
                sourcePath: '', // TODO: integrate file picker for upload
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF)),
            child: const Text('Add Song'),
          ),
        ],
      ),
    );
  }

  /// Create the song in the backend, then prompt to add to a playlist.
  Future<void> _createSongInBackend(
    BuildContext parentContext,
    WidgetRef ref, {
    required String title,
    required String artist,
    required String source,
    required String sourcePath,
  }) async {
    // Show loading with dedicated context capture
    BuildContext? dialogContext;
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)));
      },
    );

    try {
      final songService = ref.read(songServiceProvider);
      final backendSong = await songService.createSong(
        title: title,
        artist: artist,
        source: source,
        sourcePath: sourcePath,
      );
      
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(content: Text('✅ Song added to library!')),
        );

        // Prompt to add to a playlist
        _showPlaylistSelectionSheet(parentContext, ref, backendSong.id);
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text('Failed to add song: $e')),
        );
      }
    }
  }

  void _showPlaylistSelectionSheet(BuildContext parentContext, WidgetRef ref, String songId) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final playlistsAsync = ref.watch(myPlaylistsProvider);
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add to Playlist?',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.add, color: Color(0xFF7C4DFF)),
                    title: const Text('Create New Playlist', style: TextStyle(color: Colors.white)),
                    tileColor: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showNewPlaylistAndAddSong(parentContext, ref, songId);
                    },
                  ),
                  const SizedBox(height: 12),
                  playlistsAsync.when(
                    data: (playlists) {
                      if (playlists.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('No playlists yet.', style: TextStyle(color: Colors.grey)),
                        );
                      }
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            final p = playlists[index];
                            return ListTile(
                              leading: const Icon(Icons.playlist_play, color: Color(0xFF7C4DFF)),
                              title: Text(p.name, style: const TextStyle(color: Colors.white)),
                              onTap: () async {
                                Navigator.pop(ctx);
                                try {
                                  await ref.read(playlistServiceProvider).addSongToPlaylist(p.id, songId);
                                  ref.invalidate(myPlaylistsProvider);
                                  if (parentContext.mounted) {
                                    ScaffoldMessenger.of(parentContext).showSnackBar(
                                      SnackBar(content: Text('✅ Added to "${p.name}"')),
                                    );
                                  }
                                } catch (e) {
                                  if (parentContext.mounted) {
                                    ScaffoldMessenger.of(parentContext).showSnackBar(
                                      SnackBar(content: Text('Failed: $e')),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF))),
                    error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Skip', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNewPlaylistAndAddSong(BuildContext parentContext, WidgetRef ref, String songId) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: parentContext,
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
              borderSide: BorderSide(color: Color(0xFF7C4DFF)),
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
                final playlistService = ref.read(playlistServiceProvider);
                final newPlaylist = await playlistService.createPlaylist(name);
                await playlistService.addSongToPlaylist(newPlaylist.id, songId);
                ref.invalidate(myPlaylistsProvider);
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text('✅ Playlist "$name" created & song added!')),
                  );
                }
              } catch (e) {
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: const Text('Create & Add', style: TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Widget _buildTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 30),
          _buildActionItem(
            icon: Icons.music_note,
            iconColor: AppColors.primary,
            title: 'Playlist',
            subtitle: 'Create a playlist with a song',
            onTap: () => _showCreatePlaylistDialog(context, ref),
          ),
          _buildActionItem(
            icon: Icons.people_outline,
            iconColor: AppColors.warning,
            title: 'Collaborative playlist',
            subtitle: 'Create a playlist together',
            onTap: () {},
          ),
          _buildActionItem(
            icon: Icons.bolt,
            iconColor: Colors.purpleAccent,
            title: 'Jam',
            subtitle: 'Listen together from anywhere',
            onTap: () {},
          ),
          _buildActionItem(
            icon: Icons.add_circle_outline,
            iconColor: const Color(0xFF7C4DFF),
            title: 'Add Song',
            subtitle: 'Add from YouTube or local MP3',
            onTap: () => _showAddSongDialog(context, ref),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.surface,
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

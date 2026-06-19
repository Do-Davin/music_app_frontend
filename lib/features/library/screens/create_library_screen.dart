import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart';
import 'package:music_app_frontend/features/song/providers/song_provider.dart';
import 'package:music_app_frontend/shared/widgets/success_popup.dart';

class CreateLibrarySheet extends ConsumerWidget {
  final BuildContext parentContext;
  final WidgetRef parentRef;
  const CreateLibrarySheet({
    super.key,
    required this.parentContext,
    required this.parentRef,
  });

  void _showCreatePlaylistDialog(BuildContext context) {
    final TextEditingController nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'New Playlist',
          style: AppTextStyles.header.copyWith(fontSize: 20),
        ),
        content: TextField(
          controller: nameCtrl,
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
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                parentRef
                    .read(myPlaylistsProvider.notifier)
                    .createPlaylist(name);
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close bottom sheet
              }
            },
            child: Text(
              'Create',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show a bottom sheet to choose YouTube or Local MP3, then collect
  /// title + artist and save to the backend as a normal private song.
  void _showAddSongDialog(BuildContext context) {
    Navigator.pop(
      context,
    ); // Close the create-library bottom sheet first safely

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
                leading: const Icon(Icons.link, color: AppColors.primary),
                title: const Text(
                  'YouTube URL',
                  style: TextStyle(color: Colors.white),
                ),
                tileColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showYoutubeInput(parentContext);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.folder, color: AppColors.primary),
                title: const Text(
                  'Local MP3 File',
                  style: TextStyle(color: Colors.white),
                ),
                tileColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLocalInput(parentContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showYoutubeInput(BuildContext parentContext) {
    final urlCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();
    String? selectedPlaylistId;
    bool isPublic = false;

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'YouTube Song',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(urlCtrl, 'YouTube URL'),
                const SizedBox(height: 12),
                _buildTextField(titleCtrl, 'Song Title'),
                const SizedBox(height: 12),
                _buildTextField(artistCtrl, 'Artist'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Public Song',
                      style: TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    Switch(
                      value: isPublic,
                      onChanged: (val) => setState(() => isPublic = val),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final playlistsAsync = ref.watch(myPlaylistsProvider);
                    return playlistsAsync.when(
                      data: (playlists) {
                        final personal = playlists.firstWhere(
                          (p) => p.name == 'My Uploading',
                          orElse: () => playlists.isNotEmpty
                              ? playlists.first
                              : Playlist(id: '', name: 'My Uploading'),
                        );
                        if (selectedPlaylistId == null &&
                            personal.id.isNotEmpty) {
                          selectedPlaylistId = personal.id;
                        }
                        return DropdownButtonFormField<String>(
                          initialValue: selectedPlaylistId,
                          dropdownColor: const Color(0xFF2A2A2A),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Add to Playlist',
                            labelStyle: const TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: playlists
                              .map(
                                (p) => DropdownMenuItem<String>(
                                  value: p.id,
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedPlaylistId = val;
                            });
                          },
                        );
                      },
                      loading: () => const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      error: (err, _) => const Text(
                        'Failed to load playlists',
                        style: TextStyle(color: AppColors.error),
                      ),
                    );
                  },
                ),
              ],
            ),
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
                final artistInput = artistCtrl.text.trim();
                if (title.isEmpty || url.isEmpty) return;

                final artist = artistInput.isEmpty
                    ? 'Unknown Artist'
                    : artistInput;

                final videoId = YoutubePlayer.convertUrlToId(url);
                if (videoId == null) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(content: Text('Invalid YouTube URL')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                await _createSongInBackend(
                  parentContext,
                  title: title,
                  artist: artist,
                  source: 'youtube',
                  sourcePath: videoId,
                  targetPlaylistId: selectedPlaylistId,
                  isPublic: isPublic,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Add Song'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocalInput(BuildContext parentContext) {
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();
    String? selectedPlaylistId;
    bool isPublic = false;

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Local MP3', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(titleCtrl, 'Song Title'),
                const SizedBox(height: 12),
                _buildTextField(artistCtrl, 'Artist'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Public Song',
                      style: TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    Switch(
                      value: isPublic,
                      onChanged: (val) => setState(() => isPublic = val),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final playlistsAsync = ref.watch(myPlaylistsProvider);
                    return playlistsAsync.when(
                      data: (playlists) {
                        final personal = playlists.firstWhere(
                          (p) => p.name == 'My Uploading',
                          orElse: () => playlists.isNotEmpty
                              ? playlists.first
                              : Playlist(id: '', name: 'My Uploading'),
                        );
                        if (selectedPlaylistId == null &&
                            personal.id.isNotEmpty) {
                          selectedPlaylistId = personal.id;
                        }
                        return DropdownButtonFormField<String>(
                          initialValue: selectedPlaylistId,
                          dropdownColor: const Color(0xFF2A2A2A),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Add to Playlist',
                            labelStyle: const TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: playlists
                              .map(
                                (p) => DropdownMenuItem<String>(
                                  value: p.id,
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedPlaylistId = val;
                            });
                          },
                        );
                      },
                      loading: () => const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      error: (err, _) => const Text(
                        'Failed to load playlists',
                        style: TextStyle(color: AppColors.error),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final artistInput = artistCtrl.text.trim();
                if (title.isEmpty) return;

                final artist = artistInput.isEmpty
                    ? 'Unknown Artist'
                    : artistInput;

                Navigator.pop(ctx);
                await _createSongInBackend(
                  parentContext,
                  title: title,
                  artist: artist,
                  source: 'mp3',
                  sourcePath: '',
                  targetPlaylistId: selectedPlaylistId,
                  isPublic: isPublic,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Add Song'),
            ),
          ],
        ),
      ),
    );
  }

  /// Create the song in the backend, then optionally add to a playlist.
  Future<void> _createSongInBackend(
    BuildContext parentContext, {
    required String title,
    required String artist,
    required String source,
    required String sourcePath,
    String? targetPlaylistId,
    bool isPublic = false,
  }) async {
    // Show loading with dedicated context capture
    BuildContext? dialogContext;
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    );

    try {
      final songService = parentRef.read(songServiceProvider);
      final playlistService = parentRef.read(playlistServiceProvider);
      final backendSong = await songService.createSong(
        title: title,
        artist: artist,
        source: source,
        sourcePath: sourcePath,
        isPublic: isPublic,
      );

      // Invalidate the songs lists provider
      parentRef.invalidate(songsProvider);

      final playlists = parentRef.read(myPlaylistsProvider).value ?? [];
      final personalPlaylist = playlists.firstWhere(
        (p) => p.name == 'My Uploading',
        orElse: () => throw Exception('My Uploading playlist not found'),
      );

      // Always add to the Personal playlist
      final updatedPersonal = await playlistService.addSongToPlaylist(
        personalPlaylist.id,
        backendSong.id,
      );
      parentRef
          .read(myPlaylistsProvider.notifier)
          .updatePlaylist(updatedPersonal);

      // If a different target playlist was selected, add to that one too!
      if (targetPlaylistId != null && targetPlaylistId != personalPlaylist.id) {
        final updatedTarget = await playlistService.addSongToPlaylist(
          targetPlaylistId,
          backendSong.id,
        );
        parentRef
            .read(myPlaylistsProvider.notifier)
            .updatePlaylist(updatedTarget);
      }

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      if (parentContext.mounted) {
        SuccessPopup.show(
          parentContext,
          title: 'Song Added!',
          subtitle: targetPlaylistId != null
              ? 'Added to library and playlist'
              : 'Added to your library',
          icon: Icons.library_add_check_rounded,
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (parentContext.mounted) {
        ScaffoldMessenger.of(
          parentContext,
        ).showSnackBar(SnackBar(content: Text('Failed to add song: $e')));
      }
    }
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
            onTap: () => _showCreatePlaylistDialog(context),
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
            iconColor: AppColors.primary,
            title: 'Add Song',
            subtitle: 'Add from YouTube or local MP3',
            onTap: () => _showAddSongDialog(context),
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
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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

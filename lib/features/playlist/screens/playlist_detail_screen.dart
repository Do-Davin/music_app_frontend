import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/providers/song_provider.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/core/routing/app_router.dart';
import 'package:music_app_frontend/shared/widgets/success_popup.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistAsync = ref.watch(playlistByIdProvider(playlistId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: playlistAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load playlist', style: AppTextStyles.body),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.read(myPlaylistsProvider.notifier).refreshPlaylists(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (playlist) => _PlaylistDetailContent(playlist: playlist),
      ),
    );
  }
}

class _PlaylistDetailContent extends ConsumerWidget {
  final Playlist playlist;
  const _PlaylistDetailContent({required this.playlist});

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  int get _totalDuration {
    return playlist.songs?.fold<int>(0, (sum, s) => sum + (s.duration ?? 0)) ??
        0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = playlist.songs ?? [];
    final songCount = songs.length;

    return CustomScrollView(
      slivers: [
        // ── Sliver App Bar with playlist art ──────────────────────────────
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Cover art or gradient placeholder
                if (playlist.coverImageUrl != null &&
                    playlist.coverImageUrl!.isNotEmpty)
                  Image.network(
                    playlist.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildGradientPlaceholder(),
                  )
                else
                  _buildGradientPlaceholder(),
                // Gradient overlay so text is readable
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.9),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Playlist info header ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  style: AppTextStyles.header.copyWith(fontSize: 26),
                ),
                if (playlist.description != null &&
                    playlist.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    playlist.description!,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.hint,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.music_note,
                      color: AppColors.hint,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$songCount song${songCount != 1 ? 's' : ''}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.hint,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.access_time,
                      color: AppColors.hint,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_totalDuration),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.hint,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (playlist.isPublic)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Public',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Play all button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: songs.isEmpty ? null : () {},
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Add Song to Playlist button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddSongToPlaylistDialog(context, ref, playlist.id),
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    label: const Text('Add Song to Playlist'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Songs',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // ── Song list ─────────────────────────────────────────────────────
        songs.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.queue_music, color: AppColors.hint, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'No songs yet',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.hint,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = songs[index];
                  return _SongTile(
                    song: song,
                    index: index,
                    playlistId: playlist.id,
                  );
                }, childCount: songs.length),
              ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  Widget _buildGradientPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3A2000), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.library_music, color: AppColors.primary, size: 80),
      ),
    );
  }

  void _showAddSongToPlaylistDialog(BuildContext context, WidgetRef ref, String playlistId) {
    showModalBottomSheet(
      context: context,
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
                'Add Song to Playlist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.link, color: AppColors.primary),
                title: const Text('YouTube URL', style: TextStyle(color: Colors.white)),
                tileColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showYoutubeInput(context, ref, playlistId);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.folder, color: AppColors.primary),
                title: const Text('Local MP3 File', style: TextStyle(color: Colors.white)),
                tileColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLocalInput(context, ref, playlistId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showYoutubeInput(BuildContext context, WidgetRef ref, String playlistId) {
    final urlCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();

    showDialog(
      context: context,
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
              final artistInput = artistCtrl.text.trim();
              if (title.isEmpty || url.isEmpty) return;

              final artist = artistInput.isEmpty ? 'Unknown Artist' : artistInput;

              final videoId = YoutubePlayer.convertUrlToId(url);
              if (videoId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid YouTube URL')),
                );
                return;
              }

              Navigator.pop(ctx);
              await _createSongAndAddToPlaylist(
                context, ref, playlistId,
                title: title,
                artist: artist,
                source: 'youtube',
                sourcePath: videoId,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add Song'),
          ),
        ],
      ),
    );
  }

  void _showLocalInput(BuildContext context, WidgetRef ref, String playlistId) {
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();

    showDialog(
      context: context,
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
              final artistInput = artistCtrl.text.trim();
              if (title.isEmpty) return;

              final artist = artistInput.isEmpty ? 'Unknown Artist' : artistInput;

              Navigator.pop(ctx);
              await _createSongAndAddToPlaylist(
                context, ref, playlistId,
                title: title,
                artist: artist,
                source: 'mp3',
                sourcePath: '',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add Song'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSongAndAddToPlaylist(
    BuildContext context,
    WidgetRef ref,
    String playlistId, {
    required String title,
    required String artist,
    required String source,
    required String sourcePath,
  }) async {
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
      final songService = ref.read(songServiceProvider);
      final playlistService = ref.read(playlistServiceProvider);
      final backendSong = await songService.createSong(
        title: title,
        artist: artist,
        source: source,
        sourcePath: sourcePath,
      );

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      // Find Personal playlist
      final playlists = ref.read(myPlaylistsProvider).value ?? [];
      final personalPlaylist = playlists.firstWhere(
        (p) => p.name == 'Personal',
        orElse: () => throw Exception('Personal playlist not found'),
      );

      // Add to this specific playlist — use returned data for immediate update
      final updatedPlaylist = await playlistService.addSongToPlaylist(playlistId, backendSong.id);
      ref.read(myPlaylistsProvider.notifier).updatePlaylist(updatedPlaylist);
      
      // If not adding to Personal, also add it to Personal!
      if (playlistId != personalPlaylist.id) {
        final updatedPersonal = await playlistService.addSongToPlaylist(personalPlaylist.id, backendSong.id);
        ref.read(myPlaylistsProvider.notifier).updatePlaylist(updatedPersonal);
      }
      
      if (context.mounted) {
        ref.invalidate(songsProvider);
      }

      if (context.mounted) {
        SuccessPopup.show(
          context,
          title: 'Song Added!',
          subtitle: 'Added to playlist successfully',
          icon: Icons.playlist_add_check_rounded,
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add song: $e')),
        );
      }
    }
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
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
}

class _SongTile extends ConsumerWidget {
  final Song song;
  final int index;
  final String playlistId;

  const _SongTile({
    required this.song,
    required this.index,
    required this.playlistId,
  });

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _showSongOptionsSheet(BuildContext context, WidgetRef ref) {
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
                  song.artist,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Remove from playlist', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeSongFromPlaylist(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add, color: AppColors.primary),
                title: const Text('Add to playlist', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddToPlaylistSheet(context, ref);
                },
              ),
              const ListTile(
                leading: Icon(Icons.queue_music, color: Colors.grey),
                title: Text('Add to queue', style: TextStyle(color: Colors.grey)),
              ),
              const ListTile(
                leading: Icon(Icons.play_arrow_outlined, color: Colors.grey),
                title: Text('Go to queue', style: TextStyle(color: Colors.grey)),
              ),
              const ListTile(
                leading: Icon(Icons.share_outlined, color: Colors.grey),
                title: Text('Share', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _removeSongFromPlaylist(BuildContext context, WidgetRef ref) async {
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
      final playlistService = ref.read(playlistServiceProvider);
      final updatedPlaylist = await playlistService.removeSongFromPlaylist(playlistId, song.id);
      
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      if (context.mounted) {
        ref.read(myPlaylistsProvider.notifier).updatePlaylist(updatedPlaylist);
        SuccessPopup.show(
          context,
          title: 'Song Removed',
          subtitle: 'Removed from this playlist',
          icon: Icons.remove_circle_outline_rounded,
          iconColor: AppColors.error,
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove song: $e')),
        );
      }
    }
  }

  void _showAddToPlaylistSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
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
                      _showNewPlaylistAndAddSong(context, ref);
                    },
                  ),
                  const SizedBox(height: 12),
                  playlistsAsync.when(
                    data: (playlists) {
                      // Filter out current playlist to avoid adding to same playlist
                      final otherPlaylists = playlists.where((p) => p.id != playlistId).toList();
                      if (otherPlaylists.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('No other playlists yet.', style: TextStyle(color: Colors.grey)),
                        );
                      }
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: otherPlaylists.length,
                          itemBuilder: (context, index) {
                            final p = otherPlaylists[index];
                            return ListTile(
                              leading: const Icon(Icons.playlist_play, color: AppColors.primary),
                              title: Text(p.name, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                '${p.songs?.length ?? p.songIds?.length ?? 0} songs',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                              onTap: () async {
                                Navigator.pop(ctx);
                                _addSongToTargetPlaylist(context, ref, p);
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

  Future<void> _addSongToTargetPlaylist(BuildContext context, WidgetRef ref, Playlist targetPlaylist) async {
    // Show a loading indicator
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
      final updatedPlaylist = await ref.read(playlistServiceProvider).addSongToPlaylist(targetPlaylist.id, song.id);

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      // Immediately update the target playlist in state — no refetch needed
      ref.read(myPlaylistsProvider.notifier).updatePlaylist(updatedPlaylist);

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

  void _showNewPlaylistAndAddSong(BuildContext context, WidgetRef ref) {
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
          decoration: InputDecoration(
            hintText: 'Playlist Name',
            hintStyle: const TextStyle(color: Colors.grey),
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
                final playlistService = ref.read(playlistServiceProvider);
                final newPlaylist = await playlistService.createPlaylist(name);
                final updatedPlaylist = await playlistService.addSongToPlaylist(newPlaylist.id, song.id);
                ref.read(myPlaylistsProvider.notifier).updatePlaylist(updatedPlaylist);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasImage =
        song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surface,
          image: hasImage
              ? DecorationImage(
                  image: NetworkImage(song.coverImageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: !hasImage
            ? const Icon(Icons.music_note, color: AppColors.hint, size: 24)
            : null,
      ),
      title: Text(
        song.title,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (song.isYoutube)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.smart_display,
                color: Color(0xFFFF0000),
                size: 13,
              ),
            ),
          Expanded(
            child: Text(
              song.artist,
              style: AppTextStyles.body.copyWith(
                color: AppColors.hint,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(song.duration),
            style: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 12),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.hint, size: 20),
            onPressed: () => _showSongOptionsSheet(context, ref),
          ),
        ],
      ),
      onTap: () {
        context.push(
          Routes.songById(song.id),
          extra: SongPlayerRouteData(song: song, category: 'PLAYLIST'),
        );
      },
    );
  }
}

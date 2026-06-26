import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/providers/song_provider.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/core/routing/app_router.dart';
import 'package:music_app_frontend/shared/widgets/success_popup.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:music_app_frontend/features/karaoke/data/models/karaoke_song.dart';
import 'package:music_app_frontend/features/karaoke/presentation/controllers/karaoke_controller.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/lyric_editor_screen.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/player_screen.dart';
import 'package:music_app_frontend/features/song/services/song_service.dart';
import 'package:music_app_frontend/features/playlist/services/liked_songs_service.dart';
import 'package:provider/provider.dart' as provider;
import 'package:music_app_frontend/core/utils/youtube_parser.dart';
import 'package:music_app_frontend/core/utils/song_matcher.dart';
import 'package:music_app_frontend/features/song/providers/global_audio_player_provider.dart';
import 'package:music_app_frontend/features/song/widgets/playing_equalizer_wave.dart';

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

    final meAsync = ref.watch(meProvider);
    final isPlaylistOwner = meAsync.maybeWhen(
      data: (user) => user.id == playlist.userId,
      orElse: () => false,
    );

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
              onPressed: () {
                final me = meAsync.valueOrNull;
                final isSaved = playlist.savedUserIds?.contains(me?.id ?? '') ?? false;
                _showPlaylistOptionsSheet(context, ref, isPlaylistOwner, isSaved);
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: playlist.isPublic
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: playlist.isPublic
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : Colors.grey.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            playlist.isPublic ? Icons.public : Icons.lock,
                            size: 12,
                            color: playlist.isPublic ? AppColors.primary : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            playlist.isPublic ? 'Public' : 'Private',
                            style: AppTextStyles.body.copyWith(
                              color: playlist.isPublic ? AppColors.primary : Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                if (isPlaylistOwner) const SizedBox(height: 10),
                // Add Song to Playlist button
                if (isPlaylistOwner)
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
                  return SongTile(
                    song: song,
                    index: index,
                    playlist: playlist,
                    isPlaylistOwner: isPlaylistOwner,
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

  void _showPlaylistOptionsSheet(BuildContext context, WidgetRef ref, bool isPlaylistOwner, bool isSaved) {
    final isSystemPlaylist = playlist.name == 'My Uploading' || playlist.name == 'Liked Songs';

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
                  playlist.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  playlist.isPublic ? 'Public playlist' : 'Private playlist',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              // Toggle visibility (only for owner, not for system playlists like My Uploading)
              if (isPlaylistOwner && !isSystemPlaylist) ...[
                ListTile(
                  leading: Icon(
                    playlist.isPublic ? Icons.lock : Icons.public,
                    color: Colors.blue,
                  ),
                  title: Text(
                    playlist.isPublic ? 'Make Private' : 'Make Public',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    playlist.isPublic
                        ? 'Only you can see this playlist'
                        : 'Anyone can discover this playlist',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _togglePlaylistVisibility(context, ref);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Delete Playlist',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Permanently delete this playlist',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deletePlaylist(context, ref);
                  },
                ),
              ],
              // Add to / Remove from Library (only for non-owners)
              if (!isPlaylistOwner)
                ListTile(
                  leading: Icon(
                    isSaved ? Icons.library_add_check : Icons.library_add,
                    color: isSaved ? AppColors.primary : Colors.grey,
                  ),
                  title: Text(
                    isSaved ? 'Remove Playlist' : 'Add to Library',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    isSaved
                        ? 'Remove this playlist from your library'
                        : 'Save this playlist to your library',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _toggleLibraryStatus(context, ref, isSaved);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleLibraryStatus(BuildContext context, WidgetRef ref, bool isSaved) async {
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
      if (isSaved) {
        await playlistService.removePlaylistFromLibrary(playlist.id);
      } else {
        await playlistService.savePlaylistToLibrary(playlist.id);
      }

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      // Refresh the playlists providers
      await myPlaylistsNotifier.refreshPlaylists();
      ref.invalidate(playlistByIdProvider(playlist.id));

      if (context.mounted) {
        SuccessPopup.show(
          context,
          title: isSaved ? 'Removed from Library' : 'Added to Library',
          subtitle: isSaved ? 'Playlist removed successfully' : 'Playlist saved successfully',
          icon: isSaved ? Icons.bookmark_remove : Icons.bookmark_added,
          iconColor: isSaved ? AppColors.error : AppColors.primary,
        );
        if (isSaved) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _deletePlaylist(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Playlist', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to permanently delete "${playlist.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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
      final success = await playlistService.removePlaylist(playlist.id);

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      if (success) {
        await myPlaylistsNotifier.refreshPlaylists();
        if (context.mounted) {
          SuccessPopup.show(
            context,
            title: 'Playlist Deleted',
            subtitle: 'The playlist has been permanently removed',
            icon: Icons.delete_forever,
            iconColor: AppColors.error,
          );
          // Go back from detail screen
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to delete playlist');
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _togglePlaylistVisibility(BuildContext context, WidgetRef ref) async {
    // Capture providers before any async gap to avoid "ref used after dispose"
    final playlistService = ref.read(playlistServiceProvider);
    final myPlaylistsNotifier = ref.read(myPlaylistsProvider.notifier);
    final newIsPublic = !playlist.isPublic;

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
      final updated = await playlistService.updatePlaylistVisibility(
        playlistId: playlist.id,
        isPublic: newIsPublic,
      );

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      myPlaylistsNotifier.updatePlaylist(updated);

      if (context.mounted) {
        SuccessPopup.show(
          context,
          title: newIsPublic ? 'Playlist is now Public' : 'Playlist is now Private',
          subtitle: 'Visibility updated successfully',
          icon: newIsPublic ? Icons.public : Icons.lock,
          iconColor: Colors.blue,
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update visibility: $e')),
        );
      }
    }
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

              final videoId = extractYoutubeId(url);
              if (videoId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid YouTube URL or Video ID')),
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
    // Capture providers before any async gap to avoid "ref used after dispose"
    final songService = ref.read(songServiceProvider);
    final playlistService = ref.read(playlistServiceProvider);
    final myPlaylistsNotifier = ref.read(myPlaylistsProvider.notifier);
    final playlists = ref.read(myPlaylistsProvider).value ?? [];

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
      final backendSong = await songService.createSong(
        title: title,
        artist: artist,
        source: source,
        sourcePath: sourcePath,
      );

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      final personalPlaylist = playlists.firstWhere(
        (p) => p.name == 'My Uploading',
        orElse: () => throw Exception('My Uploading playlist not found'),
      );

      final updatedPlaylist = await playlistService.addSongToPlaylist(playlistId, backendSong.id);
      myPlaylistsNotifier.updatePlaylist(updatedPlaylist);
      
      if (playlistId != personalPlaylist.id) {
        final updatedPersonal = await playlistService.addSongToPlaylist(personalPlaylist.id, backendSong.id);
        myPlaylistsNotifier.updatePlaylist(updatedPersonal);
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

class SongTile extends ConsumerWidget {
  final Song song;
  final int index;
  final Playlist? playlist;
  final bool isPlaylistOwner;
  final VoidCallback? onTap;
  final bool showTypeBadge;

  const SongTile({
    required this.song,
    required this.index,
    this.playlist,
    this.isPlaylistOwner = false,
    this.onTap,
    this.showTypeBadge = false,
  });

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _showSongOptionsSheet(BuildContext context, WidgetRef ref) {
    final me = ref.read(meProvider).valueOrNull;
    final isSongOwner = me != null && song.userId == me.id;

    final isPersonalPlaylist = playlist?.name == 'My Uploading';
    final isLikedSongsPlaylist = playlist?.name == 'Liked Songs';
    final isNormalPlaylist = playlist != null && playlist!.name != 'My Uploading' && playlist!.name != 'Liked Songs';

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

              // ── NORMAL PLAYLIST ──────────────────────────────────────
              if (isNormalPlaylist) ...[
                // Owner of playlist can remove songs
                if (isPlaylistOwner)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: AppColors.error),
                    title: const Text('Remove from playlist', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _removeSongFromPlaylist(context, ref);
                    },
                  ),
                // Everyone can add to their own playlists
                // But non-owners cannot add to "My Uploading"
                ListTile(
                  leading: const Icon(Icons.playlist_add, color: AppColors.primary),
                  title: const Text('Add to playlist', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddToPlaylistSheet(context, ref, excludePersonal: !isSongOwner);
                  },
                ),
                // Only song owner can toggle visibility
                if (isSongOwner)
                  ListTile(
                    leading: Icon(song.isPublic ? Icons.lock : Icons.public, color: Colors.blue),
                    title: Text(song.isPublic ? 'Make Private' : 'Make Public', style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleSongPrivacy(context, ref);
                    },
                  ),
                // Add / Convert to Karaoke
                KaraokeOptionTile(song: song, isSongOwner: isSongOwner, parentContext: context),
                // Add to queue (feature placeholder)
                const ListTile(
                  leading: Icon(Icons.queue_music, color: Colors.grey),
                  title: Text('Add to queue', style: TextStyle(color: Colors.grey)),
                ),
              ],

              // ── MY UPLOADING PLAYLIST (personal / default) ───────────
              if (isPersonalPlaylist) ...[
                // Only song owner can delete the song permanently
                if (isSongOwner)
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: AppColors.error),
                    title: const Text('Delete Song', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _deleteSongFromBackend(context, ref);
                    },
                  ),
                // Add to another playlist
                ListTile(
                  leading: const Icon(Icons.playlist_add, color: AppColors.primary),
                  title: const Text('Add to playlist', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddToPlaylistSheet(context, ref);
                  },
                ),
                // Only song owner can toggle visibility
                if (isSongOwner)
                  ListTile(
                    leading: Icon(song.isPublic ? Icons.lock : Icons.public, color: Colors.blue),
                    title: Text(song.isPublic ? 'Make Private' : 'Make Public', style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleSongPrivacy(context, ref);
                    },
                  ),
                // Add / Convert to Karaoke
                KaraokeOptionTile(song: song, isSongOwner: isSongOwner, parentContext: context),
                // Add to queue (feature placeholder)
                const ListTile(
                  leading: Icon(Icons.queue_music, color: Colors.grey),
                  title: Text('Add to queue', style: TextStyle(color: Colors.grey)),
                ),
              ],

              // ── LIKED SONGS PLAYLIST ─────────────────────────────────
              if (isLikedSongsPlaylist) ...[
                // Unlike
                ListTile(
                  leading: const Icon(Icons.favorite_border, color: AppColors.error),
                  title: const Text('Unlike', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _unlikeSong(context, ref);
                  },
                ),
                // Move to playlist
                ListTile(
                  leading: const Icon(Icons.drive_file_move_outlined, color: Colors.orangeAccent),
                  title: const Text('Move to playlist', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMoveToPlaylistSheet(context, ref);
                  },
                ),
                // Add to playlist
                ListTile(
                  leading: const Icon(Icons.playlist_add, color: AppColors.primary),
                  title: const Text('Add to playlist', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddToPlaylistSheet(context, ref, excludePersonal: !isSongOwner);
                  },
                ),
                // Add / Convert to Karaoke
                KaraokeOptionTile(song: song, isSongOwner: isSongOwner, parentContext: context),
                // Add to queue (feature placeholder)
                const ListTile(
                  leading: Icon(Icons.queue_music, color: Colors.grey),
                  title: Text('Add to queue', style: TextStyle(color: Colors.grey)),
                ),
              ],

              // ── NO PLAYLIST CONTEXT (e.g. search results) ────────────
              if (playlist == null) ...[
                // Add to playlist (non-owners can't add to "My Uploading")
                ListTile(
                  leading: const Icon(Icons.playlist_add, color: AppColors.primary),
                  title: const Text('Add to playlist', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddToPlaylistSheet(context, ref, excludePersonal: !isSongOwner);
                  },
                ),
                // Only song owner can toggle visibility
                if (isSongOwner)
                  ListTile(
                    leading: Icon(song.isPublic ? Icons.lock : Icons.public, color: Colors.blue),
                    title: Text(song.isPublic ? 'Make Private' : 'Make Public', style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleSongPrivacy(context, ref);
                    },
                  ),
                // Add / Convert to Karaoke
                KaraokeOptionTile(song: song, isSongOwner: isSongOwner, parentContext: context),
                // Add to queue (feature placeholder)
                const ListTile(
                  leading: Icon(Icons.queue_music, color: Colors.grey),
                  title: Text('Add to queue', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _unlikeSong(BuildContext context, WidgetRef ref) async {
    // Capture providers before any async gap to avoid "ref used after dispose"
    final myPlaylistsNotifier = ref.read(myPlaylistsProvider.notifier);

    try {
      await LikedSongsService().toggleLikeSong(song.id);
      ref.invalidate(likedSongsPlaylistProvider);
      ref.invalidate(likedSongsProvider);
      ref.invalidate(isSongInLikedSongsProvider(song.id));
      myPlaylistsNotifier.refreshPlaylists();
      
      if (context.mounted) {
        SuccessPopup.show(
          context,
          title: 'Unliked',
          subtitle: 'Removed from liked songs',
          icon: Icons.favorite_border,
          iconColor: AppColors.error,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unlike: $e')),
        );
      }
    }
  }

  Future<void> _deleteSongFromBackend(BuildContext context, WidgetRef ref) async {
    // Capture providers before any async gap to avoid "ref used after dispose"
    final myPlaylistsNotifier = ref.read(myPlaylistsProvider.notifier);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Song', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to permanently delete "${song.title}" from the music platform?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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
      final songService = SongService();
      await songService.deleteSong(song.id);

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      // Refresh playlists and songs list
      myPlaylistsNotifier.refreshPlaylists();

      if (context.mounted) {
        SuccessPopup.show(
          context,
          title: 'Song Deleted',
          subtitle: 'Deleted from library permanently',
          icon: Icons.delete_forever,
          iconColor: AppColors.error,
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete song: $e')),
        );
      }
    }
  }



  Future<void> _removeSongFromPlaylist(BuildContext context, WidgetRef ref) async {
    if (playlist == null) return;
    final playlistService = ref.read(playlistServiceProvider);
    final myPlaylistsNotifier = ref.read(myPlaylistsProvider.notifier);
    
    // Optimistic UI update: instantly remove from current playlist
    myPlaylistsNotifier.removeSongLocally(playlist!.id, song.id);

    try {
      final updatedPlaylist = await playlistService.removeSongFromPlaylist(playlist!.id, song.id);
      
      myPlaylistsNotifier.updatePlaylist(updatedPlaylist);

      if (context.mounted) {
        SuccessPopup.show(
          context,
          title: 'Song Removed',
          subtitle: 'Removed from this playlist',
          icon: Icons.remove_circle_outline_rounded,
          iconColor: AppColors.error,
        );
      }
    } catch (e) {
      // Revert on error
      await myPlaylistsNotifier.refreshPlaylists();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove song: $e')),
        );
      }
    }
  }

  Future<void> _toggleSongPrivacy(BuildContext context, WidgetRef ref) async {
    final newIsPublic = !song.isPublic;

    if (newIsPublic && playlist?.name == 'My Uploading') {
      _showAddToPublicPlaylistSheet(context, ref);
      return;
    }

    // Capture providers before any async gap to avoid "ref used after dispose"
    final songService = ref.read(songServiceProvider);
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
      await songService.updateSongVisibility(
        songId: song.id,
        isPublic: newIsPublic,
      );

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      // Refresh the current playlist to see updated song state
      await myPlaylistsNotifier.refreshPlaylists();

      if (context.mounted) {
        SuccessPopup.show(
          context,
          title: newIsPublic ? 'Song is now Public' : 'Song is now Private',
          subtitle: 'Visibility updated successfully',
          icon: newIsPublic ? Icons.public : Icons.lock,
          iconColor: Colors.blue,
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update visibility: $e')),
        );
      }
    }
  }

  void _showAddToPublicPlaylistSheet(BuildContext context, WidgetRef ref) {
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
                    'Publish Song',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "To make '${song.title}' public, please add it to an existing public playlist or create a new one.",
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.add, color: AppColors.primary),
                    title: const Text('Create New Public Playlist', style: TextStyle(color: Colors.white)),
                    tileColor: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showNewPublicPlaylistAndPublish(context, ref);
                    },
                  ),
                  const SizedBox(height: 12),
                  playlistsAsync.when(
                    data: (playlists) {
                      final publicPlaylists = playlists
                          .where((p) => p.isPublic && p.name != 'My Uploading' && p.name != 'Liked Songs')
                          .toList();
                      if (publicPlaylists.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('No existing public playlists found.', style: TextStyle(color: Colors.grey)),
                        );
                      }
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: publicPlaylists.length,
                          itemBuilder: (context, index) {
                            final p = publicPlaylists[index];
                            return ListTile(
                              leading: const Icon(Icons.playlist_play, color: AppColors.primary),
                              title: Text(p.name, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                '${p.songs?.length ?? p.songIds?.length ?? 0} songs',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                              onTap: () async {
                                Navigator.pop(ctx);
                                _publishSongToTargetPlaylist(context, ref, p);
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

  Future<void> _showNewPublicPlaylistAndPublish(BuildContext context, WidgetRef ref) async {
    final playlistService = ref.read(playlistServiceProvider);
    final myPlaylistsNotifier = ref.read(myPlaylistsProvider.notifier);
    final songService = ref.read(songServiceProvider);

    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('New Public Playlist', style: TextStyle(color: Colors.white)),
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
                // 1. Create public playlist
                final newPlaylist = await myPlaylistsNotifier.createPlaylist(name, isPublic: true);
                if (newPlaylist == null) {
                  throw Exception('Failed to create public playlist');
                }

                // 2. Make song public
                await songService.updateSongVisibility(songId: song.id, isPublic: true);

                // 3. Add song to playlist
                final updatedPlaylist = await playlistService.addSongToPlaylist(newPlaylist.id, song.id);
                myPlaylistsNotifier.updatePlaylist(updatedPlaylist);

                if (dialogContext != null && dialogContext!.mounted) {
                  Navigator.pop(dialogContext!);
                }

                await myPlaylistsNotifier.refreshPlaylists();

                if (context.mounted) {
                  SuccessPopup.show(
                    context,
                    title: 'Song is now Public!',
                    subtitle: 'Published to "$name" successfully',
                    icon: Icons.public,
                    iconColor: Colors.blue,
                  );
                }
              } catch (e) {
                if (dialogContext != null && dialogContext!.mounted) {
                  Navigator.pop(dialogContext!);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            child: const Text('Create & Publish', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _publishSongToTargetPlaylist(BuildContext context, WidgetRef ref, Playlist targetPlaylist) async {
    final playlistService = ref.read(playlistServiceProvider);
    final myPlaylistsNotifier = ref.read(myPlaylistsProvider.notifier);
    final songService = ref.read(songServiceProvider);

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
      // 1. Make song public
      await songService.updateSongVisibility(songId: song.id, isPublic: true);

      // 2. Add song to target playlist
      final updatedPlaylist = await playlistService.addSongToPlaylist(targetPlaylist.id, song.id);
      myPlaylistsNotifier.updatePlaylist(updatedPlaylist);

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      await myPlaylistsNotifier.refreshPlaylists();

      if (context.mounted) {
        SuccessPopup.show(
          context,
          title: 'Song is now Public!',
          subtitle: 'Published to "${targetPlaylist.name}" successfully',
          icon: Icons.public,
          iconColor: Colors.blue,
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish song: $e')),
        );
      }
    }
  }

  void _showAddToPlaylistSheet(BuildContext context, WidgetRef ref, {bool excludePersonal = false}) {
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
                      var otherPlaylists = playlists.where((p) => p.id != playlist?.id).toList();
                      if (excludePersonal) {
                        otherPlaylists = otherPlaylists.where((p) => p.name != 'My Uploading').toList();
                      }
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
    // Capture providers before any async gap to avoid "ref used after dispose"
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

  void _showMoveToPlaylistSheet(BuildContext context, WidgetRef ref) {
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
                    'Move to Playlist',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  playlistsAsync.when(
                    data: (playlists) {
                      final otherPlaylists = playlists.where((p) => p.id != playlist?.id).toList();
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
                              leading: const Icon(Icons.drive_file_move_outlined, color: Colors.orangeAccent),
                              title: Text(p.name, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                '${p.songs?.length ?? p.songIds?.length ?? 0} songs',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                              onTap: () async {
                                Navigator.pop(ctx);
                                _moveSongToTargetPlaylist(context, ref, p);
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

  Future<void> _moveSongToTargetPlaylist(BuildContext context, WidgetRef ref, Playlist targetPlaylist) async {
    if (playlist == null) return;
    final playlistService = ref.read(playlistServiceProvider);
    final myPlaylistsNotifier = ref.read(myPlaylistsProvider.notifier);

    // Optimistic UI update: instantly remove from current playlist
    myPlaylistsNotifier.removeSongLocally(playlist!.id, song.id);

    try {
      final updatedPlaylist = await playlistService.moveSongBetweenPlaylists(
            fromPlaylistId: playlist!.id,
            toPlaylistId: targetPlaylist.id,
            songId: song.id,
          );

      myPlaylistsNotifier.updatePlaylist(updatedPlaylist);

      if (context.mounted) {
        SuccessPopup.show(
          context,
          title: 'Moved to "${targetPlaylist.name}"',
          subtitle: '"${song.title}" was moved successfully',
          icon: Icons.drive_file_move_outlined,
          iconColor: Colors.orangeAccent,
        );
      }
    } catch (e) {
      // Revert on error
      await myPlaylistsNotifier.refreshPlaylists();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to move: $e')),
        );
      }
    }
  }

  void _showNewPlaylistAndAddSong(BuildContext context, WidgetRef ref) {
    // Capture providers before any async gap to avoid "ref used after dispose"
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
                final newPlaylist = await playlistService.createPlaylist(name);
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

  Widget _buildSongOwnerBadge(WidgetRef ref, Song song) {
    final me = ref.watch(meProvider).valueOrNull;
    final isOwner = me != null && song.userId == me.id;
    final text = isOwner 
        ? (song.isPublic ? 'Yours • Public' : 'Yours • Private')
        : (song.isPublic ? 'Public' : 'Private');
    
    // Choose color: public is blue/primary, private is grey/red
    final Color badgeColor = isOwner 
        ? (song.isPublic ? AppColors.primary : Colors.orangeAccent)
        : (song.isPublic ? Colors.blue : Colors.grey);

    return Container(
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
        text,
        style: TextStyle(
          color: badgeColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).valueOrNull;
    final isSongOwner = me != null && song.userId == me.id;

    final playerState = ref.watch(globalAudioPlayerProvider);
    final isCurrentPlayingSong = playerState.currentSong?.id == song.id;
    final isPlaying = isCurrentPlayingSong && playerState.isPlaying;

    // Check if the current user is the owner of the playlist
    final bool isOwnerOfPlaylist = isPlaylistOwner;

    // Determine if the song is unaccessible/disabled for the current user:
    final bool isUnaccessible = () {
      // If the user owns the song or owns the playlist, it's always accessible.
      if (isSongOwner || isOwnerOfPlaylist) {
        return false;
      }
      // Otherwise:
      if (playlist != null) {
        // If the playlist is private, all songs in it are unaccessible.
        if (!playlist!.isPublic) {
          return true;
        }
        // If the playlist is public, private songs in it are unaccessible.
        if (playlist!.isPublic && !song.isPublic) {
          return true;
        }
      } else {
        // If there is no playlist context, private songs are unaccessible
        if (!song.isPublic) {
          return true;
        }
      }
      return false;
    }();

    final bool hasImage = song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty;
    final Widget tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Stack(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.surface,
              image: hasImage
                  ? DecorationImage(
                      image: NetworkImage(song.coverImageUrl!),
                      fit: BoxFit.cover,
                      onError: (_, _) {},
                    )
                  : null,
            ),
            child: !hasImage ? const Icon(Icons.music_note, color: AppColors.hint, size: 24) : null,
          ),
          if (isCurrentPlayingSong)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: PlayingEqualizerWave(
                    isAnimated: isPlaying,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              song.title,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: isCurrentPlayingSong ? AppColors.primary : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showTypeBadge) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4), width: 0.5),
              ),
              child: const Text(
                'SONG',
                style: TextStyle(color: Colors.blueAccent, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ],
          const SizedBox(width: 8),
          _buildSongOwnerBadge(ref, song),
        ],
      ),
      subtitle: Row(
        children: [
          if (song.isYoutube)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.smart_display, color: Color(0xFFFF0000), size: 13),
            ),
          Expanded(
            child: Text(
              song.artist,
              style: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_formatDuration(song.duration), style: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 12)),
          const SizedBox(width: 4),
          if (!isUnaccessible)
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.hint, size: 20),
              onPressed: () => _showSongOptionsSheet(context, ref),
            ),
        ],
      ),
      onTap: isUnaccessible ? null : onTap ?? () {
        ref.read(globalAudioPlayerProvider.notifier).playSong(song);
      },
    );

    if (isUnaccessible) {
      return Opacity(
        opacity: 0.4,
        child: IgnorePointer(
          child: tile,
        ),
      );
    }
    return tile;
  }
}

class KaraokeOptionTile extends StatefulWidget {
  final Song song;
  final bool isSongOwner;
  final BuildContext parentContext;

  const KaraokeOptionTile({
    super.key,
    required this.song,
    required this.isSongOwner,
    required this.parentContext,
  });

  @override
  State<KaraokeOptionTile> createState() => _KaraokeOptionTileState();
}

class _KaraokeOptionTileState extends State<KaraokeOptionTile> {
  bool _isLoading = true;
  KaraokeSong? _matchingPublicKaraoke;
  bool _alreadyInOwnSpace = false;
  KaraokeSong? _matchingOwnKaraoke;

  @override
  void initState() {
    super.initState();
    _checkKaraokeStatus();
  }

  bool _isSongMatch(KaraokeSong karaoke, Song song) {
    return isSongMatch(karaoke, song);
  }

  Future<void> _checkKaraokeStatus() async {
    try {
      final controller = KaraokeController();
      await controller.loadSongs();
      final ownSongs = controller.songs;
      final publicSongs = controller.publicSongs;

      KaraokeSong? publicMatch;
      for (final s in publicSongs) {
        if (_isSongMatch(s, widget.song) && s.lyrics.isNotEmpty) {
          publicMatch = s;
          break;
        }
      }

      KaraokeSong? ownMatch;
      for (final s in ownSongs) {
        if (_isSongMatch(s, widget.song)) {
          ownMatch = s;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _matchingPublicKaraoke = publicMatch;
          _matchingOwnKaraoke = ownMatch;
          _alreadyInOwnSpace = ownMatch != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking karaoke status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
        ),
        title: Text('Checking karaoke status...', style: TextStyle(color: Colors.grey)),
      );
    }

    if (widget.isSongOwner) {
      final isConverted = _matchingOwnKaraoke != null && _matchingOwnKaraoke!.lyrics.isNotEmpty;
      return ListTile(
        leading: Icon(
          isConverted ? Icons.edit : Icons.mic,
          color: Colors.purpleAccent,
        ),
        title: Text(
          isConverted ? 'Edit Karaoke Lyrics' : 'Add to Karaoke / Sing',
          style: const TextStyle(color: Colors.white),
        ),
        onTap: () {
          Navigator.pop(context);
          _startLyricSetup(widget.parentContext);
        },
      );
    }

    if (_matchingPublicKaraoke == null) {
      return const SizedBox.shrink();
    }

    if (_alreadyInOwnSpace) {
      return ListTile(
        leading: const Icon(Icons.mic, color: Colors.purpleAccent),
        title: const Text('Sing Karaoke (Go to Space)', style: TextStyle(color: Colors.white)),
        onTap: () {
          Navigator.pop(context);
          _playKaraokeDirectly(widget.parentContext, _matchingOwnKaraoke!);
        },
      );
    } else {
      return ListTile(
        leading: const Icon(Icons.playlist_add, color: Colors.purpleAccent),
        title: const Text('Add to KaraokeSpace', style: TextStyle(color: Colors.white)),
        onTap: () {
          Navigator.pop(context);
          _addToKaraokeSpace(widget.parentContext);
        },
      );
    }
  }

  void _playKaraokeDirectly(BuildContext context, KaraokeSong karaokeSong) {
    final controller = KaraokeController();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => provider.ChangeNotifierProvider<KaraokeController>.value(
          value: controller,
          child: PlayerScreen(
            song: karaokeSong,
            controller: controller,
          ),
        ),
      ),
    );
  }

  void _startLyricSetup(BuildContext context) async {
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
      final controller = KaraokeController();
      final karaokeSong = await controller.convertSongToKaraoke(widget.song);

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => provider.ChangeNotifierProvider<KaraokeController>.value(
              value: controller,
              child: LyricEditorScreen(
                song: karaokeSong,
                controller: controller,
                sourceSongId: widget.song.id,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start karaoke conversion: $e')),
        );
      }
    }
  }

  void _addToKaraokeSpace(BuildContext context) async {
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
      final controller = KaraokeController();
      final result = await controller.addPublicSongToSpace(_matchingPublicKaraoke!);

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      if (context.mounted) {
        if (result != null) {
          SuccessPopup.show(
            context,
            title: 'Added to Karaoke!',
            subtitle: 'Song is now in your Karaoke Space',
            icon: Icons.mic_external_on_rounded,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add song to Karaoke Space')),
          );
        }
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add song to Karaoke Space: $e')),
        );
      }
    }
  }
}

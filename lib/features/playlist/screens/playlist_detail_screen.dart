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
import 'package:music_app_frontend/features/karaoke/presentation/controllers/karaoke_controller.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/lyric_editor_screen.dart';
import 'package:music_app_frontend/features/song/services/song_service.dart';
import 'package:music_app_frontend/features/playlist/services/liked_songs_service.dart';
import 'package:provider/provider.dart' as provider;

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
              onPressed: () {},
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

      final playlists = ref.read(myPlaylistsProvider).value ?? [];
      final personalPlaylist = playlists.firstWhere(
        (p) => p.name == 'My Uploading',
        orElse: () => throw Exception('My Uploading playlist not found'),
      );

      final updatedPlaylist = await playlistService.addSongToPlaylist(playlistId, backendSong.id);
      ref.read(myPlaylistsProvider.notifier).updatePlaylist(updatedPlaylist);
      
      if (playlistId != personalPlaylist.id) {
        final updatedPersonal = await playlistService.addSongToPlaylist(personalPlaylist.id, backendSong.id);
        ref.read(myPlaylistsProvider.notifier).updatePlaylist(updatedPersonal);
      }
      
      if (context.mounted) {
        ref.invalidate(songsProvider);
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

  const SongTile({
    required this.song,
    required this.index,
    this.playlist,
    this.isPlaylistOwner = false,
    this.onTap,
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
    final isNormalPlaylist = !isPersonalPlaylist && !isLikedSongsPlaylist;

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

              // ── NORMAL PLAYLIST ────────────────────────────────────────
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
                // Only song owner can convert to karaoke
                if (isSongOwner)
                  ListTile(
                    leading: const Icon(Icons.mic, color: Colors.purpleAccent),
                    title: const Text('Convert to Karaoke', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _startLyricSetup(context, ref);
                    },
                  ),
                // Add to queue (feature placeholder)
                const ListTile(
                  leading: Icon(Icons.queue_music, color: Colors.grey),
                  title: Text('Add to queue', style: TextStyle(color: Colors.grey)),
                ),
              ],

              // ── MY UPLOADING PLAYLIST (personal / default) ─────────────
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
                // Only song owner can convert to karaoke
                if (isSongOwner)
                  ListTile(
                    leading: const Icon(Icons.mic, color: Colors.purpleAccent),
                    title: const Text('Convert to Karaoke', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _startLyricSetup(context, ref);
                    },
                  ),
                // Add to queue (feature placeholder)
                const ListTile(
                  leading: Icon(Icons.queue_music, color: Colors.grey),
                  title: Text('Add to queue', style: TextStyle(color: Colors.grey)),
                ),
              ],

              // ── LIKED SONGS PLAYLIST ───────────────────────────────────
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
              ],

              // ── NO PLAYLIST CONTEXT (e.g. search results) ──────────────
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
                // Only song owner can convert to karaoke
                if (isSongOwner)
                  ListTile(
                    leading: const Icon(Icons.mic, color: Colors.purpleAccent),
                    title: const Text('Convert to Karaoke', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _startLyricSetup(context, ref);
                    },
                  ),
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
    try {
      await LikedSongsService().toggleLikeSong(song.id);
      ref.read(myPlaylistsProvider.notifier).refreshPlaylists();
      ref.invalidate(songsProvider);
      
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
      ref.read(myPlaylistsProvider.notifier).refreshPlaylists();
      ref.invalidate(songsProvider);

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

  Future<void> _startLyricSetup(BuildContext context, WidgetRef ref) async {
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
      final karaokeSong = await controller.convertSongToKaraoke(song);

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                provider.ChangeNotifierProvider<KaraokeController>.value(
                  value: controller,
                  child: LyricEditorScreen(
                    song: karaokeSong,
                    controller: controller,
                    sourceSongId: song.id,
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
      final newIsPublic = !song.isPublic;
      await songService.updateSongVisibility(
        songId: song.id,
        isPublic: newIsPublic,
      );

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }

      // Refresh the current playlist to see updated song state
      await ref.read(myPlaylistsProvider.notifier).refreshPlaylists();

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
    final bool hasImage = song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surface,
          image: hasImage ? DecorationImage(image: NetworkImage(song.coverImageUrl!), fit: BoxFit.cover) : null,
        ),
        child: !hasImage ? const Icon(Icons.music_note, color: AppColors.hint, size: 24) : null,
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
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.hint, size: 20),
            onPressed: () => _showSongOptionsSheet(context, ref),
          ),
        ],
      ),
      onTap: onTap ?? () {
        context.push(Routes.songById(song.id), extra: SongPlayerRouteData(song: song, category: 'PLAYLIST'));
      },
    );
  }
}

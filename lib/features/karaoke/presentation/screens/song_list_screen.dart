import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart';
import 'package:music_app_frontend/shared/widgets/success_popup.dart';
import '../controllers/karaoke_controller.dart';
import '../../data/models/karaoke_song.dart';
import '../widgets/karaoke_options_sheet.dart';
import 'player_screen.dart';
import 'lyric_editor_screen.dart';
import 'my_karaoke_list_screen.dart';
import 'karaoke_playlist_songs_screen.dart';
import 'package:music_app_frontend/core/utils/song_matcher.dart';

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KaraokeController>(
      builder: (context, controller, _) {
        if (controller.isLoading && controller.songs.isEmpty && controller.publicSongs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final filteredOwnSongs = controller.songs.where((song) {
          final titleMatch = song.title.toLowerCase().contains(_searchQuery.toLowerCase());
          final artistMatch = (song.artist ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
          return titleMatch || artistMatch;
        }).toList();

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadSongs,
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search in your karaoke space...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white70),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              // Content Area
              Expanded(
                child: _searchQuery.isNotEmpty
                    ? _buildSearchResults(filteredOwnSongs, controller)
                    : _buildDashboard(context, controller),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(List<KaraokeSong> songs, KaraokeController controller) {
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            const Text(
              'No matching songs found in your space',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final hasLyrics = song.lyrics.isNotEmpty;
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: song.source == SongSource.youtube
                    ? Colors.red.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                song.source == SongSource.youtube
                    ? Icons.play_circle_filled
                    : Icons.music_note,
                color: song.source == SongSource.youtube
                    ? Colors.red
                    : AppColors.primary,
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    song.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                rp.Consumer(
                  builder: (context, ref, _) {
                    final me = ref.watch(meProvider).valueOrNull;
                    final isOwner = me != null && song.userId == me.id;
                    final badgeText = isOwner
                        ? (song.isPublic ? 'Yours • Public' : 'Yours • Private')
                        : (song.isPublic ? 'Public' : 'Private');
                    final badgeColor = isOwner
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
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
             subtitle: Text(
               song.artist ?? 'Unknown Artist',
               style: const TextStyle(color: Colors.grey),
               maxLines: 1,
               overflow: TextOverflow.ellipsis,
             ),
            trailing: rp.Consumer(
              builder: (context, ref, _) {
                return IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onPressed: () {
                    showKaraokeOptionsSheet(
                      context: context,
                      ref: ref,
                      song: song,
                      controller: controller,
                    );
                  },
                );
              },
            ),
            onTap: () {
              if (hasLyrics) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerScreen(song: song, controller: controller),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LyricEditorScreen(song: song, controller: controller),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildDashboard(BuildContext context, KaraokeController controller) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // My Karaoke Playlist Card
        _buildMyKaraokePlaylistTile(context, controller.songs.length),
        const SizedBox(height: 24),

        // Liked Karaoke Songs Section
        _buildLikedKaraokeSongsSection(context, controller),

        // Popular Karaoke Section
        _buildSectionTitle('Popular Karaoke'),
        const SizedBox(height: 12),
        _buildPopularKaraokeList(context, controller),
        const SizedBox(height: 28),

        // My Karaoke Songs (Playlists area)
        _buildMyKaraokeSongsAsPlaylistsSection(context, controller),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildKaraokePlaylistsSection(BuildContext context, KaraokeController controller) {
    return rp.Consumer(
      builder: (context, ref, _) {
        final playlists = ref.watch(myPlaylistsProvider).value ?? [];
        final karaokeSongs = controller.songs;

        final karaokePlaylists = playlists.where((playlist) {
          final playlistSongs = playlist.songs ?? [];
          return playlistSongs.any((s) => karaokeSongs.any((ks) => ks.id == s.id));
        }).toList();

        if (karaokePlaylists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Karaoke Playlists'),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: karaokePlaylists.length,
                itemBuilder: (context, index) {
                  final playlist = karaokePlaylists[index];
                  final playlistKaraokeSongs = karaokeSongs.where((ks) {
                    final inSongs = playlist.songs?.any((s) => s.id == ks.id) ?? false;
                    final inSongIds = playlist.songIds?.contains(ks.id) ?? false;
                    return inSongs || inSongIds;
                  }).toList();

                  final bool hasImage = playlist.coverImageUrl != null && playlist.coverImageUrl!.isNotEmpty;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KaraokePlaylistSongsScreen(
                            playlist: playlist,
                            controller: controller,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Artwork
                          Container(
                            width: 140,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: hasImage
                                  ? DecorationImage(
                                      image: NetworkImage(playlist.coverImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              gradient: !hasImage
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFF39C12), // Orange
                                        Color(0xFFD35400), // Dark Orange
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                if (!hasImage)
                                  const Center(
                                    child: Icon(
                                      Icons.playlist_play_rounded,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.mic_none_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${playlistKaraokeSongs.length} ${playlistKaraokeSongs.length == 1 ? "song" : "songs"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }

  Widget _buildMyKaraokePlaylistTile(BuildContext context, int songCount) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF2C1A4D).withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColors.primary.withValues(alpha: 0.1),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.mic_none_rounded,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        title: const Text(
          'My Karaoke',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Playlist • $songCount songs',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70),
        onTap: () {
          final controller = Provider.of<KaraokeController>(context, listen: false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider<KaraokeController>.value(
                value: controller,
                child: const MyKaraokeListScreen(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPopularKaraokeList(BuildContext context, KaraokeController controller) {
    final publicSongs = controller.publicSongs;

    if (publicSongs.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No recommended public karaoke songs found.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: publicSongs.length,
        itemBuilder: (context, index) {
          final song = publicSongs[index];
          return GestureDetector(
            onTap: () {
              if (song.lyrics.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerScreen(song: song, controller: controller),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LyricEditorScreen(song: song, controller: controller),
                  ),
                );
              }
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient Card Artwork
                  Container(
                    width: 140,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8E2DE2).withValues(alpha: 0.8),
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.music_video_rounded,
                            color: Colors.white70,
                            size: 48,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: rp.Consumer(
                            builder: (context, ref, _) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  showKaraokeOptionsSheet(
                                    context: context,
                                    ref: ref,
                                    song: song,
                                    controller: controller,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist ?? 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLikedKaraokeSongsSection(BuildContext context, KaraokeController controller) {
    return rp.Consumer(
      builder: (context, ref, _) {
        final likedPlaylistAsync = ref.watch(likedSongsPlaylistProvider);
        final me = ref.watch(meProvider).valueOrNull;
        return likedPlaylistAsync.when(
          data: (playlist) {
            final likedSongs = playlist.songs ?? [];
            if (likedSongs.isEmpty) return const SizedBox.shrink();

            final likedKaraokeSongs = <KaraokeSong>[];
            for (final song in likedSongs) {
              final candidates = [...controller.songs, ...controller.publicSongs];
              KaraokeSong? match;
              for (final ks in candidates) {
                if (isSongMatch(ks, song)) {
                  final isMySong = me != null && song.userId == me.id;
                  if (isMySong) {
                    if (ks.userId == me.id) {
                      match = ks;
                      break;
                    }
                  } else {
                    match = ks;
                    break;
                  }
                }
              }
              if (match != null) {
                likedKaraokeSongs.add(match);
              }
            }

            if (likedKaraokeSongs.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Liked Karaoke Songs'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: likedKaraokeSongs.length,
                    itemBuilder: (context, index) {
                      final song = likedKaraokeSongs[index];
                      final hasLyrics = song.lyrics.isNotEmpty;
                      return GestureDetector(
                        onTap: () {
                          if (hasLyrics) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlayerScreen(song: song, controller: controller),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LyricEditorScreen(song: song, controller: controller),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 140,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.redAccent.withValues(alpha: 0.8),
                                      const Color(0xFFC0392B).withValues(alpha: 0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    const Center(
                                      child: Icon(
                                        Icons.favorite_rounded,
                                        color: Colors.white70,
                                        size: 48,
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: rp.Consumer(
                                        builder: (context, ref, _) {
                                          return GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              showKaraokeOptionsSheet(
                                                context: context,
                                                ref: ref,
                                                song: song,
                                                controller: controller,
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.more_vert,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.artist ?? 'Unknown Artist',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildMyKaraokeSongsAsPlaylistsSection(BuildContext context, KaraokeController controller) {
    return rp.Consumer(
      builder: (context, ref, _) {
        final playlistsAsync = ref.watch(myPlaylistsProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('My Karaoke Songs'),
                IconButton(
                  icon: const Icon(Icons.playlist_add_rounded, color: AppColors.primary, size: 28),
                  tooltip: 'Create Playlist',
                  onPressed: () {
                    _showCreatePlaylistDialog(context, ref);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            playlistsAsync.when(
              data: (playlists) {
                final userPlaylists = playlists.where((p) => p.isKaraoke).toList();
                if (userPlaylists.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'No playlists created yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showCreatePlaylistDialog(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Playlist'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userPlaylists.length,
                  itemBuilder: (context, index) {
                    final playlist = userPlaylists[index];
                    final bool hasImage = playlist.coverImageUrl != null && playlist.coverImageUrl!.isNotEmpty;

                    final playlistKaraokeSongs = controller.songs.where((ks) {
                      final inSongs = playlist.songs?.any((s) => s.id == ks.id) ?? false;
                      final inSongIds = playlist.songIds?.contains(ks.id) ?? false;
                      return inSongs || inSongIds;
                    }).toList();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: hasImage
                                ? DecorationImage(
                                    image: NetworkImage(playlist.coverImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            gradient: !hasImage
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF8E2DE2),
                                      Color(0xFF4A00E0),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                          ),
                          child: !hasImage
                              ? const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 28)
                              : null,
                        ),
                        title: Text(
                          playlist.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${playlistKaraokeSongs.length} karaoke songs • ${playlist.isPublic ? "Public" : "Private"}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KaraokePlaylistSongsScreen(
                                playlist: playlist,
                                controller: controller,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Text('Error loading playlists: $e', style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, rp.WidgetRef ref) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Karaoke Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                final myPlaylistsNotifier = ref.read(myPlaylistsProvider.notifier);
                await myPlaylistsNotifier.createPlaylist(name, isKaraoke: true);
                if (context.mounted) {
                  SuccessPopup.show(
                    context,
                    title: 'Playlist Created',
                    subtitle: 'Playlist "$name" was created successfully',
                    icon: Icons.playlist_add_check_rounded,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create playlist: $e')),
                  );
                }
              }
            },
            child: const Text('Create', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

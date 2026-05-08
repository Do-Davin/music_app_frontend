import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/mock_data.dart' hide Song;
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/features/playlist/services/liked_songs_service.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/providers/song_provider.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

// ── Changed from StatelessWidget to StatefulWidget ────────────────────────────
// We need State so we can track _isLoading and call setState after the delay
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const Color backgroundColor = AppColors.background;
  static const Color accentColor = AppColors.primary;

  // Tracks whether we are still in the loading phase
  bool _isLoading = true;
  final Set<String> _likedSongIds = <String>{};
  bool _isLoadingLikedSongs = true;

  @override
  void initState() {
    super.initState();
    // Simulate a 2-second API delay so the skeleton is visible
    // TODO: Replace this with a real API call later
    Future.delayed(const Duration(seconds: 2), () {
      // mounted check prevents setState being called after widget is destroyed
      if (mounted) setState(() => _isLoading = false);
    });

    _loadLikedSongs();
  }

  Future<void> _loadLikedSongs() async {
    try {
      final likedSongs = await LikedSongsService().fetchLikedSongs();
      if (!mounted) return;
      setState(() {
        _likedSongIds
          ..clear()
          ..addAll(likedSongs.map((s) => s.id));
        _isLoadingLikedSongs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingLikedSongs = false);
    }
  }

  Future<void> _toggleLike(Song song) async {
    final alreadyLiked = _likedSongIds.contains(song.id);

    setState(() {
      if (alreadyLiked) {
        _likedSongIds.remove(song.id);
      } else {
        _likedSongIds.add(song.id);
      }
    });

    try {
      await LikedSongsService().toggleLikeSong(song.id);
    } catch (e) {
      if (!mounted) return;
      // revert optimistic update
      setState(() {
        if (alreadyLiked) {
          _likedSongIds.add(song.id);
        } else {
          _likedSongIds.remove(song.id);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update like: $e'),
          backgroundColor: AppColors.surface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        // If still loading → show skeleton, otherwise → show real content
        child: _isLoading
            ? const HomeSkeletonLoader()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Continue Listening'),
                    _buildContinueListeningCard(),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Your Favorites'),
                    _buildFavoritesGrid(),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Recently Played'),
                    songsAsync.when(
                      data: (songs) => _buildHorizontalSongList(
                        songs.take(8).toList(),
                        'RECENTLY PLAYED',
                      ),
                      loading: () => const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Recommended'),
                    songsAsync.when(
                      data: (songs) => _buildHorizontalSongList(
                        songs.skip(8).take(8).toList(),
                        'RECOMMENDED FOR YOU',
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Made for you'),
                    songsAsync.when(
                      data: (songs) => _buildHorizontalSongList(
                        songs.skip(16).take(8).toList(),
                        'MADE FOR YOU',
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Browse by mood'),
                    _buildMoodGrid(),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Popular Artists'),
                    _buildPopularArtists(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHorizontalSongList(List<Song> songs, String categoryName) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        separatorBuilder: (a, b) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final song = songs[index];
          final isLiked = _likedSongIds.contains(song.id);

          return GestureDetector(
            onTap: () {},
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          song.coverImageUrl ?? '',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 140,
                            height: 140,
                            color: AppColors.surface,
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minHeight: 36,
                              minWidth: 36,
                            ),
                            onPressed: _isLoadingLikedSongs
                                ? null
                                : () => _toggleLike(song),
                            icon: Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color:
                                  isLiked ? AppColors.primary : Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Hello, ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: 'Rith!',
                style: TextStyle(color: accentColor),
              ),
            ],
          ),
        ),
        const Row(
          children: [
            Icon(Icons.notifications_none, color: Colors.grey, size: 28),
            SizedBox(width: 16),
            Icon(Icons.settings_outlined, color: Colors.grey, size: 28),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: accentColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContinueListeningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://picsum.photos/seed/starboy/100',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Starboy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'The Weeknd',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      '11 Dec • 12 min left',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 0.4,
                        backgroundColor: AppColors.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: MockData.favorites.length,
      itemBuilder: (context, index) {
        final playlist = MockData.favorites[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: playlist.gradientColors != null
                ? LinearGradient(
                    colors: playlist.gradientColors!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            image: playlist.imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(playlist.imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.4),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (playlist.gradientColors != null)
                  const Center(
                    child: Icon(
                      Icons.favorite,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                const Spacer(),
                Text(
                  playlist.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: MockData.moods.length,
      itemBuilder: (context, index) {
        final mood = MockData.moods[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(mood.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                mood.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopularArtists() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MockData.popularArtistsUrls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          return CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(MockData.popularArtistsUrls[index]),
          );
        },
      ),
    );
  }
}

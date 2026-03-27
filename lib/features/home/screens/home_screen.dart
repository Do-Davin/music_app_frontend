import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/mock_data.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/features/song/screens/song_player_screen.dart';
// Note: Ensure you import your AppColors if you have them defined
// import 'package:music_app_frontend/core/constants/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Theme Constants based on your Figma design
  static const Color backgroundColor = AppColors.background; // Dark background
  static const Color accentColor = AppColors.primary; // Orange accent

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // SafeArea prevents UI from drawing under the phone's status bar/notch
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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
              _buildHorizontalSongList(MockData.recentlyPlayed),
              const SizedBox(height: 32),

              _buildSectionTitle('Recommended'),
              _buildHorizontalSongList(MockData.recommended),
              const SizedBox(height: 32),

              _buildSectionTitle('Made for you'),
              _buildHorizontalSongList(MockData.madeForYou),
              const SizedBox(height: 32),

              _buildSectionTitle('Browse by mood'),
              _buildMoodGrid(),
              const SizedBox(height: 32),

              _buildSectionTitle('Popular Artists'),
              _buildPopularArtists(),
              const SizedBox(height: 32), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

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
        color: const Color(0xFF232323), // Slightly lighter than background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://picsum.photos/seed/starboy/100', // Starboy mock image
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
                        value: 0.4, // 40% complete
                        backgroundColor: Colors.grey.shade800,
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
      physics:
          const NeverScrollableScrollPhysics(), // Prevent grid from scrolling independently
      shrinkWrap:
          true, // Allow grid to take up only needed space inside SingleChildScrollView
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4, // Width vs Height ratio
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

  Widget _buildHorizontalSongList(List<Song> songs) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final song = songs[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongPlayerScreen(song: song),
                ),
              );
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      song.imageUrl,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
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

  Widget _buildMoodGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8, // Wide cards
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
            radius: 50, // 100x100 circle
            backgroundImage: NetworkImage(MockData.popularArtistsUrls[index]),
          );
        },
      ),
    );
  }
}

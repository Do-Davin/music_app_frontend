import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/mock_data.dart';

// Provider to manage the search query state
final searchQueryProvider = StateProvider<String>((ref) => "");

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final isSearching = query.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark theme background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildHeader(ref, query),
              const SizedBox(height: 20),
              Expanded(
                child: isSearching
                    ? _buildSearchResults(query)
                    : _buildInitialView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header with Search Bar ---
  Widget _buildHeader(WidgetRef ref, String query) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => ref.read(searchQueryProvider.notifier).state = "",
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const Text(
              'Search',
              style: TextStyle(
                color: AppColors.navSelected, // Your orange/gold color
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 32), // Spacer for balance
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (val) =>
              ref.read(searchQueryProvider.notifier).state = val,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Artist, Lyrics, Song and more",
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: AppColors.navSelected),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () =>
                        ref.read(searchQueryProvider.notifier).state = "",
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            filled: true,
            fillColor: Colors.black,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.navSelected),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.navSelected,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- View 1: Recent, Trending, Browse ---
  Widget _buildInitialView() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildSectionTitle("Recent", showAction: true),
        _buildSimpleList([
          "Bek oun bong jes smos",
          "Sl ke tae mnek eg",
          "Hort mes jivit",
        ]),
        const SizedBox(height: 30),
        _buildSectionTitle("Trending"),
        _buildSimpleList([
          "Die with a smile",
          "Take it all",
          "When i was your man",
        ]),
        const SizedBox(height: 30),
        _buildSectionTitle("Browse all"),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: MockData.recentlyPlayed.length.clamp(0, 3),
          itemBuilder: (context, index) {
            final song = MockData.recentlyPlayed[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(song.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // --- View 2: Search Results ---
  Widget _buildSearchResults(String query) {
    // Combine mock lists to simulate a database search
    final allSongs = [
      ...MockData.recentlyPlayed,
      ...MockData.recommended,
      ...MockData.madeForYou,
    ];

    final results = allSongs
        .where(
          (s) =>
              s.title.toLowerCase().contains(query.toLowerCase()) ||
              s.artist.toLowerCase().contains(query.toLowerCase()) ||
              s.lyricsSnippet.toLowerCase().contains(query.toLowerCase()),
        )
        .toSet()
        .toList(); // toSet() removes duplicates if a song is in multiple lists

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final song = results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              song.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            song.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            "Song • ${song.artist}",
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          trailing: const Icon(Icons.more_vert, color: Colors.white54),
        );
      },
    );
  }

  // --- Helpers ---
  Widget _buildSectionTitle(String title, {bool showAction = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navSelected,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showAction)
          const Text(
            "Clear",
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
      ],
    );
  }

  Widget _buildSimpleList(List<String> items) {
    return Column(
      children: items
          .map(
            (item) => Column(
              children: [
                ListTile(
                  title: Text(
                    item,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                const Divider(color: Colors.white10, height: 1),
              ],
            ),
          )
          .toList(),
    );
  }
}

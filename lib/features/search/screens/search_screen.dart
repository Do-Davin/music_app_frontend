import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/core/constants/mock_data.dart' hide Song;
import 'package:music_app_frontend/features/song/providers/song_provider.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/screens/song_player_screen.dart';
import 'package:music_app_frontend/features/search/providers/recent_songs_provider.dart';

// Provider to manage the search query state
final searchQueryProvider = StateProvider<String>((ref) => "");

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final isSearching = query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                    ? _buildSearchResults(context, ref, query)
                    : _buildInitialView(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Text(
              'Search',
              style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
            ),
            const SizedBox(width: 32),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (val) =>
              ref.read(searchQueryProvider.notifier).state = val,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: "Artist, Lyrics, Song and more",
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.onSurface),
                    onPressed: () =>
                        ref.read(searchQueryProvider.notifier).state = "",
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            filled: true,
            fillColor: AppColors.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialView(BuildContext context, WidgetRef ref) {
    final recentSongs = ref.watch(recentSongsProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        if (recentSongs.isNotEmpty) ...[
          _buildSectionTitle(
            "Recent",
            showAction: true,
            onActionTap: () => ref.read(recentSongsProvider.notifier).clear(),
          ),
          _buildSongList(context, ref, recentSongs),
          const SizedBox(height: 30),
        ],
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
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.hint,
                    fontSize: 10,
                  ),
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

  Widget _buildSearchResults(BuildContext context, WidgetRef ref, String query) {
    final searchResults = ref.watch(searchSongsProvider(query));

    return searchResults.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text('No results found', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                Text(
                  'Try searching for a different song or artist',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.hint,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final song = results[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: song.coverImageUrl != null
                    ? Image.network(
                        song.coverImageUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.surface,
                          child: const Icon(Icons.music_note,
                              color: AppColors.primary),
                        ),
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        color: AppColors.surface,
                        child: const Icon(Icons.music_note,
                            color: AppColors.primary),
                      ),
              ),
              title: Text(
                song.title,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Song • ${song.artist}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.hint,
                  fontSize: 13,
                ),
              ),
              trailing: const Icon(Icons.more_vert, color: AppColors.hint),
              onTap: () {
                // Add to recent
                ref.read(recentSongsProvider.notifier).addSong(song);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SongPlayerScreen(
                      song: song,
                      category: 'Search Result',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error: $error',
          style: AppTextStyles.body.copyWith(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title,
      {bool showAction = false, VoidCallback? onActionTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.body.copyWith(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showAction)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              'Clear',
              style: AppTextStyles.body.copyWith(
                color: AppColors.hint,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSongList(BuildContext context, WidgetRef ref, List<Song> songs) {
    return Column(
      children: songs
          .map(
            (song) => Column(
              children: [
                ListTile(
                  title: Text(
                    song.title,
                    style: AppTextStyles.body.copyWith(fontSize: 14),
                  ),
                  subtitle: Text(
                    song.artist,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.hint,
                      fontSize: 12,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SongPlayerScreen(
                          song: song,
                          category: 'Recent',
                        ),
                      ),
                    );
                  },
                ),
                Divider(
                  color: Colors.white.withValues(alpha: 0.10),
                  height: 1,
                ),
              ],
            ),
          )
          .toList(),
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
                    style: AppTextStyles.body.copyWith(fontSize: 14),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                Divider(
                  color: Colors.white.withValues(alpha: 0.10),
                  height: 1,
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}

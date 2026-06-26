import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/core/constants/mock_data.dart' hide Song;
import 'package:music_app_frontend/features/song/providers/song_provider.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/screens/song_player_screen.dart';
import 'package:music_app_frontend/features/search/providers/recent_songs_provider.dart';
import 'package:music_app_frontend/features/playlist/screens/playlist_detail_screen.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart' as model;
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app_frontend/features/song/providers/global_audio_player_provider.dart';

import 'package:music_app_frontend/features/search/providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final query = ref.read(searchQueryProvider);
      if (query.isNotEmpty) {
        _searchController.text = query;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    // Use the debounced query to trigger actual API calls
    final debouncedQuery = ref.watch(debouncedSearchQueryProvider);
    final isSearching = query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildHeader(query),
              const SizedBox(height: 20),
              Expanded(
                child: isSearching
                    ? _buildSearchResults(context, ref, debouncedQuery)
                    : _buildInitialView(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String query) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Search',
            style: AppTextStyles.subtitle.copyWith(color: AppColors.primary), 
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _searchController,
          onChanged: (val) {
            ref.read(searchQueryProvider.notifier).state = val;
            ref.read(debouncedSearchQueryProvider.notifier).update(val);
          },
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
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = "";
                      ref.read(debouncedSearchQueryProvider.notifier).update("");
                    },
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
    final recentItems = ref.watch(recentItemsProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        if (recentItems.isNotEmpty) ...[
          _buildSectionTitle(
            "Recent",
            showAction: true,
            onActionTap: () => ref.read(recentItemsProvider.notifier).clear(),
          ),
          _buildRecentList(context, ref, recentItems),
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
                    child: song.imageUrl.isNotEmpty
                        ? Image.network(
                            song.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const _SongCoverPlaceholder(),
                          )
                        : const _SongCoverPlaceholder(),
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
    final activeTab = ref.watch(searchTabProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildTabButton(ref, 'All', activeTab == 'All'),
            const SizedBox(width: 12),
            _buildTabButton(ref, 'Songs', activeTab == 'Songs'),
            const SizedBox(width: 12),
            _buildTabButton(ref, 'Playlists', activeTab == 'Playlists'),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: activeTab == 'All'
              ? _buildAllSearchResults(context, ref, query)
              : activeTab == 'Songs'
                  ? _buildSongsSearchResults(context, ref, query)
                  : _buildPlaylistsSearchResults(context, ref, query),
        ),
      ],
    );
  }

  Widget _buildTabButton(WidgetRef ref, String label, bool isActive) {
    return GestureDetector(
      onTap: () => ref.read(searchTabProvider.notifier).state = label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.white10,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isActive ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAllSearchResults(BuildContext context, WidgetRef ref, String query) {
    final searchResults = ref.watch(searchAllProvider(query));
    final me = ref.watch(meProvider).valueOrNull;

    return searchResults.when(
      data: (results) {
        if (results.isEmpty) {
          return _buildNoResultsState('No results found', 'Try searching for something else');
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            if (item is Song) {
              return SongTile(
                song: item,
                index: index,
                showTypeBadge: true,
                onTap: () {
                  ref.read(recentItemsProvider.notifier).addItem(item);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SongPlayerScreen(
                        song: item,
                        category: 'Search Result',
                      ),
                    ),
                  );
                },
              );
            } else if (item is model.Playlist) {
              return _buildPlaylistTile(context, ref, item, me?.id, showTypeBadge: true);
            }
            return const SizedBox.shrink();
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildSongsSearchResults(BuildContext context, WidgetRef ref, String query) {
    final searchResults = ref.watch(searchSongsProvider(query));
    final me = ref.watch(meProvider).valueOrNull;

    return searchResults.when(
      data: (results) {
        if (results.isEmpty) {
          return _buildNoResultsState('No songs found', 'Try searching for a different song or artist');
        }

        // Sort: user's own songs first
        final sortedSongs = List<Song>.from(results)..sort((a, b) {
          final aIsMine = me != null && a.userId == me.id;
          final bIsMine = me != null && b.userId == me.id;
          if (aIsMine && !bIsMine) return -1;
          if (!aIsMine && bIsMine) return 1;
          return 0;
        });

        return ListView.builder(
          itemCount: sortedSongs.length,
          itemBuilder: (context, index) {
            final song = sortedSongs[index];
            return SongTile(
              song: song,
              index: index,
              onTap: () {
                // Add to recent
                ref.read(recentItemsProvider.notifier).addItem(song);

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
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildPlaylistTile(
    BuildContext context,
    WidgetRef ref,
    model.Playlist playlist,
    String? currentUserId, {
    bool showTypeBadge = false,
  }) {
    final isMine = currentUserId != null && playlist.userId == currentUserId;
    final isAdded = playlist.savedUserIds?.contains(currentUserId ?? '') ?? false;
    final songCount = playlist.songIds?.length ?? 0;
    final hasImage = playlist.coverImageUrl != null && playlist.coverImageUrl!.isNotEmpty;

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
                  image: NetworkImage(playlist.coverImageUrl!),
                  fit: BoxFit.cover,
                  onError: (_, _) {},
                )
              : null,
        ),
        child: !hasImage
            ? const Icon(Icons.playlist_play, color: AppColors.hint, size: 24)
            : null,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              playlist.name,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showTypeBadge) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4), width: 0.5),
              ),
              child: const Text(
                'PLAYLIST',
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isMine ? AppColors.primary.withValues(alpha: 0.2) : Colors.white10,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isMine ? AppColors.primary : Colors.white24,
                width: 0.5,
              ),
            ),
            child: Text(
              isMine ? 'Yours' : 'Public',
              style: TextStyle(
                color: isMine ? AppColors.primary : Colors.grey,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        'Playlist • $songCount songs',
        style: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 12),
      ),
      trailing: isMine
          ? null
          : IconButton(
              icon: Icon(
                isAdded ? Icons.library_add_check : Icons.library_add,
                color: isAdded ? AppColors.primary : AppColors.hint,
                size: 24,
              ),
              onPressed: () => _togglePlaylistLibrary(context, ref, playlist, isAdded),
            ),
      onTap: () {
        ref.read(recentItemsProvider.notifier).addItem(playlist);
        context.push(Routes.playlistById(playlist.id));
      },
    );
  }

  Widget _buildPlaylistsSearchResults(BuildContext context, WidgetRef ref, String query) {
    final searchResults = ref.watch(searchPlaylistsProvider(query));
    final me = ref.watch(meProvider).valueOrNull;

    return searchResults.when(
      data: (playlists) {
        if (playlists.isEmpty) {
          return _buildNoResultsState('No playlists found', 'Try searching for a different playlist name');
        }

        // Sort: user's own playlists first
        final sortedPlaylists = List<model.Playlist>.from(playlists)..sort((a, b) {
          final aIsMine = me != null && a.userId == me.id;
          final bIsMine = me != null && b.userId == me.id;
          if (aIsMine && !bIsMine) return -1;
          if (!aIsMine && bIsMine) return 1;
          return 0;
        });

        return ListView.builder(
          itemCount: sortedPlaylists.length,
          itemBuilder: (context, index) {
            final playlist = sortedPlaylists[index];
            return _buildPlaylistTile(context, ref, playlist, me?.id, showTypeBadge: false);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildNoResultsState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Text(
            subtitle,
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

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(
            error.toString().replaceAll('Exception: ', ''),
            style: AppTextStyles.body.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<bool> _showAddConfirmationDialog(BuildContext context, String playlistName) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bookmark_add, color: AppColors.primary, size: 28),
            SizedBox(width: 12),
            Text(
              'Add Playlist',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Would you like to save "$playlistName" to your library?',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Add to Library',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _togglePlaylistLibrary(BuildContext context, WidgetRef ref, model.Playlist playlist, bool isAdded) async {
    if (!isAdded) {
      final confirmed = await _showAddConfirmationDialog(context, playlist.name);
      if (!confirmed) return;
    }

    final playlistService = ref.read(playlistServiceProvider);
    try {
      if (isAdded) {
        await playlistService.removePlaylistFromLibrary(playlist.id);
      } else {
        await playlistService.savePlaylistToLibrary(playlist.id);
      }
      // Refresh playlists providers
      ref.invalidate(myPlaylistsProvider);
      ref.invalidate(searchPlaylistsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAdded ? 'Removed from library' : 'Added to library',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

  Widget _buildRecentList(BuildContext context, WidgetRef ref, List<dynamic> items) {
    return Column(
      children: items
          .map((item) {
            final id = item is Song ? item.id : (item as model.Playlist).id;
            return Dismissible(
              key: Key(id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                ref.read(recentItemsProvider.notifier).removeItem(id);
              },
              background: Container(
                color: Colors.red.withValues(alpha: 0.8),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Column(
                children: [
                  if (item is Song)
                    ListTile(
                      title: Text(
                        item.title,
                        style: AppTextStyles.body.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        item.artist,
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
                              song: item,
                              category: 'Recent',
                            ),
                          ),
                        );
                      },
                    )
                  else if (item is model.Playlist)
                    ListTile(
                      title: Text(
                        item.name,
                        style: AppTextStyles.body.copyWith(fontSize: 14),
                      ),
                      subtitle: Text(
                        'Playlist',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.hint,
                          fontSize: 12,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onTap: () {
                        context.push(Routes.playlistById(item.id));
                      },
                    ),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.10),
                    height: 1,
                  ),
                ],
              ),
            );
          })
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

class _SongCoverPlaceholder extends StatelessWidget {
  const _SongCoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.music_note,
        color: AppColors.hint,
        size: 22,
      ),
    );
  }
}

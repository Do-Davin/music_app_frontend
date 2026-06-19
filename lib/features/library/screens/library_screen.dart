import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart'
    as model;
import 'package:music_app_frontend/features/song/providers/song_provider.dart';
import 'package:music_app_frontend/features/song/models/song.dart'
    as song_model;
import 'package:music_app_frontend/core/routing/app_router.dart';
import 'create_library_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool isGridView = false;
  String selectedFilter = 'All';
  String searchQuery = '';

  void _showCreateLibrarySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navBar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          CreateLibrarySheet(parentContext: context, parentRef: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final playlistsAsync = ref.watch(myPlaylistsProvider);
        final mySongsAsync = ref.watch(mySongsProvider);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  // Header
                  Center(
                    child: Text(
                      'Your Library',
                      style: AppTextStyles.header.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Search Bar + Plus Button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 45,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            onChanged: (value) =>
                                setState(() => searchQuery = value),
                            style: AppTextStyles.body.copyWith(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Artist, Lyrics, Song and more',
                              hintStyle: AppTextStyles.body.copyWith(
                                color: AppColors.hint,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.hint,
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _showCreateLibrarySheet(context),
                        icon: const Icon(
                          Icons.add,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Filter Chips
                  Row(
                    children: [
                      _buildFilterChip('Playlists'),
                      const SizedBox(width: 8),
                      _buildFilterChip('My Songs'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Artists'),
                      if (selectedFilter != 'All') ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.hint,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => selectedFilter = 'All'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Sort Row
                  Row(
                    children: [
                      const Icon(
                        Icons.swap_vert,
                        color: AppColors.onSurface,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Recents',
                        style: AppTextStyles.body.copyWith(fontSize: 14),
                      ),
                      const Spacer(),
                      if (selectedFilter != 'My Songs')
                        IconButton(
                          onPressed: () =>
                              setState(() => isGridView = !isGridView),
                          icon: Icon(
                            isGridView ? Icons.list : Icons.grid_view_rounded,
                            color: AppColors.onSurface,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  // Content
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        if (selectedFilter == 'My Songs') {
                          return ref.refresh(mySongsProvider.future);
                        } else {
                          return ref
                              .read(myPlaylistsProvider.notifier)
                              .loadPlaylists();
                        }
                      },
                      child: selectedFilter == 'My Songs'
                          ? _buildMySongsContent(context, mySongsAsync)
                          : playlistsAsync.when(
                              data: (playlists) {
                                final filteredList = playlists.where((
                                  playlist,
                                ) {
                                  final matchesSearch = playlist.name
                                      .toLowerCase()
                                      .contains(searchQuery.toLowerCase());
                                  if (selectedFilter == 'Playlists') {
                                    return matchesSearch;
                                  } else if (selectedFilter == 'Artists') {
                                    return false; // We don't have artists yet
                                  }
                                  return matchesSearch;
                                }).toList();

                                if (filteredList.isEmpty) {
                                  return ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.2,
                                      ),
                                      AppEmptyStateWidget(
                                        icon: Icons.library_music_outlined,
                                        title: 'No Playlists Found',
                                        subtitle:
                                            'Try searching for a different name or pull down to refresh',
                                        iconColor: AppColors.primary,
                                      ),
                                    ],
                                  );
                                }

                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: isGridView
                                      ? _buildGridView(
                                          filteredList,
                                          key: const ValueKey('grid'),
                                        )
                                      : _buildListView(
                                          filteredList,
                                          key: const ValueKey('list'),
                                        ),
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                              error: (err, stack) => ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.2,
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: AppColors.error,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          err.toString().replaceAll(
                                            'Exception: ',
                                            '',
                                          ),
                                          style: AppTextStyles.body,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pull down to retry',
                                          style: AppTextStyles.body.copyWith(
                                            color: AppColors.hint,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = isSelected ? 'All' : label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Fixed: AppColors.card instead of Color(0xFF282828)
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            // Fixed: AppColors.onPrimary instead of Colors.black
            color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLikedSongsListTile(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.7),
              AppColors.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.favorite_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      title: Text(
        'Liked Songs',
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Playlist',
        style: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 12),
      ),
      onTap: () => context.push(Routes.likedSongs),
    );
  }

  Widget _buildLikedSongsGridTile(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.likedSongs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.7),
                    AppColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Liked Songs',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            maxLines: 1,
          ),
          Text(
            'Playlist',
            style: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<model.Playlist> playlists, {required Key key}) {
    return ListView.builder(
      key: key,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: playlists.length + 1,
      padding: const EdgeInsets.only(top: 10),
      itemBuilder: (context, index) {
        if (index == 0) return _buildLikedSongsListTile(context);
        final item = playlists[index - 1];
        final songCount = item.songIds?.length ?? 0;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          leading: _buildImageTile(item, 64),
          title: Text(
            item.name,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Playlist • $songCount songs',
            style: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 12,
            ),
          ),
          onTap: () {
            context.push(Routes.playlistById(item.id));
          },
        );
      },
    );
  }

  Widget _buildGridView(List<model.Playlist> playlists, {required Key key}) {
    return GridView.builder(
      key: key,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.75,
      ),
      itemCount: playlists.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildLikedSongsGridTile(context);
        final item = playlists[index - 1];
        return GestureDetector(
          onTap: () {
            context.push(Routes.playlistById(item.id));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildImageTile(item, double.infinity)),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
              ),
              Text(
                'Playlist',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.hint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageTile(model.Playlist item, double size) {
    final bool hasImage =
        item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: AppColors.surface,
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(item.coverImageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasImage
          ? const Icon(
              Icons.playlist_play,
              color: AppColors.onSurface,
              size: 32,
            )
          : null,
    );
  }

  Widget _buildMySongsContent(
    BuildContext context,
    AsyncValue<List<song_model.Song>> mySongsAsync,
  ) {
    return mySongsAsync.when(
      data: (songs) {
        final filteredList = songs.where((song) {
          return song.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              song.artist.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

        if (filteredList.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              AppEmptyStateWidget(
                icon: Icons.music_note,
                title: 'No Songs Found',
                subtitle: 'Try a different search or upload a new song',
                iconColor: AppColors.primary,
              ),
            ],
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: filteredList.length,
          padding: const EdgeInsets.only(top: 10),
          itemBuilder: (context, index) {
            final song = filteredList[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.surface,
                  image:
                      song.coverImageUrl != null &&
                          song.coverImageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(song.coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: song.coverImageUrl == null || song.coverImageUrl!.isEmpty
                    ? const Icon(Icons.music_note, color: AppColors.onSurface)
                    : null,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      song.title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!song.isPublic)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.hint,
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                song.artist,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.hint,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                context.push(
                  Routes.songById(song.id),
                  extra: SongPlayerRouteData(song: song, category: 'My Songs'),
                );
              },
              trailing: IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.hint),
                onPressed: () => _showMySongOptions(context, ref, song),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stack) =>
          Center(child: Text(err.toString(), style: AppTextStyles.body)),
    );
  }

  void _showMySongOptions(
    BuildContext context,
    WidgetRef ref,
    song_model.Song song,
  ) {
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
                leading: Icon(
                  song.isPublic ? Icons.lock : Icons.public,
                  color: Colors.blue,
                ),
                title: Text(
                  song.isPublic ? 'Make Private' : 'Make Public',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleMySongPrivacy(context, ref, song);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Delete Song',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMySong(context, ref, song);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleMySongPrivacy(
    BuildContext context,
    WidgetRef ref,
    song_model.Song song,
  ) async {
    final songService = ref.read(songServiceProvider);
    final newIsPublic = !song.isPublic;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await songService.updateSongVisibility(
        songId: song.id,
        isPublic: newIsPublic,
      );

      if (context.mounted) Navigator.pop(context); // Close loading dialog

      // Refresh mySongsProvider and myPlaylistsProvider
      ref.invalidate(mySongsProvider);
      ref.read(myPlaylistsProvider.notifier).refreshPlaylists();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newIsPublic ? 'Song is now Public' : 'Song is now Private',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update visibility: $e')),
        );
      }
    }
  }

  Future<void> _deleteMySong(
    BuildContext context,
    WidgetRef ref,
    song_model.Song song,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Song', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to permanently delete "${song.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    try {
      final songService = ref.read(songServiceProvider);
      await songService.deleteSong(song.id);

      if (context.mounted) Navigator.pop(context); // Close loading dialog

      // Refresh mySongsProvider and myPlaylistsProvider
      ref.invalidate(mySongsProvider);
      ref.read(myPlaylistsProvider.notifier).refreshPlaylists();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Song deleted successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete song: $e')));
      }
    }
  }
}

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
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/playlist/services/playlist_service.dart';
import 'package:music_app_frontend/shared/widgets/success_popup.dart';
import 'create_library_screen.dart';
import 'package:music_app_frontend/features/song/providers/global_audio_player_provider.dart';
import 'package:music_app_frontend/features/song/widgets/playing_equalizer_wave.dart';

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
      builder: (_) => CreateLibrarySheet(parentContext: context, parentRef: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final playlistsAsync = ref.watch(myPlaylistsProvider).whenData(
              (list) => list.where((p) => p.name != 'Liked Songs' && !p.isKaraoke).toList(),
            );
        final mySongsAsync = ref.watch(mySongsProvider);
        final likedSongsAsync = ref.watch(likedSongsPlaylistProvider);
        final likedCount = likedSongsAsync.when(
          data: (playlist) => playlist.songIds?.length ?? playlist.songs?.length ?? 0,
          loading: () => 0,
          error: (_, __) => 0,
        );

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
                          if (searchQuery.isNotEmpty && selectedFilter == 'All') {
                            final songs = mySongsAsync.value ?? [];
                            return _buildCombinedSearchContent(context, playlists, songs);
                          }
                          final filteredList = playlists.where((playlist) {
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

                          // Sort: "My Uploading" is always on top
                          final sortedList = List<model.Playlist>.from(filteredList)..sort((a, b) {
                            if (a.name == 'My Uploading' && b.name != 'My Uploading') return -1;
                            if (a.name != 'My Uploading' && b.name == 'My Uploading') return 1;
                            return 0;
                          });

                          if (sortedList.isEmpty) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.2,
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
                                    sortedList,
                                    likedCount: likedCount,
                                    key: const ValueKey('grid'),
                                  )
                                : _buildListView(
                                    sortedList,
                                    likedCount: likedCount,
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
                              height: MediaQuery.of(context).size.height * 0.2,
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
                                    err.toString().replaceAll('Exception: ', ''),
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

  Widget _buildLikedSongsListTile(BuildContext context, int count) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
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
          Icons.favorite_border,
          color: AppColors.primary,
          size: 32,
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Liked Songs',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orangeAccent, width: 0.5),
            ),
            child: const Text(
              'Your favourite',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        'Playlist • $count songs',
        style: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 12),
      ),
      onTap: () => context.push(Routes.likedSongs),
    );
  }

  Widget _buildLikedSongsGridTile(BuildContext context, int count) {
    return GestureDetector(
      onTap: () => context.push(Routes.likedSongs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.favorite_border,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Liked Songs',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orangeAccent, width: 0.5),
                ),
                child: const Text(
                  'Favourite',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Playlist • $count songs',
            style: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<model.Playlist> playlists, {required int likedCount, required Key key}) {
    return ListView.builder(
      key: key,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: playlists.length + 1,
      padding: const EdgeInsets.only(top: 10),
      itemBuilder: (context, index) {
        if (index == 0) return _buildLikedSongsListTile(context, likedCount);
        final item = playlists[index - 1];
        final songCount = item.songIds?.length ?? 0;
        final isUploadingPlaylist = item.name == 'My Uploading';
        final isSystemPlaylist = item.name == 'My Uploading' || item.name == 'Liked Songs';

        final me = ref.watch(meProvider).valueOrNull;
        final isPlaylistOwner = me != null && item.userId == me.id;

        final String badgeText = isPlaylistOwner 
            ? (item.isPublic ? 'Yours • Public' : 'Yours • Private')
            : (item.isPublic ? 'Public' : 'Private');

        final Color badgeColor = isPlaylistOwner
            ? (item.isPublic ? AppColors.primary : Colors.orangeAccent)
            : (item.isPublic ? Colors.orangeAccent : Colors.grey);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          leading: _buildImageTile(item, 64),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  item.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isUploadingPlaylist ? AppColors.primary : Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isUploadingPlaylist) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary, width: 0.5),
                  ),
                  child: const Text(
                    'My Uploads',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else if (!isSystemPlaylist) ...[
                const SizedBox(width: 8),
                Container(
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
                ),
              ],
            ],
          ),
          subtitle: Text(
            'Playlist • $songCount songs',
            style: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 12,
            ),
          ),
          trailing: isSystemPlaylist
              ? null
              : IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.hint, size: 20),
                  onPressed: () => _showPlaylistOptions(context, ref, item),
                ),
          onTap: () {
            context.push(Routes.playlistById(item.id));
          },
        );
      },
    );
  }

  Widget _buildGridView(List<model.Playlist> playlists, {required int likedCount, required Key key}) {
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
        if (index == 0) return _buildLikedSongsGridTile(context, likedCount);
        final item = playlists[index - 1];
        final isUploadingPlaylist = item.name == 'My Uploading';
        final isSystemPlaylist = item.name == 'My Uploading' || item.name == 'Liked Songs';

        final me = ref.watch(meProvider).valueOrNull;
        final isPlaylistOwner = me != null && item.userId == me.id;

        final String badgeText = isPlaylistOwner 
            ? (item.isPublic ? 'Yours • Public' : 'Yours • Private')
            : (item.isPublic ? 'Public' : 'Private');

        final Color badgeColor = isPlaylistOwner
            ? (item.isPublic ? AppColors.primary : Colors.orangeAccent)
            : (item.isPublic ? Colors.orangeAccent : Colors.grey);

        return GestureDetector(
          onTap: () {
            context.push(Routes.playlistById(item.id));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildImageTile(item, double.infinity)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isUploadingPlaylist ? AppColors.primary : Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isUploadingPlaylist) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.primary, width: 0.5),
                      ),
                      child: const Text(
                        'Uploads',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else if (!isSystemPlaylist) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
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
    final isUploadingPlaylist = item.name == 'My Uploading';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isUploadingPlaylist ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
        border: isUploadingPlaylist ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5) : null,
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(item.coverImageUrl!),
                fit: BoxFit.cover,
                onError: (_, _) {},
              )
            : null,
      ),
      child: !hasImage
          ? Icon(
              isUploadingPlaylist ? Icons.cloud_upload_outlined : Icons.playlist_play,
              color: isUploadingPlaylist ? AppColors.primary : AppColors.onSurface,
              size: 32,
            )
          : null,
    );
  }

  void _showPlaylistOptions(BuildContext context, WidgetRef ref, model.Playlist playlist) {
    final me = ref.read(meProvider).valueOrNull;
    final isPlaylistOwner = me != null && playlist.userId == me.id;
    final isSaved = playlist.savedUserIds?.contains(me?.id ?? '') ?? false;
    final isSystemPlaylist = playlist.name == 'My Uploading' || playlist.name == 'Liked Songs';

    if (isSystemPlaylist) return;

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
              
              if (isPlaylistOwner) ...[
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
                    _togglePlaylistVisibility(context, ref, playlist);
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
                    _deletePlaylist(context, ref, playlist);
                  },
                ),
              ],
              
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
                    _toggleLibraryStatus(context, ref, playlist, isSaved);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _togglePlaylistVisibility(BuildContext context, WidgetRef ref, model.Playlist playlist) async {
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

  Future<void> _deletePlaylist(BuildContext context, WidgetRef ref, model.Playlist playlist) async {
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

  Future<void> _toggleLibraryStatus(BuildContext context, WidgetRef ref, model.Playlist playlist, bool isSaved) async {
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

      if (context.mounted) {
        SuccessPopup.show(
          context,
          title: isSaved ? 'Removed from Library' : 'Added to Library',
          subtitle: isSaved ? 'Playlist removed successfully' : 'Playlist saved successfully',
          icon: isSaved ? Icons.bookmark_remove : Icons.bookmark_added,
          iconColor: isSaved ? AppColors.error : AppColors.primary,
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
            final playerState = ref.watch(globalAudioPlayerProvider);
            final isCurrentPlayingSong = playerState.currentSong?.id == song.id;
            final isPlaying = isCurrentPlayingSong && playerState.isPlaying;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: Stack(
                children: [
                  Container(
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
                              onError: (_, _) {},
                            )
                          : null,
                    ),
                    child: song.coverImageUrl == null || song.coverImageUrl!.isEmpty
                        ? const Icon(Icons.music_note, color: AppColors.onSurface)
                        : null,
                  ),
                  if (isCurrentPlayingSong)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
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
                children: [
                  Expanded(
                    child: Text(
                      song.title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isCurrentPlayingSong ? AppColors.primary : Colors.white,
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
                ref.read(globalAudioPlayerProvider.notifier).playSong(song);
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

      if (context.mounted) Navigator.pop(context);

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
        Navigator.pop(context);
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

      if (context.mounted) Navigator.pop(context);

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
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete song: $e')));
      }
    }
  }

  Widget _buildCombinedSearchContent(
    BuildContext context,
    List<model.Playlist> playlists,
    List<song_model.Song> songs,
  ) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const SizedBox.shrink();

    final matchedPlaylists = playlists.where((p) => p.name.toLowerCase().contains(query)).toList();
    final matchedSongs = songs.where((s) => s.title.toLowerCase().contains(query) || s.artist.toLowerCase().contains(query)).toList();

    final combined = <dynamic>[...matchedPlaylists, ...matchedSongs];

    if (combined.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          AppEmptyStateWidget(
            icon: Icons.search_off,
            title: 'No Results Found',
            subtitle: 'No playlists or songs match "$searchQuery"',
            iconColor: AppColors.primary,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: combined.length,
      itemBuilder: (context, index) {
        final item = combined[index];
        if (item is song_model.Song) {
          return _buildSearchSongTile(context, item);
        } else if (item is model.Playlist) {
          return _buildSearchPlaylistTile(context, item);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSearchPlaylistTile(BuildContext context, model.Playlist item) {
    final songCount = item.songIds?.length ?? 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: _buildImageTile(item, 64),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              item.name,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
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
      ),
      subtitle: Text(
        'Playlist • $songCount songs',
        style: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 12),
      ),
      onTap: () {
        context.push(Routes.playlistById(item.id));
      },
    );
  }

  Widget _buildSearchSongTile(BuildContext context, song_model.Song song) {
    final playerState = ref.watch(globalAudioPlayerProvider);
    final isCurrentPlayingSong = playerState.currentSong?.id == song.id;
    final isPlaying = isCurrentPlayingSong && playerState.isPlaying;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Stack(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: AppColors.surface,
              image: song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty
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
          if (isCurrentPlayingSong)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
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
                fontSize: 16,
                color: isCurrentPlayingSong ? AppColors.primary : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4), width: 0.5),
            ),
            child: const Text(
              'SONG',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        song.artist,
        style: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        ref.read(globalAudioPlayerProvider.notifier).playSong(song);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/core/routing/app_router.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/song/providers/song_provider.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/search/providers/recent_songs_provider.dart';

// Provider to manage the raw (un-debounced) search query for the text field UI.
final searchQueryProvider = StateProvider<String>((ref) => "");

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = "";
    ref.read(debouncedSearchQueryProvider.notifier).update("");
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final debouncedQuery = ref.watch(debouncedSearchQueryProvider);
    final isSearching = query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(query),
                  const SizedBox(height: 20),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isSearching
                          ? _buildSearchResults(context, debouncedQuery)
                          : _buildInitialView(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String query) {
    return Column(
      children: [
        Center(
          child: Text(
            'Search',
            style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (val) {
              ref.read(searchQueryProvider.notifier).state = val;
              ref.read(debouncedSearchQueryProvider.notifier).update(val);
            },
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            style: AppTextStyles.body.copyWith(fontSize: 15),
            decoration: InputDecoration(
              hintText: "Search songs, artists, lyrics...",
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.hint,
                fontSize: 14,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.hint.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.onSurface,
                          size: 16,
                        ),
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              filled: true,
              fillColor: AppColors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialView(BuildContext context) {
    final recentSongs = ref.watch(recentSongsProvider);
    final publicSongs = ref.watch(songsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(songsProvider);
        // Allow the FutureProvider to start its new fetch before returning.
        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: ListView(
        key: const ValueKey('initial'),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (recentSongs.isNotEmpty) ...[
            _buildSectionTitle(
              "Recent",
              icon: Icons.history_rounded,
              showAction: true,
              actionText: 'Clear all',
              onActionTap: () => ref.read(recentSongsProvider.notifier).clear(),
            ),
            const SizedBox(height: 8),
            _buildRecentSongsList(context, recentSongs),
            const SizedBox(height: 28),
          ],
          _buildSectionTitle("Explore Songs", icon: Icons.grid_view_rounded),
          const SizedBox(height: 12),
          _buildExploreSongsSection(context, publicSongs),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildExploreSongsSection(
    BuildContext context,
    AsyncValue<List<Song>> publicSongs,
  ) {
    return publicSongs.when(
      data: (songs) {
        if (songs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No songs available',
                style: AppTextStyles.body.copyWith(color: AppColors.hint),
              ),
            ),
          );
        }

        final displaySongs = songs.take(12).toList();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: displaySongs.length,
          itemBuilder: (context, index) {
            final song = displaySongs[index];
            return GestureDetector(
              onTap: () {
                ref.read(recentSongsProvider.notifier).addSong(song);
                context.push(
                  Routes.songById(song.id),
                  extra: SongPlayerRouteData(song: song, category: 'Explore'),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: song.coverImageUrl != null
                          ? Image.network(
                              song.coverImageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildGridPlaceholder(),
                            )
                          : _buildGridPlaceholder(),
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
              ),
            );
          },
        );
      },
      loading: () => _buildGridSkeleton(),
      error: (error, stack) => _buildExploreError(),
    );
  }

  Widget _buildGridPlaceholder() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 0.7),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.surface.withValues(alpha: value),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.surface.withValues(alpha: value),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  height: 8,
                  width: 35,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.surface.withValues(alpha: value),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildExploreError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Could not load songs',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(songsProvider),
            child: Text(
              'Retry',
              style: AppTextStyles.body.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, String query) {
    final searchResults = ref.watch(searchSongsProvider(query));

    return searchResults.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            key: const ValueKey('empty'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No results found',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching for a different song, artist,\nor check the spelling',
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
          key: const ValueKey('results'),
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final song = results[index];
            return _buildSearchResultTile(context, song, query, index);
          },
        );
      },
      loading: () => _buildSearchLoadingSkeleton(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTextStyles.subtitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().replaceAll('Exception: ', ''),
              style: AppTextStyles.body.copyWith(
                color: AppColors.hint,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultTile(
    BuildContext context,
    Song song,
    String query,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (index * 50).clamp(0, 300)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.primary.withValues(alpha: 0.1),
            highlightColor: AppColors.primary.withValues(alpha: 0.05),
            onTap: () {
              ref.read(recentSongsProvider.notifier).addSong(song);
              context.push(
                Routes.songById(song.id),
                extra: SongPlayerRouteData(
                  song: song,
                  category: 'Search Result',
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: song.coverImageUrl != null
                        ? Image.network(
                            song.coverImageUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHighlightedText(
                          song.title,
                          query,
                          AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Song',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildHighlightedText(
                                song.artist,
                                query,
                                AppTextStyles.body.copyWith(
                                  color: AppColors.hint,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, TextStyle baseStyle) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerQuery);

    if (matchIndex < 0) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(text: text.substring(0, matchIndex), style: baseStyle),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + query.length),
            style: baseStyle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: text.substring(matchIndex + query.length),
            style: baseStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.primary.withValues(alpha: 0.2)],
        ),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }

  Widget _buildSearchLoadingSkeleton() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _buildShimmerBox(56, 56, borderRadius: 10),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(14, 160),
                    const SizedBox(height: 8),
                    _buildShimmerBox(12, 100),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox(
    double height,
    double width, {
    double borderRadius = 6,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: AppColors.surface.withValues(alpha: value),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(
    String title, {
    IconData? icon,
    bool showAction = false,
    String actionText = 'Clear',
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (showAction)
          GestureDetector(
            onTap: onActionTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                actionText,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentSongsList(BuildContext context, List<Song> songs) {
    return Column(
      children: songs.map((song) {
        return Dismissible(
          key: ValueKey(song.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 22,
            ),
          ),
          onDismissed: (_) {
            ref.read(recentSongsProvider.notifier).removeSong(song.id);
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              splashColor: AppColors.primary.withValues(alpha: 0.1),
              onTap: () {
                context.push(
                  Routes.songById(song.id),
                  extra: SongPlayerRouteData(song: song, category: 'Recent'),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: song.coverImageUrl != null
                          ? Image.network(
                              song.coverImageUrl!,
                              width: 46,
                              height: 46,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildSmallPlaceholder(),
                            )
                          : _buildSmallPlaceholder(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: AppTextStyles.body.copyWith(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.hint,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.play_circle_outline_rounded,
                      color: AppColors.hint.withValues(alpha: 0.6),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSmallPlaceholder() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: AppColors.primary,
        size: 20,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/core/constants/mock_data.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';
import 'create_library_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
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
      builder: (context) => const CreateLibrarySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = MockData.favorites.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      if (selectedFilter == 'Playlists') {
        return matchesSearch && (item.name != 'SZA');
      } else if (selectedFilter == 'Artists') {
        return matchesSearch && (item.name == 'SZA');
      }
      return matchesSearch;
    }).toList();

    return Scaffold(
      // Fixed: AppColors.background instead of Colors.black
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
                  // Fixed: AppTextStyles instead of hardcoded TextStyle
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
                        // Fixed: AppColors.surface instead of Color(0xFF1E1E1E)
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          // Fixed: single dot . not double dot ..
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => searchQuery = value),
                        // Fixed: AppTextStyles instead of hardcoded TextStyle
                        style: AppTextStyles.body.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Artist, Lyrics, Song and more',
                          // Fixed: AppTextStyles + AppColors.hint
                          hintStyle: AppTextStyles.body.copyWith(
                            color: AppColors.hint,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            // Fixed: AppColors.hint instead of Colors.grey
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
                  _buildFilterChip('Artists'),
                  if (selectedFilter != 'All') ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        // Fixed: AppColors.hint instead of Colors.grey
                        color: AppColors.hint,
                        size: 20,
                      ),
                      onPressed: () => setState(() => selectedFilter = 'All'),
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
                  IconButton(
                    onPressed: () => setState(() => isGridView = !isGridView),
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: filteredList.isEmpty
                      // Fixed: AppEmptyStateWidget instead of plain Text
                      ? AppEmptyStateWidget(
                          icon: Icons.library_music_outlined,
                          title: 'No Results Found',
                          subtitle:
                              'Try searching for a different playlist or artist',
                          iconColor: AppColors.primary,
                        )
                      : (isGridView
                            ? _buildGridView(
                                filteredList,
                                key: const ValueKey('grid'),
                              )
                            : _buildListView(
                                filteredList,
                                key: const ValueKey('list'),
                              )),
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildListView(List playlists, {required Key key}) {
    return ListView.builder(
      key: key,
      itemCount: playlists.length,
      padding: const EdgeInsets.only(top: 10),
      itemBuilder: (context, index) {
        final item = playlists[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          leading: _buildImageTile(item, 64),
          title: Text(
            item.name,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Playlist • ${index + 5} songs',
            style: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List playlists, {required Key key}) {
    return GridView.builder(
      key: key,
      padding: const EdgeInsets.only(top: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.75,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final item = playlists[index];
        return Column(
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
        );
      },
    );
  }

  Widget _buildImageTile(dynamic item, double size) {
    final bool hasImage = item.imageUrl != null && item.imageUrl.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: !hasImage && item.gradientColors != null
            ? LinearGradient(colors: item.gradientColors!)
            : null,
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(item.imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasImage && item.name == 'Liked Songs'
          ? const Icon(Icons.favorite, color: AppColors.onSurface, size: 32)
          : null,
    );
  }
}

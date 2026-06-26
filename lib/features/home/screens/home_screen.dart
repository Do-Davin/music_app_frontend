import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/routing/app_router.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/playlist/models/playlist.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/providers/recently_played_provider.dart';
import 'package:music_app_frontend/features/song/providers/song_provider.dart';
import 'package:music_app_frontend/shared/widgets/app_error_widget.dart';
import 'package:music_app_frontend/shared/widgets/app_loading_widget.dart';
import 'package:music_app_frontend/features/song/providers/global_audio_player_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const Color _backgroundColor = AppColors.background;
  static const Color _accentColor = AppColors.primary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meState = ref.watch(meProvider);
    final username = meState.maybeWhen(
      data: (user) => _displayName(user.username, user.email),
      orElse: () => 'there',
    );

    final recentlyPlayedAsync = ref.watch(recentlyPlayedProvider);
    final mySongsAsync = ref.watch(mySongsProvider);
    final likedSongsAsync = ref.watch(likedSongsProvider);
    final myPlaylistsAsync = ref.watch(myPlaylistsProvider);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          color: _accentColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, username),
                const SizedBox(height: 32),

                // ── Continue Listening ─────────────────────────────────────
                ..._buildContinueListening(context, ref, recentlyPlayedAsync),

                // ── Recently Played ────────────────────────────────────────
                ..._buildAsyncSection<List<RecentlyPlayedEntry>>(
                  title: 'Recently Played',
                  asyncValue: recentlyPlayedAsync,
                  onRetry: () => ref.invalidate(recentlyPlayedProvider),
                  builder: (entries) => entries.isEmpty
                      ? const SizedBox.shrink()
                      : _buildRecentlyPlayedList(context, ref, entries),
                ),

                // ── My Uploads ─────────────────────────────────────────────
                ..._buildAsyncSection<List<Song>>(
                  title: 'My Uploads',
                  asyncValue: mySongsAsync,
                  onRetry: () => ref.invalidate(mySongsProvider),
                  builder: (songs) => songs.isEmpty
                      ? const SizedBox.shrink()
                      : _buildSongList(context, ref, songs, 'MY UPLOADS'),
                ),

                // ── Liked Songs ────────────────────────────────────────────
                ..._buildAsyncSection<List<Song>>(
                  title: 'Liked Songs',
                  asyncValue: likedSongsAsync,
                  onRetry: () => ref.invalidate(likedSongsProvider),
                  builder: (songs) => songs.isEmpty
                      ? const SizedBox.shrink()
                      : _buildSongList(context, ref, songs, 'LIKED SONGS'),
                ),

                // ── Your Playlists ─────────────────────────────────────────
                ..._buildPlaylistsSection(ref, myPlaylistsAsync),

                // ── Browse by Mood (local categories, no backend songs) ────
                _buildSectionTitle('Browse by Mood'),
                _buildMoodGrid(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Pull-to-refresh ──────────────────────────────────────────────────────

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.refresh(recentlyPlayedProvider.future),
      ref.refresh(mySongsProvider.future),
      ref.refresh(likedSongsProvider.future),
    ]);
    await ref.read(myPlaylistsProvider.notifier).refreshPlaylists();
  }

  // ── Generic async section builder ────────────────────────────────────────

  List<Widget> _buildAsyncSection<T>({
    required String title,
    required AsyncValue<T> asyncValue,
    required VoidCallback onRetry,
    required Widget Function(T value) builder,
  }) {
    return [
      _buildSectionTitle(title),
      asyncValue.when(
        loading: () => const SizedBox(
          height: 180,
          child: Center(child: AppLoadingWidget()),
        ),
        error: (e, _) => SizedBox(
          height: 120,
          child: AppErrorWidget(message: e.toString(), onRetry: onRetry),
        ),
        data: builder,
      ),
      const SizedBox(height: 32),
    ];
  }

  // ── Continue Listening section ────────────────────────────────────────────

  List<Widget> _buildContinueListening(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<RecentlyPlayedEntry>> asyncValue,
  ) {
    return asyncValue.when(
      loading: () => [],
      error: (_, _) => [],
      data: (entries) {
        if (entries.isEmpty) return [];
        return [
          _buildSectionTitle('Continue Listening'),
          _buildContinueListeningCard(context, ref, entries.first),
          const SizedBox(height: 32),
        ];
      },
    );
  }

  Widget _buildContinueListeningCard(
    BuildContext context,
    WidgetRef ref,
    RecentlyPlayedEntry entry,
  ) {
    final song = entry.song;
    return GestureDetector(
      onTap: () => _navigateToSong(context, ref, song, 'CONTINUE LISTENING'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _coverImage(song.coverImageUrl, 80),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 8),
                  Text(
                    _formatPlayedAt(entry.playedAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_filled, color: _accentColor, size: 40),
          ],
        ),
      ),
    );
  }

  String _formatPlayedAt(DateTime playedAt) {
    final diff = DateTime.now().difference(playedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${playedAt.day}/${playedAt.month}/${playedAt.year}';
  }

  // ── Recently played horizontal list ──────────────────────────────────────

  Widget _buildRecentlyPlayedList(
    BuildContext context,
    WidgetRef ref,
    List<RecentlyPlayedEntry> entries,
  ) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) =>
            _buildSongCard(context, ref, entries[index].song, 'RECENTLY PLAYED'),
      ),
    );
  }

  // ── Generic song horizontal list ─────────────────────────────────────────

  Widget _buildSongList(
    BuildContext context,
    WidgetRef ref,
    List<Song> songs,
    String category,
  ) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) =>
            _buildSongCard(context, ref, songs[index], category),
      ),
    );
  }

  Widget _buildSongCard(BuildContext context, WidgetRef ref, Song song, String category) {
    return GestureDetector(
      onTap: () => _navigateToSong(context, ref, song, category),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _coverImage(song.coverImageUrl, 140),
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
  }

  // ── Your Playlists section ────────────────────────────────────────────────

  List<Widget> _buildPlaylistsSection(
    WidgetRef ref,
    AsyncValue<List<Playlist>> playlistsAsync,
  ) {
    // Pre-check: hide section entirely when data is ready and empty
    final maybeEmpty = playlistsAsync.maybeWhen(
      data: (list) => list.where((p) => p.name != 'My Uploading').isEmpty,
      orElse: () => false,
    );
    if (maybeEmpty) return [];

    return [
      _buildSectionTitle('Your Playlists'),
      playlistsAsync.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: AppLoadingWidget()),
        ),
        error: (e, _) => SizedBox(
          height: 120,
          child: AppErrorWidget(
            message: e.toString(),
            onRetry: () =>
                ref.read(myPlaylistsProvider.notifier).loadPlaylists(),
          ),
        ),
        data: (playlists) {
          final visible = playlists
              .where((p) => p.name != 'My Uploading')
              .take(4)
              .toList();
          if (visible.isEmpty) return const SizedBox.shrink();
          return _buildPlaylistGrid(visible);
        },
      ),
      const SizedBox(height: 32),
    ];
  }

  Widget _buildPlaylistGrid(List<Playlist> playlists) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final hasCover =
            playlist.coverImageUrl != null &&
            playlist.coverImageUrl!.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.card,
            image: hasCover
                ? DecorationImage(
                    image: NetworkImage(playlist.coverImageUrl!),
                    fit: BoxFit.cover,
                    onError: (_, _) {},
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.4),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasCover)
                  const Center(
                    child: Icon(
                      Icons.queue_music,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Browse by Mood — static local categories ──────────────────────────────

  Widget _buildMoodGrid() {
    // Local gradients instead of random third-party images so the grid stays
    // visible even when offline / when an external host (e.g. picsum) errors.
    const moods = <_MoodTile>[
      _MoodTile(
        name: 'Focus',
        icon: Icons.center_focus_strong,
        gradient: [Color(0xFF1F3A5F), Color(0xFF4A6FA5)],
      ),
      _MoodTile(
        name: 'Chill',
        icon: Icons.nightlight_round,
        gradient: [Color(0xFF2C2C54), Color(0xFF6C5CE7)],
      ),
      _MoodTile(
        name: 'Workout',
        icon: Icons.fitness_center,
        gradient: [Color(0xFF7A1D1D), Color(0xFFE17055)],
      ),
      _MoodTile(
        name: 'Party',
        icon: Icons.celebration,
        gradient: [Color(0xFF6B0E5C), Color(0xFFE84393)],
      ),
    ];
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: moods.length,
      itemBuilder: (context, index) {
        final mood = moods[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: mood.gradient,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(mood.icon, color: Colors.white70, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, String username) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: 'Hello, ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: '$username!',
                  style: const TextStyle(color: _accentColor),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            const Icon(Icons.notifications_none, color: Colors.grey, size: 28),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Friends',
              onPressed: () => context.push(Routes.friends),
              icon: const Icon(
                Icons.person_add,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.settings_outlined, color: Colors.grey, size: 28),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: _accentColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _displayName(String username, String email) {
    final trimmed = username.trim();
    if (trimmed.isNotEmpty) return trimmed;
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return 'there';
    return trimmedEmail.split('@').first;
  }

  void _navigateToSong(BuildContext context, WidgetRef ref, Song song, String category) {
    ref.read(globalAudioPlayerProvider.notifier).playSong(song);
  }

  Widget _coverImage(String? url, double size) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _coverFallback(size),
      );
    }
    return _coverFallback(size);
  }

  Widget _coverFallback(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surface,
      child: const Icon(Icons.music_note, color: Colors.white24),
    );
  }
}

class _MoodTile {
  const _MoodTile({
    required this.name,
    required this.icon,
    required this.gradient,
  });

  final String name;
  final IconData icon;
  final List<Color> gradient;
}

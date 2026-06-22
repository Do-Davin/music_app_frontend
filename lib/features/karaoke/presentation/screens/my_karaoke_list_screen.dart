import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import '../controllers/karaoke_controller.dart';
import '../../data/models/karaoke_song.dart';
import '../widgets/karaoke_options_sheet.dart';
import 'player_screen.dart';
import 'lyric_editor_screen.dart';

class MyKaraokeListScreen extends StatefulWidget {
  const MyKaraokeListScreen({super.key});

  @override
  State<MyKaraokeListScreen> createState() => _MyKaraokeListScreenState();
}

class _MyKaraokeListScreenState extends State<MyKaraokeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Karaoke Space', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<KaraokeController>(
        builder: (context, controller, _) {
          final filteredSongs = controller.songs.where((song) {
            final titleMatch = song.title.toLowerCase().contains(_searchQuery.toLowerCase());
            final artistMatch = (song.artist ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
            return titleMatch || artistMatch;
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search in your karaoke space...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white70),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              // List of Songs
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : filteredSongs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mic_off_rounded, size: 64, color: Colors.grey[700]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No matching songs found'
                                      : 'Your space is empty\nGo convert some songs!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredSongs.length,
                            itemBuilder: (context, index) {
                              final song = filteredSongs[index];
                              final hasLyrics = song.lyrics.isNotEmpty;
                              return Card(
                                color: const Color(0xFF1E1E1E),
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: song.source == SongSource.youtube
                                          ? Colors.red.withValues(alpha: 0.15)
                                          : AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      song.source == SongSource.youtube
                                          ? Icons.play_circle_filled
                                          : Icons.music_note,
                                      color: song.source == SongSource.youtube
                                          ? Colors.red
                                          : AppColors.primary,
                                    ),
                                  ),
                                  title: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          song.title,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      rp.Consumer(
                                        builder: (context, ref, _) {
                                          final me = ref.watch(meProvider).valueOrNull;
                                          final isOwner = me != null && song.userId == me.id;
                                          final badgeText = isOwner
                                              ? (song.isPublic ? 'Yours • Public' : 'Yours • Private')
                                              : (song.isPublic ? 'Public' : 'Private');
                                          final badgeColor = isOwner
                                              ? (song.isPublic ? AppColors.primary : Colors.orangeAccent)
                                              : (song.isPublic ? Colors.blue : Colors.grey);

                                          return Container(
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
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    song.artist ?? 'Unknown Artist',
                                    style: const TextStyle(color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: rp.Consumer(
                                    builder: (context, ref, _) {
                                      return IconButton(
                                        icon: const Icon(Icons.more_vert, color: Colors.white70),
                                        onPressed: () {
                                          showKaraokeOptionsSheet(
                                            context: context,
                                            ref: ref,
                                            song: song,
                                            controller: controller,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    if (hasLyrics) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PlayerScreen(song: song, controller: controller),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LyricEditorScreen(song: song, controller: controller),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

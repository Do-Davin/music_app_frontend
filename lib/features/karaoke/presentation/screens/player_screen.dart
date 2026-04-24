import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../data/models/karaoke_song.dart';
import '../controllers/karaoke_controller.dart';
import '../widgets/lyric_line.dart';

class PlayerScreen extends StatelessWidget {
  final KaraokeSong song;
  final KaraokeController controller;

  const PlayerScreen({super.key, required this.song, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Start playing when screen builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.currentSong?.id != song.id) {
        controller.playSong(song);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Column(
              children: [
                _buildHeader(context),

                // Media player section
                if (song.source == SongSource.youtube &&
                    controller.youtubeController != null)
                  _buildYoutubePlayer()
                else if (song.source == SongSource.local)
                  _buildLocalPlayerIndicator(),

                const SizedBox(height: 16),

                // Lyrics display - NOW WITH CENTERED SCROLLING
                Expanded(child: _buildLyrics()),

                // Controls
                _buildControls(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Don't stop playback, just go back
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.currentSong?.title ?? song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (controller.currentSong?.artist != null)
                  Text(
                    controller.currentSong!.artist!,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYoutubePlayer() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: controller.youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: const Color(0xFF7C4DFF),
          onReady: () {},
        ),
      ),
    );
  }

  Widget _buildLocalPlayerIndicator() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1E1E1E),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 48, color: Color(0xFF7C4DFF)),
            const SizedBox(height: 8),
            Text(
              controller.currentSong?.title ?? 'Playing...',
              style: const TextStyle(color: Colors.white),
            ),
            if (controller.isPlaying)
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyrics() {
    final lyrics = controller.currentSong?.lyrics ?? song.lyrics;

    if (lyrics.isEmpty) {
      return Center(
        child: Text(
          'No lyrics available',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _LyricScroller(controller: controller, lyrics: lyrics),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar for local audio
          if (controller.audioPlayer != null)
            StreamBuilder<Duration>(
              stream: controller.audioPlayer!.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration =
                    controller.audioPlayer!.duration ?? Duration.zero;

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                        activeTrackColor: const Color(0xFF7C4DFF),
                        inactiveTrackColor: Colors.grey[800],
                        thumbColor: const Color(0xFF7C4DFF),
                        overlayColor: const Color(
                          0xFF7C4DFF,
                        ).withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        min: 0,
                        max: duration.inMilliseconds.toDouble(),
                        value: position.inMilliseconds
                            .clamp(0, duration.inMilliseconds)
                            .toDouble(),
                        onChanged: (value) => controller.seek(
                          Duration(milliseconds: value.toInt()),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(position),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            _formatTime(duration),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

          const SizedBox(height: 8),

          // Play/Pause button
          GestureDetector(
            onTap: controller.togglePlay,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C4DFF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                controller.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ============================================
// NEW: Dedicated lyric scroller with centering
// ============================================
class _LyricScroller extends StatefulWidget {
  final KaraokeController controller;
  final List<dynamic> lyrics;

  const _LyricScroller({required this.controller, required this.lyrics});

  @override
  State<_LyricScroller> createState() => _LyricScrollerState();
}

class _LyricScrollerState extends State<_LyricScroller> {
  final ScrollController _scrollController = ScrollController();
  final double _itemHeight = 56.0;

  @override
  void initState() {
    super.initState();
    // Listen to ValueNotifier for line changes
    widget.controller.currentLineNotifier.addListener(_onLineChanged);
  }

  void _onLineChanged() {
    final index = widget.controller.currentLineNotifier.value;
    _scrollToActiveLine(index);
  }

  void _scrollToActiveLine(int index) {
    if (!_scrollController.hasClients) return;

    final viewportHeight = _scrollController.position.viewportDimension;
    final centerOffset = (viewportHeight / 2) - (_itemHeight / 2);
    final targetOffset = (index * _itemHeight) - centerOffset;

    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    debugPrint(
      '📜 PlayerScreen scrolling to line $index, offset: $clampedOffset',
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;
        final padding = (viewportHeight / 2) - (_itemHeight / 2);

        return ValueListenableBuilder<int>(
          valueListenable: widget.controller.currentLineNotifier,
          builder: (context, currentLine, _) {
            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: padding),
              itemCount: widget.lyrics.length,
              itemBuilder: (context, index) {
                final isActive = index == currentLine;
                final distance = (index - currentLine).abs();
                final opacity = isActive
                    ? 1.0
                    : (1.0 - (distance * 0.35)).clamp(0.15, 0.5);

                return Opacity(
                  opacity: opacity,
                  child: LyricLine(
                    text: widget.lyrics[index].text,
                    isActive: isActive,
                    height: _itemHeight,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    widget.controller.currentLineNotifier.removeListener(_onLineChanged);
    _scrollController.dispose();
    super.dispose();
  }
}

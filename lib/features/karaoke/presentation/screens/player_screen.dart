import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../data/models/karaoke_song.dart';
import '../../data/models/lrc_line.dart';
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

                // Lyrics display - active line always centered
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
            onPressed: () => Navigator.pop(context),
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
            ValueListenableBuilder<bool>(
              valueListenable: controller.isPlayingNotifier,
              builder: (context, isPlaying, _) {
                return isPlaying
                    ? Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C4DFF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                    : const SizedBox.shrink();
              },
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

          // Play/Pause button — uses ValueListenableBuilder to avoid stale state
          ValueListenableBuilder<bool>(
            valueListenable: controller.isPlayingNotifier,
            builder: (context, isPlaying, _) {
              return GestureDetector(
                onTap: controller.togglePlay,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
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
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              );
            },
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
// Lyric scroller: active line always centered
// ============================================
class _LyricScroller extends StatefulWidget {
  final KaraokeController controller;
  final List<LrcLine> lyrics;

  const _LyricScroller({required this.controller, required this.lyrics});

  @override
  State<_LyricScroller> createState() => _LyricScrollerState();
}

class _LyricScrollerState extends State<_LyricScroller> {
  final ScrollController _scrollController = ScrollController();

  // Active line height is bigger (26px font, height factor 1.4 → ~36px) + padding
  // We fix a stable item height for scroll math:
  static const double _inactiveHeight = 52.0;
  static const double _activeHeight = 72.0;

  // Cache heights so we can compute exact offsets
  late List<double> _itemHeights;
  double _viewportHeight = 0;

  @override
  void initState() {
    super.initState();
    _rebuildHeights(0);
    widget.controller.currentLineNotifier.addListener(_onLineChanged);

    // Schedule initial scroll to center first lyric after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLine = widget.controller.currentLineNotifier.value;
      _scrollToActiveLine(currentLine);
    });
  }

  void _rebuildHeights(int activeLine) {
    _itemHeights = List.generate(
      widget.lyrics.length,
      (i) => i == activeLine ? _activeHeight : _inactiveHeight,
    );
  }

  void _onLineChanged() {
    final index = widget.controller.currentLineNotifier.value;
    _rebuildHeights(index);
    _scrollToActiveLine(index);
  }

  /// Compute the scroll offset so that the center of item [index] aligns
  /// with the vertical center of the viewport.
  void _scrollToActiveLine(int index) {
    if (!_scrollController.hasClients || _viewportHeight == 0) return;

    // Sum heights of all items before [index]
    double offsetToTop = 0;
    for (int i = 0; i < index; i++) {
      offsetToTop += _itemHeights[i];
    }

    // Center of this item
    final itemCenter = offsetToTop + _itemHeights[index] / 2;

    // We want itemCenter to be at viewportCenter. The list has topPadding =
    // viewportHeight/2 - activeHeight/2 so the very first item starts centered.
    // The raw scroll offset = itemCenter - viewportHeight/2
    final targetOffset = itemCenter - _viewportHeight / 2;

    final clamped = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportHeight = constraints.maxHeight;

        // Top padding = half viewport so first item starts centered.
        // Bottom padding mirrors so last item can also be centered.
        final halfViewport = _viewportHeight / 2;
        final verticalPadding = math.max(0.0, halfViewport - _activeHeight / 2);

        return ValueListenableBuilder<int>(
          valueListenable: widget.controller.currentLineNotifier,
          builder: (context, currentLine, _) {
            _rebuildHeights(currentLine);

            return ListView.builder(
              controller: _scrollController,
              // top padding = half viewport - half of the FIRST item's height
              // so item 0 starts centered
              padding: EdgeInsets.only(
                top: verticalPadding,
                bottom: verticalPadding,
              ),
              itemCount: widget.lyrics.length,
              itemBuilder: (context, index) {
                final isActive = index == currentLine;
                final distance = (index - currentLine).abs();
                // Lines far away fade more
                final opacity = isActive
                    ? 1.0
                    : (1.0 - (distance * 0.25)).clamp(0.1, 0.55);

                return SizedBox(
                  height: _itemHeights[index],
                  child: Opacity(
                    opacity: opacity,
                    child: LyricLine(
                      text: widget.lyrics[index].text,
                      isActive: isActive,
                      height: _itemHeights[index],
                    ),
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

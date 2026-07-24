import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/providers/global_audio_player_provider.dart';
import 'package:music_app_frontend/features/song/screens/song_player_screen.dart' show SongPlayerScreen;

class SlidingPlayerPanel extends ConsumerStatefulWidget {
  final Widget body;
  final String currentPath;
  final double navHeight;
  final Song currentSong;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final bool isMaximized;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;

  const SlidingPlayerPanel({
    super.key,
    required this.body,
    required this.currentPath,
    required this.navHeight,
    required this.currentSong,
    required this.isPlaying,
    required this.isLoading,
    required this.position,
    required this.duration,
    required this.isMaximized,
    required this.onMinimize,
    required this.onMaximize,
  });

  @override
  ConsumerState<SlidingPlayerPanel> createState() => _SlidingPlayerPanelState();
}

class _SlidingPlayerPanelState extends ConsumerState<SlidingPlayerPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  double _dragStartY = 0;
  double _panelHeightStart = 0;

  static const double miniPlayerHeight = 120.0;
  static const double miniPlayerWidth = 300.0;
  static const double _albumArtSize = 80.0;
  bool _isMuted = false;

  bool _isPositionInitialized = false;
  double _right = 16.0;
  double _bottom = 16.0;

  double _lerp(double start, double end, double t) => start + (end - start) * t;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.isMaximized) {
      _ac.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant SlidingPlayerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMaximized != oldWidget.isMaximized) {
      if (widget.isMaximized) {
        _ac.fling(velocity: 1.0);
      } else {
        _ac.fling(velocity: -1.0);
      }
    }
    if (widget.navHeight != oldWidget.navHeight) {
      _bottom += (widget.navHeight - oldWidget.navHeight);
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
    _panelHeightStart = _ac.value;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details, double totalHeight) {
    final dragDelta = _dragStartY - details.globalPosition.dy;
    final normalizedDelta = dragDelta / totalHeight;
    _ac.value = (_panelHeightStart + normalizedDelta).clamp(0.0, 1.0);
  }

  void _handleVerticalDragEnd(DragEndDetails details, double totalHeight) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -500) {
      widget.onMaximize();
      _ac.fling(velocity: 1.0);
    } else if (velocity > 500) {
      widget.onMinimize();
      _ac.fling(velocity: -1.0);
    } else if (_ac.value > 0.5) {
      widget.onMaximize();
      _ac.fling(velocity: 1.0);
    } else {
      widget.onMinimize();
      _ac.fling(velocity: -1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final totalHeight = size.height;
    
    // Total space at the bottom when minimized
    final double minimizedBottom = widget.navHeight;

    if (!_isPositionInitialized) {
      _right = 16.0;
      _bottom = minimizedBottom + 16.0;
      _isPositionInitialized = true;
    } else {
      // Clamp to ensure it doesn't get pushed off-screen due to screen size changes
      _right = _right.clamp(16.0, screenWidth - miniPlayerWidth - 16.0);
      _bottom = _bottom.clamp(16.0 + minimizedBottom, totalHeight - miniPlayerHeight - 16.0);
    }

    debugPrint('🎵 SlidingPlayerPanel: _bottom=$_bottom, navHeight=$minimizedBottom');

    return PopScope(
      canPop: !widget.isMaximized,
      onPopInvokedWithResult: (didPop, result) {
        if (widget.isMaximized) {
          widget.onMinimize();
        }
      },
      child: Stack(
        children: [
          // 1. MAIN BODY: no extra padding needed since mini player is a floating popup
          widget.body,
          
          // 2. SLIDING PANEL (Mini Player & Full Screen Player combined)
          AnimatedBuilder(
            animation: _ac,
            builder: (context, child) {
              final panelVal = _ac.value;
              
              // Calculate positioning
              final currentLeft = _lerp(screenWidth - miniPlayerWidth - _right, 0.0, panelVal);
              final currentRight = _lerp(_right, 0.0, panelVal);
              final currentBottom = _lerp(_bottom, 0.0, panelVal);
              final currentHeight = _lerp(miniPlayerHeight, totalHeight, panelVal);

              // For the mini player, we need extra left space for the protruding circle
              final artOverhang = panelVal < 0.5 ? (_albumArtSize / 2) * (1.0 - panelVal * 2) : 0.0;

              return Positioned(
                left: currentLeft - artOverhang,
                right: currentRight,
                bottom: currentBottom,
                height: currentHeight,
                child: GestureDetector(
                  onVerticalDragStart: panelVal > 0.1 ? _handleVerticalDragStart : null,
                  onVerticalDragUpdate: panelVal > 0.1 ? (details) => _handleVerticalDragUpdate(details, totalHeight) : null,
                  onVerticalDragEnd: panelVal > 0.1 ? (details) => _handleVerticalDragEnd(details, totalHeight) : null,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Always-mounted full-screen player (hidden at opacity 0 when minimized)
                      // This keeps the YoutubePlayer widget alive so audio plays immediately
                      Positioned.fill(
                        child: Opacity(
                          opacity: panelVal >= 0.5 ? ((panelVal - 0.05) * 1.05).clamp(0.0, 1.0) : 0.0,
                          child: IgnorePointer(
                            ignoring: panelVal < 0.9,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.all(
                                  Radius.circular((1.0 - panelVal) * 20.0),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.all(
                                  Radius.circular((1.0 - panelVal) * 20.0),
                                ),
                                child: SongPlayerScreen(
                                  key: ValueKey('player_${widget.currentSong.id}'),
                                  song: widget.currentSong,
                                  category: 'Queue',
                                  isEmbedMode: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Mini player view (visible only when panelVal < 0.5)
                      if (panelVal < 0.5) ...[
                        // Card body (shifted right for the protruding circle)
                        Positioned(
                          left: artOverhang,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: IgnorePointer(
                                ignoring: panelVal > 0.1,
                                child: _buildMiniPlayer(miniPlayerHeight, screenWidth, totalHeight),
                              ),
                            ),
                          ),
                        ),
                        // Circular album art protruding from left
                        Positioned(
                          left: 0,
                          top: (miniPlayerHeight - _albumArtSize) / 2,
                          child: GestureDetector(
                            onTap: widget.onMaximize,
                            child: Container(
                              width: _albumArtSize,
                              height: _albumArtSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.6),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                                image: (widget.currentSong.coverImageUrl != null &&
                                        widget.currentSong.coverImageUrl!.isNotEmpty)
                                    ? DecorationImage(
                                        image: NetworkImage(widget.currentSong.coverImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: AppColors.card,
                              ),
                              child: (widget.currentSong.coverImageUrl == null ||
                                      widget.currentSong.coverImageUrl!.isEmpty)
                                  ? const Icon(Icons.music_note, color: AppColors.primary, size: 32)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(double height, double screenWidth, double totalHeight) {
    // Progress fraction
    final totalMs = widget.duration.inMilliseconds;
    final posMs = widget.position.inMilliseconds;
    final progress = totalMs > 0 ? (posMs / totalMs).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        setState(() {
          _right = (_right - details.delta.dx).clamp(16.0, screenWidth - miniPlayerWidth - 16.0);
          _bottom = (_bottom - details.delta.dy).clamp(16.0 + widget.navHeight, totalHeight - miniPlayerHeight - 16.0);
        });
      },
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          height: height,
          child: Padding(
            // Leave left space for the protruding circle
            padding: EdgeInsets.only(left: _albumArtSize / 2 + 10, right: 12, top: 10, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: Title/Artist + Mute + Close ──
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onMaximize,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.currentSong.title,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              widget.currentSong.artist,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.hint,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Mute button
                    GestureDetector(
                      onTap: () {
                        setState(() { _isMuted = !_isMuted; });
                        final notifier = ref.read(globalAudioPlayerProvider.notifier);
                        notifier.setMuted(_isMuted);
                      },
                      child: Icon(
                        _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Close button
                    GestureDetector(
                      onTap: () {
                        ref.read(globalAudioPlayerProvider.notifier).clear();
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // ── Row 2: Progress bar (only visible when we have duration) ──
                if (totalMs > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 3,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 3),
                const Spacer(),
                // ── Row 3: Centered playback controls ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => ref.read(globalAudioPlayerProvider.notifier).previous(),
                      child: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () => ref.read(globalAudioPlayerProvider.notifier).togglePlay(),
                      child: Icon(
                        widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () => ref.read(globalAudioPlayerProvider.notifier).next(),
                      child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 26),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

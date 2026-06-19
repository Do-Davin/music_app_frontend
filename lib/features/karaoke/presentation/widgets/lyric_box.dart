import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/karaoke_controller.dart';
import 'lyric_line.dart';

class LyricBox extends StatelessWidget {
  final void Function(int lineIndex, int wordIndex)? onWordLongPress;

  const LyricBox({super.key, this.onWordLongPress});

  @override
  Widget build(BuildContext context) {
    return Consumer<KaraokeController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return _buildLoadingState();
        }

        if (!controller.hasActivePlayer || controller.currentSong == null) {
          return _buildEmptyState();
        }

        return _buildLyricDisplay(controller);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF7C4DFF), strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note_outlined, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'Select a song to play',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricDisplay(KaraokeController controller) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _LyricList(
          controller: controller,
          onWordLongPress: onWordLongPress,
        ),
      ),
    );
  }
}

class _LyricList extends StatefulWidget {
  final KaraokeController controller;
  final void Function(int lineIndex, int wordIndex)? onWordLongPress;

  const _LyricList({required this.controller, this.onWordLongPress});

  @override
  State<_LyricList> createState() => _LyricListState();
}

class _LyricListState extends State<_LyricList> {
  final ScrollController _scrollController = ScrollController();

  /// Stores measured heights of rendered lyric items.
  final Map<int, double> _measuredHeights = {};

  double _viewportHeight = 0;
  double _availableWidth = 0;

  @override
  void initState() {
    super.initState();
    // Listen to ValueNotifier instead of Stream
    widget.controller.currentLineNotifier.addListener(_onLineChanged);
  }

  /// Estimate the height of a lyric item based on text length.
  double _estimateHeight(int index) {
    if (_measuredHeights.containsKey(index)) {
      return _measuredHeights[index]!;
    }

    final lyrics = widget.controller.currentSong?.lyrics ?? [];
    if (index >= lyrics.length) return 50.0;

    final text = lyrics[index].text;
    final currentLine = widget.controller.currentLineNotifier.value;
    final isActive = index == currentLine;
    final fontSize = isActive ? 26.0 : 18.0;
    final verticalPad = isActive ? 28.0 : 16.0;
    final horizontalPad = 32.0;

    if (_availableWidth <= 0) {
      return isActive ? 80.0 : 50.0;
    }

    final charWidth = fontSize * 0.55;
    final usableWidth = _availableWidth - horizontalPad;
    final textWidth = text.length * charWidth;
    final numLines = (textWidth / usableWidth).ceil().clamp(1, 5);

    return (numLines * fontSize * 1.4) + verticalPad;
  }

  void _onItemMeasured(int index, double height) {
    if ((_measuredHeights[index] ?? 0) != height) {
      _measuredHeights[index] = height;
    }
  }

  void _onLineChanged() {
    final index = widget.controller.currentLineNotifier.value;
    debugPrint('📜 ValueNotifier changed to line: $index');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveLine(index);
    });
  }

  void _scrollToActiveLine(int index) {
    if (!_scrollController.hasClients) {
      debugPrint('❌ ScrollController has no clients yet');
      return;
    }

    if (_viewportHeight == 0) return;

    double offsetToTop = 0;
    for (int i = 0; i < index; i++) {
      offsetToTop += _estimateHeight(i);
    }

    final activeItemHeight = _estimateHeight(index);
    final itemCenter = offsetToTop + activeItemHeight / 2;
    final targetOffset = itemCenter - _viewportHeight / 2;

    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    debugPrint('📜 Scrolling to index $index, offset: $clampedOffset');

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.controller.currentSong?.lyrics ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportHeight = constraints.maxHeight;
        _availableWidth = constraints.maxWidth;

        final halfViewport = _viewportHeight / 2;

        // Use ValueListenableBuilder for both line index and position
        return ValueListenableBuilder<int>(
          valueListenable: widget.controller.currentLineNotifier,
          builder: (context, currentLine, _) {
            return ValueListenableBuilder<Duration>(
              valueListenable: widget.controller.positionNotifier,
              builder: (context, currentPosition, _) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    top: halfViewport,
                    bottom: halfViewport,
                  ),
                  itemCount: lyrics.length,
                  itemBuilder: (context, index) {
                    final isActive = index == currentLine;
                    final distance = (index - currentLine).abs();
                    final opacity = isActive
                        ? 1.0
                        : (1.0 - (distance * 0.3)).clamp(0.1, 0.5);

                    return _LyricBoxItemWrapper(
                      index: index,
                      onMeasured: _onItemMeasured,
                      child: Opacity(
                        opacity: opacity,
                        child: LyricLine(
                          text: lyrics[index].text,
                          isActive: isActive,
                          words: lyrics[index].words,
                          currentPosition: currentPosition,
                          onWordLongPress: (wordIdx) =>
                              widget.onWordLongPress?.call(index, wordIdx),
                        ),
                      ),
                    );
                  },
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

/// Wrapper that measures its child's rendered height and reports it back.
class _LyricBoxItemWrapper extends StatefulWidget {
  final int index;
  final void Function(int index, double height) onMeasured;
  final Widget child;

  const _LyricBoxItemWrapper({
    required this.index,
    required this.onMeasured,
    required this.child,
  });

  @override
  State<_LyricBoxItemWrapper> createState() => _LyricBoxItemWrapperState();
}

class _LyricBoxItemWrapperState extends State<_LyricBoxItemWrapper> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant _LyricBoxItemWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      widget.onMeasured(widget.index, renderBox.size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(key: _key, child: widget.child);
  }
}

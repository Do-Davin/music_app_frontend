import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
  final ItemScrollController _itemScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.currentLineNotifier.addListener(_onLineChanged);
  }

  void _onLineChanged() {
    final index = widget.controller.currentLineNotifier.value;
    debugPrint('📜 ValueNotifier changed to line: $index');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveLine(index);
    });
  }

  void _scrollToActiveLine(int index) {
    if (!_itemScrollController.isAttached) {
      debugPrint('❌ ItemScrollController is not attached yet');
      return;
    }

    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      alignment: 0.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.controller.currentSong?.lyrics ?? [];

    return ValueListenableBuilder<int>(
      valueListenable: widget.controller.currentLineNotifier,
      builder: (context, currentLine, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: widget.controller.positionNotifier,
          builder: (context, currentPosition, _) {
            return ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              padding: const EdgeInsets.symmetric(vertical: 100),
              itemCount: lyrics.length,
              itemBuilder: (context, index) {
                final isActive = index == currentLine;
                final distance = (index - currentLine).abs();
                final opacity = isActive
                    ? 1.0
                    : (1.0 - (distance * 0.3)).clamp(0.1, 0.5);

                return Opacity(
                  opacity: opacity,
                  child: LyricLine(
                    text: lyrics[index].text,
                    isActive: isActive,
                    words: lyrics[index].words,
                    currentPosition: currentPosition,
                    onWordLongPress: (wordIdx) =>
                        widget.onWordLongPress?.call(index, wordIdx),
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
    super.dispose();
  }
}

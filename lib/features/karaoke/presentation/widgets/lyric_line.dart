import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import '../../data/models/lrc_line.dart';

/// Displays a single lyric line.
///
/// When [words] is provided and the line [isActive], renders word-by-word
/// highlighting based on [currentPosition]. Words whose timestamp has passed
/// are highlighted (bright white + glow), while upcoming words remain dim.
///
/// When [words] is null, falls back to the original line-level highlighting.
///
/// Height is dynamic — it adapts to the text length, handling both single-line
/// and multi-line lyrics without overflow.
class LyricLine extends StatelessWidget {
  final String text;
  final bool isActive;
  final List<LrcWord>? words;
  final Duration currentPosition;
  final void Function(int wordIndex)? onWordLongPress;

  const LyricLine({
    super.key,
    required this.text,
    required this.isActive,
    this.words,
    this.currentPosition = Duration.zero,
    this.onWordLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final hasWords = words != null && words!.isNotEmpty && isActive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isActive ? 14 : 8,
      ),
      child: hasWords ? _buildWordByWord() : _buildSingleLine(),
    );
  }

  /// Standard line-level highlight (backward compatible).
  Widget _buildSingleLine() {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      style: TextStyle(
        fontSize: isActive ? 26 : 18,
        fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
        color: isActive
            ? Colors.white
            : Colors.white.withValues(alpha: 0.3),
        height: 1.4,
        letterSpacing: isActive ? 0.5 : 0,
        shadows: isActive
            ? [
                Shadow(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
                Shadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 48,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Word-by-word karaoke highlighting with sweep effect.
  Widget _buildWordByWord() {
    final spans = <InlineSpan>[];

    for (int i = 0; i < words!.length; i++) {
      final word = words![i];
      final wordStart = word.timestamp;

      // Determine end time: next word's start or line end
      Duration? wordEnd;
      if (i + 1 < words!.length) {
        wordEnd = words![i + 1].timestamp;
      }

      final bool isPast = currentPosition >= wordStart &&
          (wordEnd == null || currentPosition >= wordEnd);
      final bool isCurrent = currentPosition >= wordStart &&
          (wordEnd == null || currentPosition < wordEnd);

      Color wordColor;
      FontWeight wordWeight;
      List<Shadow>? wordShadows;

      if (isCurrent) {
        // Currently singing this word — bright highlight with glow
        wordColor = Colors.white;
        wordWeight = FontWeight.w900;
        wordShadows = [
          Shadow(
            color: AppColors.primary.withValues(alpha: 0.8),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
          Shadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 4),
          ),
        ];
      } else if (isPast) {
        // Already sung — slightly dimmer than current
        wordColor = Colors.white.withValues(alpha: 0.75);
        wordWeight = FontWeight.w700;
        wordShadows = [
          Shadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ];
      } else {
        // Upcoming — dim
        wordColor = Colors.white.withValues(alpha: 0.3);
        wordWeight = FontWeight.w400;
        wordShadows = null;
      }

      // Add space between words
      if (i > 0) {
        spans.add(const TextSpan(text: ' '));
      }

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onLongPress: () => onWordLongPress?.call(i),
          child: Text(
            word.text,
            style: TextStyle(
              color: wordColor,
              fontWeight: wordWeight,
              fontSize: 26,
              height: 1.4,
              letterSpacing: 0.5,
              shadows: wordShadows,
            ),
          ),
        ),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import '../../data/models/karaoke_song.dart';
import '../../data/models/lrc_line.dart';
import '../../domain/utils/word_timing_generator.dart';
import '../controllers/karaoke_controller.dart';
import '../widgets/lyric_line.dart';

class PlayerScreen extends StatefulWidget {
  final KaraokeSong song;
  final KaraokeController controller;

  const PlayerScreen({super.key, required this.song, required this.controller});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late List<LrcLine> _lyricsWithWords;
  bool _isAdvancedMode = false;
  String? _initError;

  @override
  void initState() {
    super.initState();

    try {
      if (widget.song.lyrics.isEmpty) {
        debugPrint('⚠️ Song has no lyrics');
        _lyricsWithWords = [];
      } else {
        // Auto-generate word timing from line timestamps
        _lyricsWithWords = WordTimingGenerator.generateWordTiming(
          widget.song.lyrics,
        );
        debugPrint(
          '✅ Generated word timing for ${_lyricsWithWords.length} lines',
        );
      }

      // Start playing when screen opens
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (widget.controller.currentSong?.id != widget.song.id) {
            widget.controller.playSong(
              widget.song.copyWith(lyrics: _lyricsWithWords),
            );
          }
        } catch (e) {
          debugPrint('❌ Error playing song: $e');
          setState(() => _initError = 'Error playing song: ${e.toString()}');
        }
      });
    } catch (e) {
      debugPrint('❌ Error initializing lyrics: $e');
      setState(() => _initError = 'Error loading lyrics: ${e.toString()}');
      _lyricsWithWords = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Song',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _initError!,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildHeader(context),

                // Media player section
                if (widget.song.source == SongSource.youtube)
                  _buildYoutubePlayer()
                else if (widget.song.source == SongSource.local)
                  _buildLocalPlayerIndicator(),

                const SizedBox(height: 8),

                // Lyrics display with word-by-word highlighting
                Expanded(child: _buildLyrics()),

                // Playback controls
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
                  widget.controller.currentSong?.title ?? widget.song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.controller.currentSong?.artist != null)
                  Text(
                    widget.controller.currentSong!.artist!,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Playback Settings',
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Playback Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),

                    // Offset section
                    const Text(
                      'Timing Offset',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Offset highlights lyrics slightly ahead of audio (default 0ms)',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<int>(
                      valueListenable: widget.controller.leadTimeMs,
                      builder: (context, currentMs, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current: ${currentMs}ms',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Wrap(
                              spacing: 6,
                              children: [0, 200, 300, 500, 800].map((ms) {
                                final isActive = currentMs == ms;
                                return GestureDetector(
                                  onTap: () {
                                    widget.controller.setLeadTime(ms);
                                    setModalState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.primary
                                          : const Color(0xFF2D2D2D),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${ms}ms',
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.black
                                            : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),

                    // Advanced editing mode section
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Advanced Word Editing Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Pause playback & long press any word to edit its start time',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                      value: _isAdvancedMode,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setModalState(() {
                          _isAdvancedMode = val;
                        });
                        setState(() {
                          _isAdvancedMode = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildYoutubePlayer() {
    if (widget.controller.youtubeController == null) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1E1E1E),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 12),
              Text('Loading video...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

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
          controller: widget.controller.youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.primary,
          onReady: () {
            debugPrint('✅ YouTube player ready');
          },
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
            const Icon(Icons.music_note, size: 48, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              widget.controller.currentSong?.title ?? 'Playing...',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyrics() {
    final lyrics = _lyricsWithWords;

    if (lyrics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lyrics, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'No lyrics available',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Add lyrics using the editor to sync with audio',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
        child: Stack(
          children: [
            _LyricScroller(
              controller: widget.controller,
              lyrics: lyrics,
              onWordLongPress: _isAdvancedMode ? _showWordEditDialog : null,
            ),
            if (_isAdvancedMode)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Editing Mode Active: Pause playback & long press any word to edit its start time.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slides unified progress bar
          _ProgressBar(controller: widget.controller),

          const SizedBox(height: 12),

          // Play/Pause button
          ValueListenableBuilder<bool>(
            valueListenable: widget.controller.isPlayingNotifier,
            builder: (context, isPlaying, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.fast_rewind_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    tooltip: 'Back 2s',
                    onPressed: () =>
                        widget.controller.skip(const Duration(seconds: -2)),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: widget.controller.togglePlay,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 40,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(
                      Icons.fast_forward_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    tooltip: 'Forward 2s',
                    onPressed: () =>
                        widget.controller.skip(const Duration(seconds: 2)),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showWordEditDialog(int lineIndex, int wordIndex) {
    if (widget.controller.isPlaying) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pause the song first to edit timing')),
      );
      return;
    }

    final line = _lyricsWithWords[lineIndex];
    final word = line.words![wordIndex];
    final textController = TextEditingController(text: word.text);
    Duration currentTimestamp = word.timestamp;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              'Edit Word Timing',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Word Text',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Timestamp: ${_formatTimeWithMs(currentTimestamp)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _adjustBtn(setDialogState, -100, '-100ms', () {
                      setDialogState(
                        () => currentTimestamp -= const Duration(
                          milliseconds: 100,
                        ),
                      );
                    }),
                    _adjustBtn(setDialogState, -10, '-10ms', () {
                      setDialogState(
                        () => currentTimestamp -= const Duration(
                          milliseconds: 10,
                        ),
                      );
                    }),
                    _adjustBtn(setDialogState, 10, '+10ms', () {
                      setDialogState(
                        () => currentTimestamp += const Duration(
                          milliseconds: 10,
                        ),
                      );
                    }),
                    _adjustBtn(setDialogState, 100, '+100ms', () {
                      setDialogState(
                        () => currentTimestamp += const Duration(
                          milliseconds: 100,
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateWord(
                    lineIndex,
                    wordIndex,
                    textController.text,
                    currentTimestamp,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Save Change',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _adjustBtn(
    StateSetter setDialogState,
    int ms,
    String label,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2A2A2A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(60, 36),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  void _updateWord(int lineIdx, int wordIdx, String newText, Duration newTime) {
    setState(() {
      final line = _lyricsWithWords[lineIdx];
      final words = List<LrcWord>.from(line.words!);
      words[wordIdx] = LrcWord(timestamp: newTime, text: newText);
      _lyricsWithWords[lineIdx] = line.copyWith(words: words);
    });

    widget.controller
        .saveLyrics(widget.song.id, _lyricsWithWords)
        .then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Word updated and saved!'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        })
        .catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving: $e'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
  }

  String _formatTimeWithMs(Duration d) {
    final min = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$min:$sec.$ms';
  }
}

// ============================================
// Unified Progress Bar for Audio and YouTube
// ============================================
class _ProgressBar extends StatefulWidget {
  final KaraokeController controller;
  const _ProgressBar({required this.controller});

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  Timer? _timer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      final ap = widget.controller.audioPlayer;
      final yt = widget.controller.youtubeController;
      Duration pos = Duration.zero;
      Duration dur = Duration.zero;

      if (ap != null) {
        pos = ap.position;
        dur = ap.duration ?? Duration.zero;
      } else if (yt != null) {
        pos = yt.value.position;
        dur = yt.value.metaData.duration;
      }

      if (pos != _position || dur != _duration) {
        setState(() {
          _position = pos;
          _duration = dur;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = _duration.inMilliseconds;
    final currentMs = _position.inMilliseconds;
    final sliderValue = totalMs > 0
        ? currentMs.clamp(0, totalMs).toDouble()
        : 0.0;
    final maxSlider = totalMs > 0 ? totalMs.toDouble() : 1.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.grey[800],
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            min: 0,
            max: maxSlider,
            value: sliderValue,
            onChanged: (value) {
              widget.controller.seek(Duration(milliseconds: value.toInt()));
              setState(() {
                _position = Duration(milliseconds: value.toInt());
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(_position),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                _formatTime(_duration),
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
  }

  String _formatTime(Duration d) {
    final min = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}

// ============================================
// Lyric scroller: active line always centered
// with word-by-word highlighting.
// ============================================
class _LyricScroller extends StatefulWidget {
  final KaraokeController controller;
  final List<LrcLine> lyrics;
  final void Function(int lineIndex, int wordIndex)? onWordLongPress;

  const _LyricScroller({
    required this.controller,
    required this.lyrics,
    this.onWordLongPress,
  });

  @override
  State<_LyricScroller> createState() => _LyricScrollerState();
}

class _LyricScrollerState extends State<_LyricScroller> {
  final ItemScrollController _itemScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.currentLineNotifier.addListener(_onLineChanged);
  }

  void _onLineChanged() {
    final index = widget.controller.currentLineNotifier.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveLine(index);
    });
  }

  void _scrollToActiveLine(int index) {
    if (!_itemScrollController.isAttached) {
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
    return ValueListenableBuilder<int>(
      valueListenable: widget.controller.currentLineNotifier,
      builder: (context, currentLine, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: widget.controller.positionNotifier,
          builder: (context, currentPosition, _) {
            return ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              padding: const EdgeInsets.symmetric(vertical: 100),
              itemCount: widget.lyrics.length,
              itemBuilder: (context, index) {
                final isActive = index == currentLine;
                final distance = (index - currentLine).abs();
                final opacity = isActive
                    ? 1.0
                    : (1.0 - (distance * 0.25)).clamp(0.1, 0.55);

                return Opacity(
                  opacity: opacity,
                  child: LyricLine(
                    text: widget.lyrics[index].text,
                    isActive: isActive,
                    words: widget.lyrics[index].words,
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

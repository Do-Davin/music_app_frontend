import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../data/models/karaoke_song.dart';
import '../../data/models/lrc_line.dart';
import '../../domain/utils/lrc_parser.dart';
import '../controllers/karaoke_controller.dart';
import 'player_screen.dart';

class LyricEditorScreen extends StatefulWidget {
  final KaraokeSong song;
  final KaraokeController controller;

  const LyricEditorScreen({
    super.key,
    required this.song,
    required this.controller,
  });

  @override
  State<LyricEditorScreen> createState() => _LyricEditorScreenState();
}

class _LyricEditorScreenState extends State<LyricEditorScreen> {
  final List<LyricLineInput> _lines = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.song.lyrics.isNotEmpty) {
      for (var lyric in widget.song.lyrics) {
        _lines.add(
          LyricLineInput(
            timeCtrl: TextEditingController(text: _formatTime(lyric.timestamp)),
            textCtrl: TextEditingController(text: lyric.text),
          ),
        );
      }
    } else {
      _addLine();
    }
  }

  String _formatTime(Duration duration) {
    final min = duration.inMinutes.toString().padLeft(2, '0');
    final sec = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final centi = ((duration.inMilliseconds % 1000) ~/ 10).toString().padLeft(
      2,
      '0',
    );
    return '$min:$sec.$centi';
  }

  void _addLine() {
    setState(() {
      _lines.add(
        LyricLineInput(
          timeCtrl: TextEditingController(text: '00:00.00'),
          textCtrl: TextEditingController(),
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  void _showPasteLyricsDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Paste All Lyrics',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste one lyric line per line.\nSupports LRC format with timestamps.',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              minLines: 5,
              maxLines: 10,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Line 1\nLine 2\nLine 3...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                _parseAndLoadLyrics(text);
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Load',
              style: TextStyle(color: Color(0xFF7C4DFF)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'lrc'],
      );

      if (result == null || result.files.isEmpty) return;

      String content;

      // Try to read from path first (Android/iOS)
      final filePath = result.files.single.path;
      if (filePath != null) {
        final file = File(filePath);
        content = await file.readAsString();
      } else {
        // Fallback to bytes (web)
        final bytes = result.files.single.bytes;
        if (bytes == null) return;
        content = String.fromCharCodes(bytes);
      }

      _parseAndLoadLyrics(content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing file: $e')),
        );
      }
    }
  }

  void _parseAndLoadLyrics(String content) {
    final lines = content.split('\n');
    final newLines = <LyricLineInput>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Skip LRC metadata
      if (RegExp(r'^\[(ti|ar|al|by|offset|re|ve):').hasMatch(line)) continue;

      // Try to parse as LRC (standard or enhanced)
      try {
        final parsed = LrcParser.parseLine(line);
        newLines.add(
          LyricLineInput(
            timeCtrl: TextEditingController(
                text: _formatTime(parsed.timestamp)),
            textCtrl: TextEditingController(text: parsed.text),
          ),
        );
      } catch (_) {
        // Plain text — add with default timestamp
        newLines.add(
          LyricLineInput(
            timeCtrl: TextEditingController(text: '00:00.00'),
            textCtrl: TextEditingController(text: line),
          ),
        );
      }
    }

    if (newLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid lyrics found')),
      );
      return;
    }

    setState(() {
      for (var line in _lines) {
        line.dispose();
      }
      _lines.clear();
      _lines.addAll(newLines);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded ${newLines.length} lyric lines')),
    );
  }

  Future<void> _saveLyrics() async {
    final lyrics = <LrcLine>[];

    for (final line in _lines) {
      final timeStr = line.timeCtrl.text.trim();
      final text = line.textCtrl.text.trim();

      if (text.isEmpty) continue;

      final parsed = _parseTime(timeStr);
      if (parsed != null) {
        lyrics.add(LrcLine(timestamp: parsed, text: text));
      }
    }

    if (lyrics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one lyric line')),
      );
      return;
    }

    // Use widget.controller instead of context.read
    await widget.controller.saveLyrics(widget.song.id, lyrics);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            song: widget.song.copyWith(lyrics: lyrics),
            controller: widget.controller,
          ),
        ),
      );
    }
  }

  Duration? _parseTime(String timeStr) {
    timeStr = timeStr.replaceAll('[', '').replaceAll(']', '');

    final parts = timeStr.split(':');
    if (parts.length != 2) return null;

    final min = int.tryParse(parts[0]);
    final secParts = parts[1].split('.');
    final sec = int.tryParse(secParts[0]);
    final centi = secParts.length > 1
        ? int.tryParse(secParts[1].padRight(2, '0'))
        : 0;

    if (min == null || sec == null || centi == null) return null;

    return Duration(minutes: min, seconds: sec, milliseconds: centi * 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Text(
          'Add Lyrics: ${widget.song.title}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: _saveLyrics,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Color(0xFF7C4DFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E1E1E),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enter timestamp [mm:ss.xx] and lyrics. Tap + to add more lines.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _lines.length,
              itemBuilder: (context, index) {
                return _buildLineInput(index);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _addLine,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Line'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A2A2A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showPasteLyricsDialog,
                        icon: const Icon(Icons.paste),
                        label: const Text('Paste All Lyrics'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A2A2A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _importFromFile,
                        icon: const Icon(Icons.file_open),
                        label: const Text('Import File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A2A2A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineInput(int index) {
    final line = _lines[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: TextField(
              controller: line.timeCtrl,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: '00:00.00',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: line.textCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter lyric text...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
          if (_lines.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => _removeLine(index),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }
}

class LyricLineInput {
  final TextEditingController timeCtrl;
  final TextEditingController textCtrl;

  LyricLineInput({required this.timeCtrl, required this.textCtrl});

  void dispose() {
    timeCtrl.dispose();
    textCtrl.dispose();
  }
}

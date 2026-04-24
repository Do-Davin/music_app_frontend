import 'package:flutter/material.dart';
import '../../data/models/karaoke_song.dart';
import '../../data/models/lrc_line.dart';
import '../controllers/karaoke_controller.dart';
import 'player_screen.dart';

class LyricEditorScreen extends StatefulWidget {
  final KaraokeSong song;
  final KaraokeController controller; // ← Add this

  const LyricEditorScreen({
    super.key,
    required this.song,
    required this.controller, // ← Required
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
    _addLine();
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
            controller: widget.controller, // Pass controller forward
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
            child: Row(
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

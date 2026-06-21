import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/lyric_chord_builder_screen.dart'
    show LyricChordItem, CanvasItemType;
import 'package:shared_preferences/shared_preferences.dart';

/// Read-only view of a song's lyric/chord canvas.
/// Loads the same per-song data saved by [LyricChordBuilderScreen]
/// but renders items as plain text (no boxes/borders) and does not
/// allow editing, moving, or resizing.
class ChordViewerScreen extends StatefulWidget {
  final String songId;
  final String? songTitle;

  const ChordViewerScreen({super.key, required this.songId, this.songTitle});

  @override
  State<ChordViewerScreen> createState() => _ChordViewerScreenState();
}

class _ChordViewerScreenState extends State<ChordViewerScreen> {
  static const _defaultCanvasWidth = 1200.0;
  static const _defaultCanvasHeight = 800.0;

  final List<LyricChordItem> _items = [];
  double _canvasWidth = _defaultCanvasWidth;
  double _canvasHeight = _defaultCanvasHeight;
  bool _loading = true;

  String get _storageKey => 'lyric_chord_builder_state_${widget.songId}';

  @override
  void initState() {
    super.initState();
    _loadCanvasState();
  }

  Future<void> _loadCanvasState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonText = prefs.getString(_storageKey);

    if (jsonText == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final data = jsonDecode(jsonText) as Map<String, dynamic>;
      final itemsData = (data['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final loadedItems = itemsData
          .map((json) => LyricChordItem.fromJson(json))
          .toList();

      setState(() {
        _items.clear();
        _items.addAll(loadedItems);
        _canvasWidth =
            (data['canvasWidth'] as num?)?.toDouble() ?? _defaultCanvasWidth;
        _canvasHeight =
            (data['canvasHeight'] as num?)?.toDouble() ?? _defaultCanvasHeight;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Text(
          widget.songTitle != null ? 'Chords: ${widget.songTitle}' : 'Chords',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? _buildEmptyState()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _canvasWidth,
                    height: _canvasHeight,
                    child: Stack(children: _items.map(_buildItem).toList()),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.grid_on_outlined, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No chords available for this song yet',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders an item as plain text only — no background, border, or
  /// container — positioned exactly where it was placed in the editor.
  Widget _buildItem(LyricChordItem item) {
    final isChord = item.type == CanvasItemType.chord;
    final color = isChord ? const Color(0xFF6FA8FF) : Colors.white;

    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: SizedBox(
        width: item.width,
        height: item.height,
        child: Align(
          alignment: isChord ? Alignment.center : Alignment.centerLeft,
          child: Text(
            item.text,
            style: TextStyle(
              color: color,
              fontSize: (isChord ? 24 : 16) * item.fontScale,
              fontWeight: isChord ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

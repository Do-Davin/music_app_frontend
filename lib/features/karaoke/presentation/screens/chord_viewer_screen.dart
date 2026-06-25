import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/lyric_chord_builder_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Read-only view of a song's lyric/chord canvas.
/// Loads the same per-song data saved by [LyricChordBuilderScreen]
/// but renders items as plain text with rich styling and does not
/// allow editing, moving, or resizing.
/// If [isOwner] is true, an edit button appears in the AppBar.
class ChordViewerScreen extends StatefulWidget {
  final String songId;
  final String? songTitle;
  final bool isOwner;

  const ChordViewerScreen({
    super.key,
    required this.songId,
    this.songTitle,
    this.isOwner = false,
  });

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
    setState(() => _loading = true);
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

  Future<void> _openEditor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LyricChordBuilderScreen(
          songId: widget.songId,
          songTitle: widget.songTitle,
        ),
      ),
    );
    // Reload canvas after returning from editor
    _loadCanvasState();
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
        actions: [
          if (widget.isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              tooltip: 'Edit Chords',
              onPressed: _openEditor,
            ),
        ],
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
            if (widget.isOwner) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openEditor,
                icon: const Icon(Icons.add),
                label: const Text('Create Chords'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Renders item with full rich styling — fontColor, fontSize,
  /// bold/italic/underline — exactly as positioned in the editor.
  Widget _buildItem(LyricChordItem item) {
    final isChord = item.type == CanvasItemType.chord;

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
              color: isChord ? const Color(0xFF6FA8FF) : item.fontColor,
              fontSize: (isChord ? 24 : item.fontSize) * item.fontScale,
              fontWeight: isChord
                  ? FontWeight.w700
                  : item.isBold
                  ? FontWeight.bold
                  : FontWeight.w500,
              fontStyle: item.isItalic ? FontStyle.italic : FontStyle.normal,
              decoration: item.isUnderline
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: item.fontColor,
            ),
          ),
        ),
      ),
    );
  }
}

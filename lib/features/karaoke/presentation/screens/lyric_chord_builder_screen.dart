import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';

enum CanvasItemType { lyric, chord }

enum ChordNotationStyle { abc, doReMi }

class LyricChordItem {
  final int id;
  final CanvasItemType type;
  final String text;
  final Offset position;
  final ChordNotationStyle notationStyle;
  final double width;
  final double height;
  final double fontScale;
  final double fontSize;
  final Color fontColor;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;

  LyricChordItem({
    required this.id,
    required this.type,
    required this.text,
    required this.position,
    required this.notationStyle,
    this.width = 200,
    this.height = 48,
    this.fontScale = 1.0,
    this.fontSize = 15.0,
    this.fontColor = Colors.white,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
  });

  LyricChordItem copyWith({
    Offset? position,
    String? text,
    double? width,
    double? height,
    double? fontScale,
    double? fontSize,
    Color? fontColor,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
  }) {
    return LyricChordItem(
      id: id,
      type: type,
      text: text ?? this.text,
      position: position ?? this.position,
      notationStyle: notationStyle,
      width: width ?? this.width,
      height: height ?? this.height,
      fontScale: fontScale ?? this.fontScale,
      fontSize: fontSize ?? this.fontSize,
      fontColor: fontColor ?? this.fontColor,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'text': text,
      'x': position.dx,
      'y': position.dy,
      'notationStyle': notationStyle.name,
      'width': width,
      'height': height,
      'fontScale': fontScale,
      'fontSize': fontSize,
      'fontColor': fontColor.value,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
    };
  }

  factory LyricChordItem.fromJson(Map<String, dynamic> json) {
    return LyricChordItem(
      id: json['id'] as int,
      type: CanvasItemType.values.byName(json['type'] as String),
      text: json['text'] as String,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      notationStyle: ChordNotationStyle.values.byName(
        json['notationStyle'] as String,
      ),
      width: (json['width'] as num?)?.toDouble() ?? 200,
      height: (json['height'] as num?)?.toDouble() ?? 48,
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 15.0,
      fontColor: json['fontColor'] != null
          ? Color(json['fontColor'] as int)
          : Colors.white,
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderline: json['isUnderline'] as bool? ?? false,
    );
  }
}

// ── Storage key helper ─────────────────────────────────────
String lyricChordStorageKey(String? songId) {
  if (songId != null && songId.isNotEmpty) {
    return 'lyric_chord_builder_state_$songId';
  }
  return 'lyric_chord_builder_state';
}

// ── Preset color swatches ──────────────────────────────────
class _ColorSwatch {
  final Color color;
  final String label;
  const _ColorSwatch({required this.color, required this.label});
}

const List<_ColorSwatch> _kColorSwatches = [
  _ColorSwatch(color: Colors.white, label: 'White'),
  _ColorSwatch(color: Color(0xFFFFEB3B), label: 'Yellow'),
  _ColorSwatch(color: Color(0xFFFF9800), label: 'Orange'),
  _ColorSwatch(color: Color(0xFFF44336), label: 'Red'),
  _ColorSwatch(color: Color(0xFF4CAF50), label: 'Green'),
  _ColorSwatch(color: Color(0xFF00BCD4), label: 'Cyan'),
  _ColorSwatch(color: Color(0xFF9C27B0), label: 'Purple'),
  _ColorSwatch(color: Color(0xFF2196F3), label: 'Blue'),
];

// ─────────────────────────────────────────────────────────────────────────────

class LyricChordBuilderScreen extends StatefulWidget {
  /// When provided, canvas state is saved/loaded per song.
  final String? songId;

  /// Optional song title shown in the AppBar.
  final String? songTitle;

  const LyricChordBuilderScreen({super.key, this.songId, this.songTitle});

  @override
  State<LyricChordBuilderScreen> createState() =>
      _LyricChordBuilderScreenState();
}

class _LyricChordBuilderScreenState extends State<LyricChordBuilderScreen> {
  static const _defaultCanvasWidth = 1200.0;
  static const _defaultCanvasHeight = 800.0;
  static const _maxHistory = 50;

  // ── Storage key is per-song when songId is given ───────────
  String get _storageKey => lyricChordStorageKey(widget.songId);

  final TextEditingController _lyricController = TextEditingController();
  final List<LyricChordItem> _items = [];
  final GlobalKey _canvasKey = GlobalKey();

  // Undo / redo stacks
  final List<List<LyricChordItem>> _undoStack = [];
  final List<List<LyricChordItem>> _redoStack = [];

  double _canvasWidth = _defaultCanvasWidth;
  double _canvasHeight = _defaultCanvasHeight;
  int _nextItemId = 0;
  bool _loading = true;
  ChordNotationStyle _chordNotationStyle = ChordNotationStyle.abc;

  // Resize state tracking
  int? _resizingItemId;
  Offset? _resizeStartPosition;
  double? _resizeStartWidth;
  double? _resizeStartHeight;

  static const _majorChords = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
  static const _minorChords = ['Am', 'Bm', 'Cm', 'Dm', 'Em', 'Fm', 'Gm'];
  static const _sharpFlatChords = [
    'C#',
    'D#',
    'F#',
    'G#',
    'A#',
    'Db',
    'Eb',
    'Gb',
    'Ab',
    'Bb',
  ];
  static const _seventhChords = ['A7', 'B7', 'C7', 'D7', 'E7', 'F7', 'G7'];

  @override
  void initState() {
    super.initState();
    _loadCanvasState();
  }

  @override
  void dispose() {
    _lyricController.dispose();
    super.dispose();
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
          .toList(growable: true);

      final maxId = loadedItems.isNotEmpty
          ? loadedItems.map((item) => item.id).reduce(max)
          : -1;

      setState(() {
        _items.clear();
        _items.addAll(loadedItems);
        _nextItemId = maxId + 1;
        _canvasWidth =
            (data['canvasWidth'] as num?)?.toDouble() ?? _defaultCanvasWidth;
        _canvasHeight =
            (data['canvasHeight'] as num?)?.toDouble() ?? _defaultCanvasHeight;
        final notationName = data['notationStyle'] as String?;
        if (notationName != null) {
          _chordNotationStyle = ChordNotationStyle.values.byName(notationName);
        }
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveCanvasState() async {
    final prefs = await SharedPreferences.getInstance();
    final state = {
      'canvasWidth': _canvasWidth,
      'canvasHeight': _canvasHeight,
      'notationStyle': _chordNotationStyle.name,
      'items': _items.map((item) => item.toJson()).toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(state));
  }

  /// Snapshot current _items before a mutation so it can be undone.
  void _pushHistory() {
    _undoStack.add(_items.map((e) => e.copyWith()).toList());
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_items.map((e) => e.copyWith()).toList());
    final previous = _undoStack.removeLast();
    setState(() {
      _items
        ..clear()
        ..addAll(previous);
    });
    _saveCanvasState();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_items.map((e) => e.copyWith()).toList());
    final next = _redoStack.removeLast();
    setState(() {
      _items
        ..clear()
        ..addAll(next);
    });
    _saveCanvasState();
  }

  void _addLyric(String text, {bool splitLines = false}) {
    if (text.trim().isEmpty) return;
    _pushHistory();

    if (splitLines) {
      final lines = text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.length > 1) {
        setState(() {
          for (var i = 0; i < lines.length; i++) {
            _items.add(
              LyricChordItem(
                id: _nextItemId++,
                type: CanvasItemType.lyric,
                text: lines[i],
                position: Offset(40, 40 + ((_items.length) * 42.0)),
                notationStyle: _chordNotationStyle,
                width: 320,
                height: 48,
                fontScale: 1.0,
              ),
            );
          }
          _lyricController.clear();
        });
        _saveCanvasState();
        return;
      }
    }

    final newItem = LyricChordItem(
      id: _nextItemId++,
      type: CanvasItemType.lyric,
      text: text.trim(),
      position: Offset(40, 40 + (_items.length * 42.0)),
      notationStyle: _chordNotationStyle,
      width: 320,
      height: 48,
      fontScale: 1.0,
    );
    setState(() {
      _items.add(newItem);
      _lyricController.clear();
    });
    _saveCanvasState();
  }

  void _addChord(String chord) {
    _pushHistory();
    final newItem = LyricChordItem(
      id: _nextItemId++,
      type: CanvasItemType.chord,
      text: chord,
      position: Offset(80, 80 + (_items.length * 42.0)),
      notationStyle: _chordNotationStyle,
      width: 56,
      height: 56,
      fontScale: 1.0,
    );
    setState(() {
      _items.add(newItem);
    });
    _saveCanvasState();
  }

  void _moveItem(int itemId, Offset delta) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index == -1) return;
      final current = _items[index];
      final newPosition = Offset(
        (current.position.dx + delta.dx).clamp(
          0.0,
          _canvasWidth - current.width,
        ),
        (current.position.dy + delta.dy).clamp(
          0.0,
          _canvasHeight - current.height,
        ),
      );
      _items[index] = current.copyWith(position: newPosition);
    });
    _saveCanvasState();
  }

  void _removeItem(int itemId) {
    _pushHistory();
    setState(() => _items.removeWhere((item) => item.id == itemId));
    _saveCanvasState();
  }

  void _startResize(int itemId, Offset startPosition) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index == -1) return;
    _pushHistory();
    setState(() {
      _resizingItemId = itemId;
      _resizeStartPosition = startPosition;
      _resizeStartWidth = _items[index].width;
      _resizeStartHeight = _items[index].height;
    });
  }

  void _updateResize(Offset currentPosition) {
    if (_resizingItemId == null ||
        _resizeStartPosition == null ||
        _resizeStartWidth == null ||
        _resizeStartHeight == null)
      return;

    final index = _items.indexWhere((item) => item.id == _resizingItemId);
    if (index == -1) return;

    final delta = currentPosition - _resizeStartPosition!;
    final newWidth = (_resizeStartWidth! + delta.dx).clamp(
      80.0,
      double.infinity,
    );
    final newHeight = (_resizeStartHeight! + delta.dy).clamp(
      40.0,
      double.infinity,
    );

    setState(() {
      _items[index] = _items[index].copyWith(
        width: newWidth,
        height: newHeight,
      );
    });
  }

  void _finishResize() {
    if (_resizingItemId != null) _saveCanvasState();
    setState(() {
      _resizingItemId = null;
      _resizeStartPosition = null;
      _resizeStartWidth = null;
      _resizeStartHeight = null;
    });
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text(
          'Clear Canvas',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Remove all lyrics and chords from the builder?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pushHistory();
              setState(() => _items.clear());
              _saveCanvasState();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLyricDialog() {
    _lyricController.clear();
    bool splitLines = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: const Color(0xFF161616),
          title: const Text('Add Lyric', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _lyricController,
                  minLines: 3,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter lyric text here...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: const Color(0xFF222222),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setDialog(() => splitLines = !splitLines),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          splitLines
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: splitLines
                              ? AppColors.primary
                              : Colors.white38,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Split each line into its own box',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () {
                final lyric = _lyricController.text.trim();
                if (lyric.isEmpty) return;
                Navigator.pop(context);
                _addLyric(lyric, splitLines: splitLines);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161616),
          title: const Text('Add Chord', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _chordSectionLabel('Major'),
                  _chordWrap(_majorChords),
                  const SizedBox(height: 16),
                  _chordSectionLabel('Minor'),
                  _chordWrap(_minorChords),
                  const SizedBox(height: 16),
                  _chordSectionLabel('Sharps & Flats'),
                  _chordWrap(_sharpFlatChords),
                  const SizedBox(height: 16),
                  _chordSectionLabel('7th Chords'),
                  _chordWrap(_seventhChords),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showEditChordDialog(LyricChordItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161616),
          title: Row(
            children: [
              const Text('Change Chord', style: TextStyle(color: Colors.white)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6FA8FF).withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6FA8FF), width: 1),
                ),
                child: Text(
                  item.text,
                  style: const TextStyle(
                    color: Color(0xFF6FA8FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _chordSectionLabel('Major'),
                  _chordEditWrap(_majorChords, item),
                  const SizedBox(height: 16),
                  _chordSectionLabel('Minor'),
                  _chordEditWrap(_minorChords, item),
                  const SizedBox(height: 16),
                  _chordSectionLabel('Sharps & Flats'),
                  _chordEditWrap(_sharpFlatChords, item),
                  const SizedBox(height: 16),
                  _chordSectionLabel('7th Chords'),
                  _chordEditWrap(_seventhChords, item),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _chordEditWrap(List<String> chords, LyricChordItem item) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chords.map((chord) {
        final isSelected = chord == item.text;
        return ActionChip(
          label: Text(
            chord,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          backgroundColor: isSelected
              ? const Color(0xFF6FA8FF)
              : const Color(0xFF2A2A2A),
          side: isSelected
              ? const BorderSide(color: Color(0xFF6FA8FF), width: 1.5)
              : BorderSide.none,
          onPressed: () {
            _pushHistory();
            final idx = _items.indexWhere((i) => i.id == item.id);
            if (idx != -1) {
              setState(() {
                _items[idx] = _items[idx].copyWith(text: chord);
              });
              _saveCanvasState();
            }
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  Widget _chordSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _chordWrap(List<String> chords) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chords.map((chord) {
        return ActionChip(
          label: Text(chord, style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF2A2A2A),
          onPressed: () {
            Navigator.pop(context);
            _addChord(chord);
          },
        );
      }).toList(),
    );
  }

  void _updateCanvasSize({double? width, double? height}) {
    setState(() {
      _canvasWidth = width ?? _canvasWidth;
      _canvasHeight = height ?? _canvasHeight;
    });
    _saveCanvasState();
  }

  void _showEditItemDialog(LyricChordItem item) {
    final ctrl = TextEditingController(text: item.text);
    double fontSize = item.fontSize;
    Color fontColor = item.fontColor;
    bool isBold = item.isBold;
    bool isItalic = item.isItalic;
    bool isUnderline = item.isUnderline;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          return Dialog(
            backgroundColor: const Color(0xFF161616),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 40,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Edit Lyric',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: ctrl,
                          minLines: 2,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (_) => setDialog(() {}),
                          decoration: InputDecoration(
                            hintText: 'Edit text',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            filled: true,
                            fillColor: const Color(0xFF222222),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'FONT SIZE',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222222),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (fontSize > 8)
                                    setDialog(() => fontSize -= 1);
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: fontSize <= 8
                                        ? const Color(0xFF333333)
                                        : const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    color: fontSize <= 8
                                        ? Colors.white24
                                        : Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${fontSize.toInt()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'pt',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (fontSize < 72)
                                    setDialog(() => fontSize += 1);
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: fontSize >= 72
                                        ? const Color(0xFF333333)
                                        : AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: fontSize >= 72
                                        ? Colors.white24
                                        : Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'FONT COLOR',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _kColorSwatches.map((swatch) {
                            final isSelected =
                                fontColor.value == swatch.color.value;
                            return GestureDetector(
                              onTap: () =>
                                  setDialog(() => fontColor = swatch.color),
                              child: Tooltip(
                                message: swatch.label,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: swatch.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.white24,
                                      width: isSelected ? 3 : 1.5,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.55),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'FONT STYLE',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _styleToggleBtn(
                              label: 'B',
                              active: isBold,
                              extraStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                              onTap: () => setDialog(() => isBold = !isBold),
                            ),
                            const SizedBox(width: 10),
                            _styleToggleBtn(
                              label: 'I',
                              active: isItalic,
                              extraStyle: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 16,
                              ),
                              onTap: () =>
                                  setDialog(() => isItalic = !isItalic),
                            ),
                            const SizedBox(width: 10),
                            _styleToggleBtn(
                              label: 'U',
                              active: isUnderline,
                              extraStyle: const TextStyle(
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                                fontSize: 16,
                              ),
                              onTap: () =>
                                  setDialog(() => isUnderline = !isUnderline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'PREVIEW',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            ctrl.text.trim().isEmpty
                                ? 'Preview text'
                                : ctrl.text,
                            style: TextStyle(
                              color: fontColor,
                              fontSize: fontSize,
                              fontWeight: isBold
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontStyle: isItalic
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              decoration: isUnderline
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              decorationColor: fontColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            _pushHistory();
                            final idx = _items.indexWhere(
                              (i) => i.id == item.id,
                            );
                            if (idx != -1) {
                              setState(() {
                                _items[idx] = _items[idx].copyWith(
                                  text: ctrl.text.trim(),
                                  fontSize: fontSize,
                                  fontColor: fontColor,
                                  isBold: isBold,
                                  isItalic: isItalic,
                                  isUnderline: isUnderline,
                                );
                              });
                              _saveCanvasState();
                            }
                            Navigator.pop(ctx);
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _styleToggleBtn({
    required String label,
    required bool active,
    required TextStyle extraStyle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.primary : Colors.white24,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: extraStyle.copyWith(
              color: active ? Colors.white : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): _redo,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: const Color(0xFF121212),
            title: Text(
              widget.songTitle != null
                  ? 'Chords: ${widget.songTitle}'
                  : 'Lyric & Chord Builder',
            ),
            actions: [
              IconButton(
                onPressed: _undo,
                icon: const Icon(Icons.undo),
                tooltip: 'Undo (Ctrl+Z)',
              ),
              IconButton(
                onPressed: _redo,
                icon: const Icon(Icons.redo),
                tooltip: 'Redo (Ctrl+Y)',
              ),
              IconButton(
                onPressed: _saveCanvasState,
                icon: const Icon(Icons.save),
                tooltip: 'Save canvas',
              ),
              IconButton(
                onPressed: _clearCanvas,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear canvas',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showAddLyricDialog,
                        icon: const Icon(Icons.text_fields),
                        label: const Text('Add Lyric'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showAddChordDialog,
                        icon: const Icon(Icons.music_note),
                        label: const Text('Add Chord'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A2A2A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSizeControl(
                        'Width',
                        _canvasWidth.toInt(),
                        onIncrease: () =>
                            _updateCanvasSize(width: _canvasWidth + 200),
                        onDecrease: () => _updateCanvasSize(
                          width: max(600, _canvasWidth - 200),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSizeControl(
                        'Height',
                        _canvasHeight.toInt(),
                        onIncrease: () =>
                            _updateCanvasSize(height: _canvasHeight + 200),
                        onDecrease: () => _updateCanvasSize(
                          height: max(500, _canvasHeight - 200),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Stack(
                        children: [
                          Container(
                            key: _canvasKey,
                            width: _canvasWidth,
                            height: _canvasHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: const Color(0xFF1B1B1B),
                              border: Border.all(color: Colors.white12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x59000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _CanvasGridPainter(),
                                  ),
                                ),
                                ..._items.map(_buildDraggableItem),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drag to reposition · Long press to remove · Pencil icon to edit font',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
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

  Widget _buildSizeControl(
    String label,
    int value, {
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove, color: Colors.white70),
          ),
          Text('$value', style: const TextStyle(color: Colors.white)),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableItem(LyricChordItem item) {
    final isChord = item.type == CanvasItemType.chord;
    final accent = isChord ? const Color(0xFF6FA8FF) : AppColors.primary;
    final background = isChord
        ? accent
        : const Color(0xFF2A2A2A).withAlpha(243);

    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) => _moveItem(item.id, details.delta),
        onLongPress: () => _removeItem(item.id),
        onTap: isChord ? () => _showEditChordDialog(item) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: item.width,
              height: item.height,
              child: Container(
                padding: isChord
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withAlpha(204), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x59000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: isChord
                    ? Center(
                        child: Text(
                          item.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24 * item.fontScale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.text_snippet, color: accent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.text,
                              style: TextStyle(
                                color: item.fontColor,
                                fontSize: item.fontSize * item.fontScale,
                                fontWeight: item.isBold
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontStyle: item.isItalic
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                decoration: item.isUnderline
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                                decorationColor: item.fontColor,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            // Edit button — top-right corner
            if (!isChord)
              Positioned(
                left: item.width - 8,
                top: -6,
                child: GestureDetector(
                  onTap: () => _showEditItemDialog(item),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            // Resize button — bottom-right corner
            if (!isChord)
              Positioned(
                left: item.width - 8,
                top: item.height - 8,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  child: GestureDetector(
                    onPanStart: (d) => _startResize(item.id, d.globalPosition),
                    onPanUpdate: (d) => _updateResize(d.globalPosition),
                    onPanEnd: (_) => _finishResize(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _resizingItemId == item.id
                            ? AppColors.primary
                            : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _resizingItemId == item.id
                              ? Colors.white
                              : Colors.white12,
                        ),
                      ),
                      child: Icon(
                        Icons.open_in_full,
                        size: 16,
                        color: _resizingItemId == item.id
                            ? Colors.white
                            : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CanvasGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
    const step = 80.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final borderPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Offset.zero & size, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

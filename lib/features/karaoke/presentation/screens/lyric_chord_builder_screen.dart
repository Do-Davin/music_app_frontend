import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CanvasItemType { lyric, chord }

enum ChordNotationStyle { abc, doReMi }

class LyricChordItem {
  final int id;
  final CanvasItemType type;
  final String text;
  final Offset position;
  final ChordNotationStyle notationStyle;

  LyricChordItem({
    required this.id,
    required this.type,
    required this.text,
    required this.position,
    required this.notationStyle,
  });

  LyricChordItem copyWith({Offset? position, String? text}) {
    return LyricChordItem(
      id: id,
      type: type,
      text: text ?? this.text,
      position: position ?? this.position,
      notationStyle: notationStyle,
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
    );
  }
}

class LyricChordBuilderScreen extends StatefulWidget {
  const LyricChordBuilderScreen({super.key});

  @override
  State<LyricChordBuilderScreen> createState() =>
      _LyricChordBuilderScreenState();
}

class _LyricChordBuilderScreenState extends State<LyricChordBuilderScreen> {
  static const _storageKey = 'lyric_chord_builder_state';
  static const _defaultCanvasWidth = 1200.0;
  static const _defaultCanvasHeight = 800.0;

  final TextEditingController _lyricController = TextEditingController();
  final List<LyricChordItem> _items = [];
  final GlobalKey _canvasKey = GlobalKey();

  double _canvasWidth = _defaultCanvasWidth;
  double _canvasHeight = _defaultCanvasHeight;
  int _nextItemId = 0;
  bool _loading = true;
  ChordNotationStyle _chordNotationStyle = ChordNotationStyle.abc;

  static const _abcChords = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
  static const _doReMiChords = ['Do', 'Re', 'Mi', 'Fa', 'So', 'La', 'Ti'];

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

  void _addLyric(String text) {
    if (text.trim().isEmpty) return;
    final newItem = LyricChordItem(
      id: _nextItemId++,
      type: CanvasItemType.lyric,
      text: text.trim(),
      position: Offset(40, 40 + (_items.length * 42.0)),
      notationStyle: _chordNotationStyle,
    );
    setState(() {
      _items.add(newItem);
      _lyricController.clear();
    });
    _saveCanvasState();
  }

  void _addChord(String chord) {
    final newItem = LyricChordItem(
      id: _nextItemId++,
      type: CanvasItemType.chord,
      text: chord,
      position: Offset(80, 80 + (_items.length * 42.0)),
      notationStyle: _chordNotationStyle,
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
        (current.position.dx + delta.dx).clamp(0.0, _canvasWidth - 100),
        (current.position.dy + delta.dy).clamp(0.0, _canvasHeight - 40),
      );
      _items[index] = current.copyWith(position: newPosition);
    });
    _saveCanvasState();
  }

  void _removeItem(int itemId) {
    setState(() {
      _items.removeWhere((item) => item.id == itemId);
    });
    _saveCanvasState();
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                setState(() {
                  _items.clear();
                });
                _saveCanvasState();
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Color(0xFF7C4DFF)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddLyricDialog() {
    _lyricController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161616),
          title: const Text('Add Lyric', style: TextStyle(color: Colors.white)),
          content: TextField(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
              ),
              onPressed: () {
                final lyric = _lyricController.text.trim();
                if (lyric.isEmpty) return;
                Navigator.pop(context);
                _addLyric(lyric);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddChordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final chords = _chordNotationStyle == ChordNotationStyle.abc
                ? _abcChords
                : _doReMiChords;
            return AlertDialog(
              backgroundColor: const Color(0xFF161616),
              title: const Text(
                'Add Chord',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text(
                            'ABC',
                            style: TextStyle(color: Colors.white),
                          ),
                          selected:
                              _chordNotationStyle == ChordNotationStyle.abc,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _chordNotationStyle = ChordNotationStyle.abc;
                              });
                            }
                          },
                          selectedColor: const Color(0xFF7C4DFF),
                          backgroundColor: const Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text(
                            'Do Re Mi',
                            style: TextStyle(color: Colors.white),
                          ),
                          selected:
                              _chordNotationStyle == ChordNotationStyle.doReMi,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _chordNotationStyle = ChordNotationStyle.doReMi;
                              });
                            }
                          },
                          selectedColor: const Color(0xFF7C4DFF),
                          backgroundColor: const Color(0xFF222222),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: chords.map((chord) {
                      return ActionChip(
                        label: Text(
                          chord,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF2A2A2A),
                        onPressed: () {
                          Navigator.pop(context);
                          _addChord(chord);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updateCanvasSize({double? width, double? height}) {
    setState(() {
      _canvasWidth = width ?? _canvasWidth;
      _canvasHeight = height ?? _canvasHeight;
    });
    _saveCanvasState();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Lyric & Chord Builder'),
        actions: [
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
                      backgroundColor: const Color(0xFF7C4DFF),
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
                    onDecrease: () =>
                        _updateCanvasSize(width: max(600, _canvasWidth - 200)),
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
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: Container(
                      key: _canvasKey,
                      width: _canvasWidth,
                      height: _canvasHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: const Color(0xFF1B1B1B),
                        border: Border.all(color: Colors.white12),
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0x59000000),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _CanvasGridPainter()),
                          ),
                          ..._items.map(_buildDraggableItem),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag items to reposition. Long press an item to remove it. Use Save to persist canvas state.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
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
    final background = isChord
        ? const Color(0xFF2A3A5B)
        : const Color(0xFF2A2A2A);
    final accent = isChord ? const Color(0xFF6FA8FF) : const Color(0xFF7C4DFF);
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) => _moveItem(item.id, details.delta),
        onLongPress: () => _removeItem(item.id),
        child: Container(
          constraints: const BoxConstraints(minWidth: 100, maxWidth: 240),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background.withAlpha(243),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withAlpha(204), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isChord ? Icons.music_note : Icons.text_snippet,
                    color: accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isChord ? 'Chord' : 'Lyric',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.text,
                style: TextStyle(
                  color: const Color(0xEBFFFFFF),
                  fontSize: isChord ? 18 : 15,
                  fontWeight: isChord ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (isChord)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _chordNotationStyle == ChordNotationStyle.abc
                        ? 'ABC notation'
                        : 'Do Re Mi notation',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
            ],
          ),
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

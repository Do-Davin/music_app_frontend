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
  final double width;
  final double height;
  final double fontScale;

  LyricChordItem({
    required this.id,
    required this.type,
    required this.text,
    required this.position,
    required this.notationStyle,
    this.width = 200,
    this.height = 48,
    this.fontScale = 1.0,
  });

  LyricChordItem copyWith({
    Offset? position,
    String? text,
    double? width,
    double? height,
    double? fontScale,
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

  // Resize state tracking
  int? _resizingItemId;
  Offset? _resizeStartPosition;
  double? _resizeStartFontScale;

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
    setState(() {
      _items.removeWhere((item) => item.id == itemId);
    });
    _saveCanvasState();
  }

  void _startResize(int itemId, Offset startPosition) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    setState(() {
      _resizingItemId = itemId;
      _resizeStartPosition = startPosition;
      _resizeStartFontScale = _items[index].fontScale;
    });
  }

  void _updateResize(Offset currentPosition) {
    if (_resizingItemId == null ||
        _resizeStartPosition == null ||
        _resizeStartFontScale == null) {
      return;
    }

    final index = _items.indexWhere((item) => item.id == _resizingItemId);
    if (index == -1) return;

    final current = _items[index];
    final delta = currentPosition - _resizeStartPosition!;

    // Change font scale based on vertical drag movement
    final fontScaleDelta = delta.dy * 0.005;
    final newFontScale = (_resizeStartFontScale! + fontScaleDelta).clamp(
      0.5,
      2.5,
    );

    // Scale width and height proportionally to font scale change
    final scaleRatio = newFontScale / _resizeStartFontScale!;
    final newWidth = (current.width * scaleRatio).clamp(80.0, 600.0);
    final newHeight = (current.height * scaleRatio).clamp(40.0, 300.0);

    setState(() {
      _items[index] = _items[index].copyWith(
        fontScale: newFontScale,
        width: newWidth,
        height: newHeight,
      );
    });
  }

  void _finishResize() {
    if (_resizingItemId != null) {
      _saveCanvasState();
    }
    setState(() {
      _resizingItemId = null;
      _resizeStartPosition = null;
      _resizeStartFontScale = null;
    });
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
    final accent = isChord ? const Color(0xFF6FA8FF) : const Color(0xFF7C4DFF);
    final background = isChord
        ? accent
        : const Color(0xFF2A2A2A).withAlpha(243);
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) => _moveItem(item.id, details.delta),
        onLongPress: () => _removeItem(item.id),
        child: SizedBox(
          width: item.width,
          height: item.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main pill / box
              Container(
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
                            fontSize: 16 * item.fontScale,
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
                                color: Colors.white,
                                fontSize: 15 * item.fontScale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              // Top-right edit button (pencil) - Only for lyrics
              if (!isChord)
                Positioned(
                  right: -6,
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

              // Bottom-right resize handle - Only for lyrics
              if (!isChord)
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      onPanStart: (details) =>
                          _startResize(item.id, details.globalPosition),
                      onPanUpdate: (details) =>
                          _updateResize(details.globalPosition),
                      onPanEnd: (_) => _finishResize(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _resizingItemId == item.id
                              ? const Color(0xFF7C4DFF)
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
      ),
    );
  }

  void _showEditItemDialog(LyricChordItem item) {
    final ctrl = TextEditingController(text: item.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Edit Item', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          minLines: 2,
          maxLines: 6,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Edit text',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFF222222),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final idx = _items.indexWhere((i) => i.id == item.id);
              if (idx != -1) {
                setState(() {
                  _items[idx] = _items[idx].copyWith(text: ctrl.text.trim());
                });
                _saveCanvasState();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResizeItemDialog(LyricChordItem item) {
    double tempW = item.width;
    double tempH = item.height;
    double tempScale = item.fontScale;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Resize Item',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'Width',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const Spacer(),
                        Text(
                          '${tempW.round()}px',
                          style: const TextStyle(
                            color: Color(0xFF7C4DFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      min: 80,
                      max: 600,
                      value: tempW,
                      activeColor: const Color(0xFF7C4DFF),
                      inactiveColor: Colors.white12,
                      onChanged: (v) => setStateSB(() => tempW = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Font Size',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const Spacer(),
                        Text(
                          '${(tempScale * 100).round()}%',
                          style: const TextStyle(
                            color: Color(0xFF7C4DFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      min: 0.7,
                      max: 1.6,
                      value: tempScale,
                      activeColor: const Color(0xFF7C4DFF),
                      inactiveColor: Colors.white12,
                      onChanged: (v) => setStateSB(() => tempScale = v),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final idx = _items.indexWhere(
                              (i) => i.id == item.id,
                            );
                            if (idx != -1) {
                              setState(() {
                                _items[idx] = _items[idx].copyWith(
                                  width: tempW,
                                  height: tempH,
                                  fontScale: tempScale,
                                );
                              });
                              _saveCanvasState();
                            }
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C4DFF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
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

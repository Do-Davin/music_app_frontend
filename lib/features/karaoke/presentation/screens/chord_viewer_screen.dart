import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/lyric_chord_builder_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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
  VoidCallback? _builderUndo;
  VoidCallback? _builderRedo;

  static const _defaultCanvasWidth = 1200.0;
  static const _defaultCanvasHeight = 800.0;

  final List<LyricChordItem> _items = [];
  double _canvasWidth = _defaultCanvasWidth;
  double _canvasHeight = _defaultCanvasHeight;
  bool _loading = true;
  bool _isEditMode = false;

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

  void _onToggleMode(bool editMode) {
    if (!editMode && _isEditMode) {
      // Switching from edit → view: reload latest saved state
      _loadCanvasState();
    }
    setState(() => _isEditMode = editMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Text(
          widget.songTitle != null ? 'Chords: ${widget.songTitle}' : 'Chords',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (widget.isOwner)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildToggle(),
            ),
        ],
      ),
      // IndexedStack keeps both widgets alive so edit state is preserved
      // when toggling back and forth
      body: widget.isOwner
          ? CallbackShortcuts(
              bindings: {
                const SingleActivator(
                  LogicalKeyboardKey.keyZ,
                  control: true,
                ): () =>
                    _builderUndo?.call(),
                const SingleActivator(
                  LogicalKeyboardKey.keyY,
                  control: true,
                ): () =>
                    _builderRedo?.call(),
                const SingleActivator(
                  LogicalKeyboardKey.keyZ,
                  control: true,
                  shift: true,
                ): () =>
                    _builderRedo?.call(),
              },
              child: Focus(
                autofocus: true,
                child: IndexedStack(
                  index: _isEditMode ? 1 : 0,
                  children: [
                    _buildViewBody(),
                    LyricChordBuilderScreen(
                      key: ValueKey(widget.songId),
                      songId: widget.songId,
                      songTitle: widget.songTitle,
                      embeddedMode: true,
                      onActionsReady: (undo, redo) {
                        _builderUndo = undo;
                        _builderRedo = redo;
                      },
                    ),
                  ],
                ),
              ),
            )
          : _buildViewBody(),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleSegment(
            label: 'View',
            icon: Icons.visibility_outlined,
            active: !_isEditMode,
            onTap: () => _onToggleMode(false),
          ),
          _toggleSegment(
            label: 'Edit',
            icon: Icons.edit_outlined,
            active: _isEditMode,
            onTap: () => _onToggleMode(true),
          ),
        ],
      ),
    );
  }

  Widget _toggleSegment({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? Colors.black : Colors.white54),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.black : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                ),
                ..._items.map(_buildItem),
              ],
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
                onPressed: () => _onToggleMode(true),
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

  Widget _buildItem(LyricChordItem item) {
    final isChord = item.type == CanvasItemType.chord;

    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: SizedBox(
        width: item.width,
        height: item.height,
        child: isChord
            ? Center(
                child: Text(
                  item.text,
                  style: TextStyle(
                    color: const Color(0xFF6FA8FF),
                    fontSize: 24 * item.fontScale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : Padding(
                // Match edit mode: 14px left pad + 18px icon + 8px gap = 40px
                padding: const EdgeInsets.only(
                  left: 40,
                  top: 10,
                  right: 14,
                  bottom: 10,
                ),
                child: Text(
                  item.text,
                  style: TextStyle(
                    color: item.fontColor,
                    fontSize: item.fontSize * item.fontScale,
                    fontWeight: item.isBold ? FontWeight.bold : FontWeight.w500,
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
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
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

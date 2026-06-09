import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/karaoke_song.dart';
import '../../data/models/lrc_line.dart';
import '../../domain/utils/lrc_parser.dart';
import '../controllers/karaoke_controller.dart';
import 'player_screen.dart';
import '../../../references/screens/reference_material_screen.dart';
import '../../../../features/song/providers/song_provider.dart';
import '../../../../features/playlist/providers/playlist_provider.dart';
import '../../../../core/constants/app_colors.dart';

class LyricEditorScreen extends StatefulWidget {
  final KaraokeSong song;
  final KaraokeController controller;
  final String? targetPlaylistId;
  final String? sourceSongId;
  final bool selectPlaylistAfterSave;

  const LyricEditorScreen({
    super.key,
    required this.song,
    required this.controller,
    this.targetPlaylistId,
    this.sourceSongId,
    this.selectPlaylistAfterSave = false,
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
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
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
              text: _formatTime(parsed.timestamp),
            ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No valid lyrics found')));
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

  Future<void> _saveLyrics(WidgetRef ref) async {
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

    try {
      await widget.controller.saveLyricsForSong(widget.song, lyrics);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save karaoke lyrics: $e')),
        );
      }
      return;
    }
    final serializedLyrics = lyrics
        .map((l) => '[${_formatTime(l.timestamp)}] ${l.text}')
        .join('\n');

    if (widget.sourceSongId != null &&
        _looksLikeObjectId(widget.sourceSongId!)) {
      try {
        await ref
            .read(songServiceProvider)
            .updateSongLyrics(
              songId: widget.sourceSongId!,
              lyrics: serializedLyrics,
            );
        ref.invalidate(songsProvider);
        ref.invalidate(songByIdProvider(widget.sourceSongId!));
      } catch (e) {
        debugPrint('Karaoke saved, but song lyrics update failed: $e');
      }
    }

    if (widget.targetPlaylistId != null || widget.selectPlaylistAfterSave) {
      if (!mounted) return;
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      try {
        final songService = ref.read(songServiceProvider);
        final playlistService = ref.read(playlistServiceProvider);

        final backendSong = await songService.createSong(
          title: widget.song.title,
          artist: widget.song.artist ?? 'Unknown Artist',
          source: widget.song.source == SongSource.youtube ? 'youtube' : 'mp3',
          sourcePath: widget.song.sourcePath,
          lyrics: serializedLyrics,
        );

        ref.invalidate(songsProvider);

        if (!mounted) return;
        // Close loading
        Navigator.pop(context);

        if (widget.targetPlaylistId != null) {
          final updatedPlaylist = await playlistService.addSongToPlaylist(
            widget.targetPlaylistId!,
            backendSong.id,
          );
          ref.read(myPlaylistsProvider.notifier).updatePlaylist(updatedPlaylist);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Song successfully added to playlist!'),
              ),
            );
            Navigator.pop(context); // Close LyricEditorScreen
          }
        } else if (widget.selectPlaylistAfterSave) {
          _showPlaylistSelectionSheet(backendSong.id, ref);
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save to playlist backend: $e')),
        );
      }
    } else {
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
  }

  bool _looksLikeObjectId(String value) =>
      RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value);

  void _showPlaylistSelectionSheet(String songId, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final playlistsAsync = ref.watch(myPlaylistsProvider);

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add to Playlist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.add, color: AppColors.primary),
                    title: const Text(
                      'Create New Playlist',
                      style: TextStyle(color: Colors.white),
                    ),
                    tileColor: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showCreateAndAddPlaylistDialog(songId, ref);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Existing Playlist',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: playlistsAsync.when(
                      data: (playlists) {
                        if (playlists.isEmpty) {
                          return const Center(
                            child: Text(
                              'No playlists available.\nCreate one above!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.playlist_play,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                playlist.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () async {
                                Navigator.pop(ctx);
                                await _addSongToExistingPlaylist(
                                  playlist.id,
                                  songId,
                                  ref,
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Error: $err',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx); // Close sheet
                        Navigator.pop(context); // Close LyricEditorScreen
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addSongToExistingPlaylist(
    String playlistId,
    String songId,
    WidgetRef ref,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final playlistService = ref.read(playlistServiceProvider);
      final updatedPlaylist = await playlistService.addSongToPlaylist(playlistId, songId);
      ref.read(myPlaylistsProvider.notifier).updatePlaylist(updatedPlaylist);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Song successfully added to playlist!'),
          ),
        );
        Navigator.pop(context); // Close LyricEditorScreen
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to playlist: $e')),
        );
      }
    }
  }

  void _showCreateAndAddPlaylistDialog(String songId, WidgetRef ref) {
    final TextEditingController nameController = TextEditingController();
    final screenContext = context;

    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'New Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist Name',
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogContext); // Close dialog

                if (!screenContext.mounted) return;
                // Show loading
                showDialog(
                  context: screenContext,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );

                try {
                  final playlistService = ref.read(playlistServiceProvider);
                  final newPlaylist = await playlistService.createPlaylist(
                    name,
                  );
                  final updatedPlaylist = await playlistService.addSongToPlaylist(
                    newPlaylist.id,
                    songId,
                  );
                  ref.read(myPlaylistsProvider.notifier).updatePlaylist(updatedPlaylist);

                  if (screenContext.mounted) {
                    Navigator.pop(screenContext); // Close loading dialog
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ Playlist "$name" created and song added!',
                        ),
                      ),
                    );
                    Navigator.pop(screenContext); // Close LyricEditorScreen
                  }
                } catch (e) {
                  if (screenContext.mounted) {
                    Navigator.pop(screenContext); // Close loading dialog
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      SnackBar(content: Text('Failed to create playlist: $e')),
                    );
                  }
                }
              }
            },
            child: const Text(
              'Create & Add',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
          Consumer(
            builder: (context, ref, _) {
              return TextButton(
                onPressed: () => _saveLyrics(ref),
                child: const Text(
                  'SAVE',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReferenceMaterialScreen(
                                songId: widget.song.id,
                              ),
                            ),
                          );
                        },
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

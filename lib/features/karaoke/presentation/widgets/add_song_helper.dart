import 'package:flutter/material.dart';
import '../controllers/karaoke_controller.dart';
import '../screens/lyric_editor_screen.dart';
import '../screens/player_screen.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';

class AddSongHelper {
  static void showAddSongDialog(
    BuildContext context,
    KaraokeController controller, {
    String? targetPlaylistId,
    bool selectPlaylistAfterSave = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Song',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.link, color: AppColors.primary),
                title: const Text('YouTube URL', style: TextStyle(color: Colors.white)),
                tileColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showYoutubeInput(
                    context,
                    controller,
                    targetPlaylistId: targetPlaylistId,
                    selectPlaylistAfterSave: selectPlaylistAfterSave,
                  );
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.folder, color: AppColors.primary),
                title: const Text('Local MP3 File', style: TextStyle(color: Colors.white)),
                tileColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLocalInput(
                    context,
                    controller,
                    targetPlaylistId: targetPlaylistId,
                    selectPlaylistAfterSave: selectPlaylistAfterSave,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showYoutubeInput(
    BuildContext context,
    KaraokeController controller, {
    String? targetPlaylistId,
    bool selectPlaylistAfterSave = false,
  }) {
    final urlCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'YouTube Song',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(urlCtrl, 'YouTube URL'),
            const SizedBox(height: 12),
            _buildTextField(titleCtrl, 'Song Title'),
            const SizedBox(height: 12),
            _buildTextField(artistCtrl, 'Artist (optional)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final localContext = context;
              final song = await controller.createSongFromYoutube(
                urlCtrl.text.trim(),
                titleCtrl.text.trim(),
                artistCtrl.text.trim().isEmpty ? null : artistCtrl.text.trim(),
              );
              // ignore: use_build_context_synchronously
              if (!localContext.mounted) return;
              Navigator.pop(localContext);
              if (song != null) {
                if (song.lyrics.isNotEmpty) {
                  ScaffoldMessenger.of(localContext).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Lyrics auto-fetched from YouTube!'),
                    ),
                  );
                  Navigator.push(
                    localContext,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(song: song, controller: controller),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(localContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'ℹ️ No captions found on this video. Please add lyrics manually.',
                      ),
                    ),
                  );
                  Navigator.push(
                    localContext,
                    MaterialPageRoute(
                      builder: (_) => LyricEditorScreen(
                        song: song,
                        controller: controller,
                        targetPlaylistId: targetPlaylistId,
                        selectPlaylistAfterSave: selectPlaylistAfterSave,
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Next: Add Lyrics'),
          ),
        ],
      ),
    );
  }

  static void _showLocalInput(
    BuildContext context,
    KaraokeController controller, {
    String? targetPlaylistId,
    bool selectPlaylistAfterSave = false,
  }) {
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Local MP3', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(titleCtrl, 'Song Title'),
            const SizedBox(height: 12),
            _buildTextField(artistCtrl, 'Artist (optional)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final localContext = context;
              final song = await controller.createSongFromLocal(
                titleCtrl.text.trim(),
                artistCtrl.text.trim().isEmpty ? null : artistCtrl.text.trim(),
              );
              // ignore: use_build_context_synchronously
              if (!localContext.mounted) return;
              Navigator.pop(localContext);
              if (song != null) {
                Navigator.push(
                  localContext,
                  MaterialPageRoute(
                    builder: (_) => LyricEditorScreen(
                      song: song,
                      controller: controller,
                      targetPlaylistId: targetPlaylistId,
                      selectPlaylistAfterSave: selectPlaylistAfterSave,
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Select File & Add Lyrics'),
          ),
        ],
      ),
    );
  }

  static Widget _buildTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

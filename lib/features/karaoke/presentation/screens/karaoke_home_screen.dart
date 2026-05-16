import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/karaoke_controller.dart';
import 'song_list_screen.dart';
import 'lyric_editor_screen.dart';
import 'lyric_chord_builder_screen.dart';
import 'player_screen.dart';

class KaraokeHomeScreen extends StatelessWidget {
  const KaraokeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KaraokeController()..loadSongs(),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          title: const Text('Karaoke', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Open Builder',
              icon: const Icon(Icons.create, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LyricChordBuilderScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: const SongListScreen(),
        floatingActionButton: Builder(
          // ← Add Builder here
          builder: (context) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context),
              backgroundColor: const Color(0xFF7C4DFF),
              icon: const Icon(Icons.add),
              label: const Text('Add Song'),
            );
          },
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = context.read<KaraokeController>();

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
              _buildOption(
                icon: Icons.link,
                label: 'YouTube URL',
                onTap: () {
                  Navigator.pop(ctx);
                  _showYoutubeInput(context, controller);
                },
              ),
              const SizedBox(height: 12),
              _buildOption(
                icon: Icons.folder,
                label: 'Local MP3 File',
                onTap: () {
                  Navigator.pop(ctx);
                  _showLocalInput(context, controller);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF7C4DFF)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      tileColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  void _showYoutubeInput(BuildContext context, KaraokeController controller) {
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
                      builder: (_) =>
                          PlayerScreen(song: song, controller: controller),
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
                        controller: controller, // ← Pass controller
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
            ),
            child: const Text('Next: Add Lyrics'),
          ),
        ],
      ),
    );
  }

  void _showLocalInput(BuildContext context, KaraokeController controller) {
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
                      controller: controller, // ← Pass controller
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
            ),
            child: const Text('Select File & Add Lyrics'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
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

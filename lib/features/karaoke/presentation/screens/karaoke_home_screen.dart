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
      ),
    );
  }
}

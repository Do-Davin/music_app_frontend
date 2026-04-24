import 'dart:async';
// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/karaoke_song.dart';
import '../../data/models/lrc_line.dart';
import '../../data/repositories/karaoke_repository.dart';

class KaraokeController extends ChangeNotifier {
  final _repository = KaraokeRepository();
  final _uuid = const Uuid();

  AudioPlayer? get audioPlayer => _audioPlayer;
  YoutubePlayerController? get youtubeController => _youtubeController;

  // Player instances
  AudioPlayer? _audioPlayer;
  YoutubePlayerController? _youtubeController;

  // Current song
  KaraokeSong? _currentSong;
  KaraokeSong? get currentSong => _currentSong;

  // Song list
  List<KaraokeSong> _songs = [];
  List<KaraokeSong> get songs => _songs;

  // States
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _currentLineIndex = 0;
  int get currentLineIndex => _currentLineIndex;

  bool get isPlaying =>
      _audioPlayer?.playing ?? _youtubeController?.value.isPlaying ?? false;

  bool get hasActivePlayer =>
      _audioPlayer != null || _youtubeController != null;

  Timer? _syncTimer;
  // Replace StreamController with ValueNotifier
  final ValueNotifier<int> currentLineNotifier = ValueNotifier<int>(0);

  // In _startSync(), instead of _activeLineController.add(newIndex):

  // ==================== SONG LIST ====================

  Future<void> loadSongs() async {
    _isLoading = true;
    notifyListeners();

    _songs = await _repository.getAllSongs();

    _isLoading = false;
    notifyListeners();
  }

  // ==================== ADD SONG FLOW ====================

  Future<KaraokeSong?> createSongFromYoutube(
    String url,
    String title,
    String? artist,
  ) async {
    try {
      final videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId == null) {
        _error = 'Invalid YouTube URL';
        notifyListeners();
        return null;
      }

      final song = KaraokeSong(
        id: _uuid.v4(),
        title: title,
        artist: artist,
        source: SongSource.youtube,
        sourcePath: videoId, // Store just the ID
        lyrics: [], // Empty initially - user adds later
      );

      await _repository.saveSong(song);
      await loadSongs();
      return song;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<KaraokeSong?> createSongFromLocal(String title, String? artist) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'flac'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final filePath = result.files.single.path;
      if (filePath == null) {
        _error = 'Could not access file';
        notifyListeners();
        return null;
      }

      final song = KaraokeSong(
        id: _uuid.v4(),
        title: title,
        artist: artist,
        source: SongSource.local,
        sourcePath: filePath,
        lyrics: [], // Empty initially
      );

      await _repository.saveSong(song);
      await loadSongs();
      return song;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ==================== SAVE LYRICS ====================

  Future<void> saveLyrics(String songId, List<LrcLine> lyrics) async {
    final song = _songs.firstWhere((s) => s.id == songId);
    final updated = KaraokeSong(
      id: song.id,
      title: song.title,
      artist: song.artist,
      source: song.source,
      sourcePath: song.sourcePath,
      lyrics: lyrics,
      duration: song.duration,
      createdAt: song.createdAt,
    );

    await _repository.saveSong(updated);
    await loadSongs();
  }

  // ==================== PLAYBACK ====================

  Future<void> playSong(KaraokeSong song) async {
    _currentSong = song;
    _currentLineIndex = 0;

    // Clean up previous player
    _disposePlayers();

    if (song.source == SongSource.youtube) {
      _initYoutubePlayer(song.sourcePath);
    } else {
      await _initAudioPlayer(song.sourcePath);
    }

    _startSync();
    notifyListeners();
  }

  void _initYoutubePlayer(String videoId) {
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: true,
        hideThumbnail: false,
      ),
    );
  }

  Future<void> _initAudioPlayer(String filePath) async {
    _audioPlayer = AudioPlayer();
    await _audioPlayer!.setFilePath(filePath);
    await _audioPlayer!.play();
  }

  void _startSync() {
    _syncTimer?.cancel();
    debugPrint('🎵 Starting sync with ${currentSong?.lyrics.length} lyrics');

    if (_currentSong == null || _currentSong!.lyrics.isEmpty) {
      debugPrint('❌ No lyrics to sync');
      return;
    }

    _syncTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      Duration? position;

      if (_audioPlayer != null) {
        position = _audioPlayer!.position;
      } else if (_youtubeController != null) {
        position = _youtubeController!.value.position;
      }

      if (position == null) {
        debugPrint('❌ No position available');
        return;
      }

      final newIndex = _findCurrentLineIndex(position);
      if (newIndex != _currentLineIndex) {
        debugPrint(
          '🎵 Line changed: $_currentLineIndex -> $newIndex at ${position.inSeconds}s',
        );
        _currentLineIndex = newIndex;
        currentLineNotifier.value = newIndex;
        notifyListeners();
      }
    });
  }

  int _findCurrentLineIndex(Duration position) {
    if (_currentSong == null) return 0;

    for (int i = _currentSong!.lyrics.length - 1; i >= 0; i--) {
      if (position >= _currentSong!.lyrics[i].timestamp) {
        return i;
      }
    }
    return 0;
  }

  void togglePlay() {
    if (_audioPlayer != null) {
      _audioPlayer!.playing ? _audioPlayer!.pause() : _audioPlayer!.play();
    } else if (_youtubeController != null) {
      _youtubeController!.value.isPlaying
          ? _youtubeController!.pause()
          : _youtubeController!.play();
    }
    notifyListeners();
  }

  void seek(Duration position) {
    _audioPlayer?.seek(position);
    _youtubeController?.seekTo(position);
  }

  void _disposePlayers() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _youtubeController?.dispose();
    _youtubeController = null;
    _syncTimer?.cancel();
  }

  Future<void> deleteSong(String id) async {
    if (_currentSong?.id == id) {
      _disposePlayers();
      _currentSong = null;
    }
    await _repository.deleteSong(id);
    await loadSongs();
  }

  @override
  void dispose() {
    _disposePlayers();
    currentLineNotifier.dispose();
    super.dispose();
  }
}

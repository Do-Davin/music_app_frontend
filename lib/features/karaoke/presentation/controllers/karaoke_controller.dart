import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
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
  final ValueNotifier<int> currentLineNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  /// Emits the current playback position (with lead-time offset applied).
  /// Used by LyricLine widgets for word-by-word highlight timing.
  final ValueNotifier<Duration> positionNotifier =
      ValueNotifier<Duration>(Duration.zero);

  /// Adjustable lead-time offset: lyrics highlight ahead of audio
  /// so singers can read ahead. Default 0ms, user can adjust.
  final ValueNotifier<int> leadTimeMs = ValueNotifier<int>(0);

  Duration get leadTimeOffset => Duration(milliseconds: leadTimeMs.value);

  void setLeadTime(int ms) {
    leadTimeMs.value = ms;
    notifyListeners();
  }

  // ==================== SONG LIST ====================

  Future<void> loadSongs() async {
    _isLoading = true;
    notifyListeners();

    _songs = await _repository.getAllSongs();

    _isLoading = false;
    notifyListeners();
  }

  // ==================== HELPER: VTT Caption Parser ====================

  List<LrcLine> _parseVTTCaptions(String vttContent) {
    final lyrics = <LrcLine>[];

    // VTT format:
    // 00:00:00.000 --> 00:00:05.000
    // Caption text here
    // (blank line)
    // 00:00:05.000 --> 00:00:10.000
    // Next caption

    final lines = vttContent.split('\n');
    Duration? currentTimestamp;

    for (var line in lines) {
      line = line.trim();

      // Skip WEBVTT header and NOTE lines
      if (line.isEmpty || line.startsWith('WEBVTT') || line.startsWith('NOTE')) {
        continue;
      }

      // Check if this is a timestamp line
      if (line.contains('-->')) {
        // Extract the start timestamp
        final parts = line.split('-->');
        if (parts.isNotEmpty) {
          currentTimestamp = _parseVTTTimestamp(parts[0].trim());
        }
      } else if (currentTimestamp != null && line.isNotEmpty) {
        // This is a caption line
        // Remove HTML tags if present
        var text = line.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (text.isNotEmpty) {
          lyrics.add(LrcLine(timestamp: currentTimestamp, text: text));
          currentTimestamp = null; // Reset for next caption
        }
      }
    }

    return lyrics;
  }

  Duration _parseVTTTimestamp(String timestamp) {
    // VTT format: HH:MM:SS.mmm
    // Example: 00:01:23.456
    try {
      final parts = timestamp.split(':');
      if (parts.length < 2) return Duration.zero;

      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);

      final secondParts = parts[2].split('.');
      final seconds = int.parse(secondParts[0]);
      final milliseconds =
          secondParts.length > 1 ? int.parse(secondParts[1].padRight(3, '0')) : 0;

      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    } catch (e) {
      debugPrint('❌ Failed to parse VTT timestamp: $timestamp - $e');
      return Duration.zero;
    }
  }

  // ==================== HELPER: Fetch Captions with Format Handling ====================

  Future<List<LrcLine>> _fetchCaptionsWithYoutubeDart(
    String videoId,
    yt_explode.ClosedCaptionTrackInfo trackInfo,
  ) async {
    try {
      final yt = yt_explode.YoutubeExplode();

      debugPrint('⏳ Fetching caption data for ${trackInfo.language.name}...');

      // Try to get the track - this may fail if format is not XML
      try {
        final track = await yt.videos.closedCaptions.get(trackInfo);
        debugPrint('📝 Got ${track.captions.length} captions');

        final lyrics = <LrcLine>[];
        for (var caption in track.captions) {
          if (caption.text.trim().isNotEmpty) {
            lyrics.add(LrcLine(timestamp: caption.offset, text: caption.text));
          }
        }

        if (lyrics.isNotEmpty) {
          debugPrint('✅ Successfully fetched ${lyrics.length} lyric lines');
          yt.close();
          return lyrics;
        }
      } catch (parseError) {
        debugPrint('⚠️ Caption parsing failed (format issue): $parseError');

        // Try to fetch raw data from the caption track URL
        debugPrint('💡 Attempting to fetch raw caption data...');
        try {
          final manifest = await yt.videos.closedCaptions.getManifest(videoId);
          if (manifest.tracks.isNotEmpty) {
            // Use the track URL as-is (VTT format - srv1)
            var trackUrl = trackInfo.url.toString();
            debugPrint('🔗 Caption track URL: $trackUrl');

            final capRes = await http.get(
              Uri.parse(trackUrl),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                'Referer': 'https://www.youtube.com/',
              },
            ).timeout(const Duration(seconds: 10));

            debugPrint('📊 Response status: ${capRes.statusCode}, length: ${capRes.body.length}');

            if (capRes.statusCode == 200 && capRes.body.isNotEmpty) {
              debugPrint('📊 Got ${capRes.body.length} bytes of VTT caption data');

              // Parse VTT format
              try {
                final lyrics = _parseVTTCaptions(capRes.body);
                if (lyrics.isNotEmpty) {
                  debugPrint('✅ Parsed VTT captions: ${lyrics.length} lines');
                  yt.close();
                  return lyrics;
                }
              } catch (e) {
                debugPrint('⚠️ VTT parsing failed: $e');
              }
            } else {
              debugPrint('⚠️ Empty response or error status');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Raw data fetch failed: $e');
        }
      }

      yt.close();
      return [];
    } catch (e) {
      debugPrint('❌ Caption fetch error: $e');
      return [];
    }
  }

  // ==================== HELPER: Manual Caption Fetching (Fallback) ====================

  Future<List<LrcLine>> _fetchCaptionsManually(String videoId) async {
    try {
      debugPrint('🔧 Attempting manual caption fetch for: $videoId');
      final videoPageUrl = 'https://www.youtube.com/watch?v=$videoId';

      final res = await http.get(
        Uri.parse(videoPageUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        debugPrint('❌ Failed to fetch YouTube page: ${res.statusCode}');
        return [];
      }

      final html = res.body;
      final regex = RegExp(r'ytInitialPlayerResponse\s*=\s*(\{.+?\});');
      final match = regex.firstMatch(html);

      if (match == null) {
        debugPrint('❌ Could not find ytInitialPlayerResponse in page');
        return [];
      }

      final jsonStr = match.group(1)!;
      final playerResponse = jsonDecode(jsonStr);

      final captionTracks = playerResponse['captions']?['playerCaptionsTracklistRenderer']
          ?['captionTracks'] as List?;
      if (captionTracks == null || captionTracks.isEmpty) {
        debugPrint('❌ No caption tracks found in player response');
        return [];
      }

      // Find English captions
      Map<String, dynamic>? selectedTrack;
      for (var track in captionTracks) {
        final trackLang = track['languageCode'] as String?;
        if (trackLang?.startsWith('en') ?? false) {
          selectedTrack = track;
          break;
        }
      }
      selectedTrack ??= captionTracks.first as Map<String, dynamic>?;

      if (selectedTrack == null) {
        debugPrint('❌ No valid caption track found');
        return [];
      }

      final baseUrl = selectedTrack['baseUrl'] as String?;
      if (baseUrl == null) {
        debugPrint('❌ No baseUrl found in caption track');
        return [];
      }

      final jsonUrl = Uri.parse(baseUrl).replace(queryParameters: {
        ...Uri.parse(baseUrl).queryParameters,
        'fmt': 'json3',
      });

      debugPrint('📥 Fetching captions from: $jsonUrl');
      final capRes = await http.get(
        jsonUrl,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
          'Accept': 'application/json',
          'Referer': 'https://www.youtube.com/',
          'Accept-Encoding': 'gzip, deflate',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📊 Caption response status: ${capRes.statusCode}');
      debugPrint('📊 Caption response length: ${capRes.body.length}');

      if (capRes.body.isEmpty) {
        debugPrint('⚠️ Caption response is empty');
        return [];
      }

      if (capRes.statusCode != 200) {
        debugPrint('❌ Failed to fetch captions: ${capRes.statusCode}');
        final preview = capRes.body.length > 200
          ? capRes.body.substring(0, 200)
          : capRes.body;
        debugPrint('📝 Response: $preview');
        return [];
      }

      final capData = jsonDecode(capRes.body);
      final events = capData['events'] as List?;
      if (events == null || events.isEmpty) {
        debugPrint('⚠️ No events found in caption data');
        return [];
      }

      final lyrics = <LrcLine>[];
      for (var event in events) {
        final startMs = event['tStartMs'] as String?;
        final segs = event['segs'] as List?;

        if (startMs == null || segs == null) continue;

        final timestamp =
            Duration(milliseconds: int.parse(startMs));
        final text = segs
            .map((seg) => seg['utf8'] as String? ?? '')
            .join('')
            .trim();

        if (text.isNotEmpty) {
          lyrics.add(LrcLine(timestamp: timestamp, text: text));
        }
      }

      debugPrint('✅ Manual fetch succeeded: ${lyrics.length} captions');
      return lyrics;
    } catch (e, stack) {
      debugPrint('❌ Manual caption fetch failed: $e');
      debugPrint('📍 Stack trace: $stack');
      return [];
    }
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

      List<LrcLine> fetchedLyrics = [];
      try {
        debugPrint('🎬 Attempting to fetch captions for video: $videoId');
        final yt = yt_explode.YoutubeExplode();
        final manifest = await yt.videos.closedCaptions.getManifest(videoId);

        debugPrint('📋 Found ${manifest.tracks.length} caption tracks');

        if (manifest.tracks.isNotEmpty) {
          yt_explode.ClosedCaptionTrackInfo? bestTrack;

          // Try to find Khmer captions first
          for (var track in manifest.tracks) {
            debugPrint('  - ${track.language.name} (${track.language.code})');
            if (track.language.code.toLowerCase().startsWith('km')) {
              bestTrack = track;
              break;
            }
          }

          // Fall back to English
          if (bestTrack == null) {
            for (var track in manifest.tracks) {
              if (track.language.code.toLowerCase().startsWith('en')) {
                bestTrack = track;
                break;
              }
            }
          }

          // Use first available
          bestTrack ??= manifest.tracks.first;

          debugPrint('✅ Selected track: ${bestTrack.language.name}');

          // Try to fetch captions using the wrapper
          fetchedLyrics = await _fetchCaptionsWithYoutubeDart(videoId, bestTrack);

          if (fetchedLyrics.isEmpty) {
            debugPrint('⚠️ YouTube caption API limitation: Auto-caption loading not available');
            _error =
                'YouTube captions cannot be auto-loaded on mobile. Please add lyrics manually using the editor below.';
          }
        } else {
          debugPrint('⚠️ No caption tracks available for this video');
          _error = 'No captions available for this video. Please add lyrics manually.';
        }
        yt.close();
      } catch (e) {
        debugPrint('❌ Failed to process captions: $e');
        _error = 'Could not load captions. Please add lyrics manually using the editor.';
      }

      final song = KaraokeSong(
        id: _uuid.v4(),
        title: title,
        artist: artist,
        source: SongSource.youtube,
        sourcePath: videoId, // Store just the ID
        lyrics: fetchedLyrics, // Pre-filled if captions exist
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
      final result = await FilePicker.pickFiles(
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

    isPlayingNotifier.value = true;
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

    _syncTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
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

      // Apply lead-time offset so lyrics appear slightly ahead of audio
      final adjustedPosition = position + leadTimeOffset;

      // Update position notifier for word-level sync
      positionNotifier.value = adjustedPosition;

      final newIndex = _findCurrentLineIndex(adjustedPosition);
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
      if (_audioPlayer!.playing) {
        _audioPlayer!.pause();
        isPlayingNotifier.value = false;
      } else {
        _audioPlayer!.play();
        isPlayingNotifier.value = true;
      }
    } else if (_youtubeController != null) {
      if (_youtubeController!.value.isPlaying) {
        _youtubeController!.pause();
        isPlayingNotifier.value = false;
      } else {
        _youtubeController!.play();
        isPlayingNotifier.value = true;
      }
    }
    notifyListeners();
  }

  void seek(Duration position) {
    _audioPlayer?.seek(position);
    _youtubeController?.seekTo(position);
  }

  void skip(Duration delta) {
    Duration current = Duration.zero;
    if (_audioPlayer != null) {
      current = _audioPlayer!.position;
    } else if (_youtubeController != null) {
      current = _youtubeController!.value.position;
    }

    final target = current + delta;
    seek(target.isNegative ? Duration.zero : target);
  }

  void _disposePlayers() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _youtubeController?.dispose();
    _youtubeController = null;
    _syncTimer?.cancel();
    isPlayingNotifier.value = false;
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
    isPlayingNotifier.dispose();
    positionNotifier.dispose();
    leadTimeMs.dispose();
    super.dispose();
  }
}

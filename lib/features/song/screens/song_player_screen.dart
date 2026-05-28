import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/services/song_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:music_app_frontend/features/karaoke/presentation/controllers/karaoke_controller.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/lyric_editor_screen.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/player_screen.dart';

class SongPlayerScreen extends StatefulWidget {
  final Song song;
  final String category;

  const SongPlayerScreen({
    super.key,
    required this.song,
    required this.category,
  });

  @override
  State<SongPlayerScreen> createState() => _SongPlayerScreenState();
}

class _SongPlayerScreenState extends State<SongPlayerScreen> {
  AudioPlayer? _audioPlayer;
  YoutubePlayerController? _youtubeController;
  bool _isPlaying = false;
  bool _isPreparingKaraoke = false;
  bool _lyricsReadyOverride = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  Song? _currentSong;

  void _loadLatestSongDetails() async {
    try {
      final freshSong = await SongService().fetchSongById(widget.song.id);
      if (mounted) {
        setState(() {
          _currentSong = freshSong;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch fresh song details in player: $e");
    }
  }

  void initState() {
    _currentSong = widget.song;
    _loadLatestSongDetails();
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    final url = _resolvePlaybackUrl(widget.song.audioUrl);
    if (url == null || url.isEmpty) {
      debugPrint("No playback URL found for song: ${widget.song.title}");
      _showPlaybackError('No audio source found for this song.');
      return;
    }

    if (widget.song.isYoutube) {
      _initYoutubePlayer(url);
    } else {
      _initAudioPlayer(url);
    }
  }

  void _initYoutubePlayer(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      debugPrint("Could not extract YouTube ID from URL: $url");
      _showPlaybackError('Unable to play this YouTube song.');
      return;
    }

    _youtubeController =
        YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            hideControls: true,
            disableDragSeek: true,
          ),
        )..addListener(() {
          if (!mounted) return;

          setState(() {
            _isPlaying = _youtubeController!.value.isPlaying;
            _position = _youtubeController!.value.position;
            _duration = _youtubeController!.metadata.duration;
          });
        });
  }

  void _initAudioPlayer(String url) async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer!.setUrl(url);
      await _audioPlayer!.play();
    } catch (e) {
      debugPrint("Error loading audio: $e");
      _showPlaybackError('Unable to play this song.');
    }

    _audioPlayer!.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _audioPlayer!.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _audioPlayer!.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    });
  }

  String? _resolvePlaybackUrl(String? rawUrl) {
    final value = rawUrl?.trim();
    if (value == null || value.isEmpty) return null;

    if (widget.song.isYoutube) return value;

    final uri = Uri.tryParse(value);
    if (uri == null) return value;
    if (uri.hasScheme) return value;

    final endpoint = Uri.tryParse(GraphQLConfig.httpEndpoint);
    if (endpoint == null || !endpoint.hasScheme || endpoint.host.isEmpty) {
      return value;
    }

    return endpoint.replace(path: value, query: '', fragment: '').toString();
  }

  void _showPlaybackError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (widget.song.isYoutube) {
      if (_isPlaying) {
        _youtubeController?.pause();
      } else {
        _youtubeController?.play();
      }
    } else {
      if (_isPlaying) {
        _audioPlayer?.pause();
      } else {
        _audioPlayer?.play();
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  bool get _hasLyrics =>
      _lyricsReadyOverride ||
      (_currentSong?.lyrics != null && _currentSong!.lyrics!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.mic,
              color: _hasLyrics ? const Color(0xFF7C4DFF) : Colors.grey,
              size: 28,
            ),
            tooltip: _hasLyrics ? 'Sing Karaoke' : 'Add lyrics first',
            onPressed: _hasLyrics
                ? () => _startKaraokeConversion(context, widget.song)
                : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildMedia(context),
              const SizedBox(height: 40),
              Text(
                _currentSong?.lyrics ?? "Enjoy the music!",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.song.artist,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: _hasLyrics ? 'Karaoke lyrics ready' : 'Set up lyrics',
                        icon: Icon(
                          Icons.lyrics,
                          color: _hasLyrics
                              ? Colors.grey.shade600
                              : const Color(0xFF7C4DFF),
                          size: 28,
                        ),
                        onPressed: _hasLyrics || _isPreparingKaraoke
                            ? null
                            : () => _startLyricSetup(context, widget.song),
                      ),
                      const SizedBox(height: 10),
                      const Icon(
                        Icons.favorite,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildProgressBar(),
              const SizedBox(height: 20),
              _buildPlayerControls(),
              const SizedBox(height: 30),
              _buildFeatureActions(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureActions() {
    final enabled = _hasLyrics && !_isPreparingKaraoke;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: ElevatedButton.icon(
          onPressed: enabled
              ? () => _startKaraokeConversion(context, widget.song)
              : null,
          icon: const Icon(Icons.mic, color: Colors.white, size: 20),
          label: const Text(
            'SING KARAOKE',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: const Color(0xFF2A2A2A),
            disabledForegroundColor: Colors.white38,
            backgroundColor: const Color(0xFF7C4DFF),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
            shadowColor: const Color(0xFF7C4DFF).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    final controller = _youtubeController;
    if (widget.song.isYoutube && controller != null) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: YoutubePlayer(
            controller: controller,
            showVideoProgressIndicator: false,
          ),
        ),
      );
    }

    return _buildAlbumArt(context);
  }

  Widget _buildAlbumArt(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.width * 0.85,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child:
            (widget.song.coverImageUrl != null &&
                widget.song.coverImageUrl!.isNotEmpty)
            ? Image.network(
                widget.song.coverImageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            : Container(
                color: AppColors.surface,
                child: const Center(
                  child: Icon(
                    Icons.music_note,
                    color: Colors.white24,
                    size: 80,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProgressBar() {
    double value = 0;
    if (_duration.inMilliseconds > 0) {
      value = _position.inMilliseconds / _duration.inMilliseconds;
    }
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value.clamp(0.0, 1.0),
            onChanged: (v) {
              final newPos = Duration(
                milliseconds: (v * _duration.inMilliseconds).toInt(),
              );
              if (widget.song.isYoutube) {
                _youtubeController?.seekTo(newPos);
              } else {
                _audioPlayer?.seek(newPos);
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_position),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatDuration(_duration),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 48),
          onPressed: () {},
        ),
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            height: 75,
            width: 75,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppColors.primary,
              size: 50,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, color: Colors.white, size: 48),
          onPressed: () {},
        ),
      ],
    );
  }

  void _startLyricSetup(BuildContext context, Song song) async {
    if (_isPlaying) {
      _togglePlay();
    }

    setState(() => _isPreparingKaraoke = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
      ),
    );

    try {
      final controller = KaraokeController();
      final karaokeSong = await controller.convertSongToKaraoke(song);

      if (context.mounted) {
        Navigator.pop(context); // close loading
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<KaraokeController>.value(
              value: controller,
              child: LyricEditorScreen(
                song: karaokeSong,
                controller: controller,
                sourceSongId: song.id,
              ),
            ),
          ),
        );
      }

      // Mark lyrics ready only if lyrics were actually saved
      if (mounted) {
        final savedSongs = controller.songs;
        final hasSaved = savedSongs.any(
          (s) => s.id == karaokeSong.id && s.lyrics.isNotEmpty,
        );
        setState(() => _lyricsReadyOverride = hasSaved);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lyrics setup failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPreparingKaraoke = false);
      }
    }
  }

  void _startKaraokeConversion(BuildContext context, Song song) async {
    if (!_hasLyrics) return;

    // Pause current playing audio first
    if (_isPlaying) {
      _togglePlay();
    }

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
      ),
    );

    try {
      final controller = KaraokeController();
      final karaokeSong = await controller.convertSongToKaraoke(song);

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        if (karaokeSong.lyrics.isNotEmpty) {
          // Auto-fetched lyrics — let user choose edit or play
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Karaoke Lyrics Fetched!',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'Auto-captured ${karaokeSong.lyrics.length} lyric lines from YouTube captions!\n\nWould you like to edit them or play the Karaoke directly?',
                style: const TextStyle(color: Colors.grey),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChangeNotifierProvider<KaraokeController>.value(
                          value: controller,
                          child: LyricEditorScreen(
                            song: karaokeSong,
                            controller: controller,
                            sourceSongId: song.id,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Edit/Verify Lyrics',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChangeNotifierProvider<KaraokeController>.value(
                          value: controller,
                          child: PlayerScreen(
                            song: karaokeSong,
                            controller: controller,
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('Play Karaoke'),
                ),
              ],
            ),
          );
        } else {
          // No lyrics fetched — open editor to add manually
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No captions found. Opening editor to add lyrics.'),
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider<KaraokeController>.value(
                value: controller,
                child: LyricEditorScreen(
                  song: karaokeSong,
                  controller: controller,
                  sourceSongId: song.id,
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading if still open
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Conversion failed: $e')));
      }
    }
  }
}

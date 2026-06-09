import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/karaoke/presentation/controllers/karaoke_controller.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/lyric_editor_screen.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/player_screen.dart';
import 'package:music_app_frontend/features/references/screens/reference_material_screen.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/services/song_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart' as provider;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:music_app_frontend/features/karaoke/data/repositories/karaoke_repository.dart';
import 'package:music_app_frontend/features/karaoke/data/models/karaoke_song.dart';

class SongPlayerScreen extends ConsumerStatefulWidget {
  final Song song;
  final String category;

  const SongPlayerScreen({
    super.key,
    required this.song,
    required this.category,
  });

  @override
  ConsumerState<SongPlayerScreen> createState() => _SongPlayerScreenState();
}

class _SongPlayerScreenState extends ConsumerState<SongPlayerScreen> {
  AudioPlayer? _audioPlayer;
  YoutubePlayerController? _youtubeController;
  bool _isPlaying = false;
  bool _isPreparingKaraoke = false;
  bool _lyricsReadyOverride = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Song? _currentSong;

  bool _hasKaraokeLyrics = false;

  @override
  void initState() {
    _currentSong = widget.song;
    _loadLatestSongDetails();
    _checkKaraokeLyricsStatus();
    super.initState();
    _initPlayer();
  }

  bool _isSongMatch(KaraokeSong karaoke, Song song) {
    if (karaoke.id == song.id) return true;

    final titleMatches =
        karaoke.title.trim().toLowerCase() == song.title.trim().toLowerCase();
    if (!titleMatches) return false;

    final songUrl = song.audioUrl;
    if (songUrl == null) return false;

    if (song.isYoutube) {
      final songYtId =
          YoutubePlayer.convertUrlToId(songUrl) ??
          (songUrl.length == 11 ? songUrl : null);
      final karaokeYtId =
          YoutubePlayer.convertUrlToId(karaoke.sourcePath) ??
          karaoke.sourcePath;
      if (songYtId != null && songYtId == karaokeYtId) {
        return true;
      }
    } else {
      final songFilename = songUrl.split('/').last.split('\\').last;
      final karaokeFilename = karaoke.sourcePath
          .split('/')
          .last
          .split('\\')
          .last;
      if (songFilename == karaokeFilename) {
        return true;
      }
    }

    final artistMatches =
        (karaoke.artist?.trim().toLowerCase() ?? '') ==
        song.artist.trim().toLowerCase();
    return artistMatches;
  }

  void _checkKaraokeLyricsStatus() async {
    try {
      final repo = KaraokeRepository();
      final karaokeSongs = await repo.getAllSongs();
      final hasSaved = karaokeSongs.any(
        (s) => _isSongMatch(s, widget.song) && s.lyrics.isNotEmpty,
      );
      if (mounted) {
        setState(() {
          _hasKaraokeLyrics = hasSaved;
        });
      }
    } catch (e) {
      debugPrint("Error checking karaoke lyrics status: $e");
    }
  }

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
    final videoId =
        (url.length == 11 && !url.contains('/') && !url.contains('?'))
        ? url
        : YoutubePlayer.convertUrlToId(url);
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

  void _skipForward() {
    final newPosition = _position + const Duration(seconds: 10);
    final maxPosition = _duration;

    if (newPosition < maxPosition) {
      if (widget.song.isYoutube) {
        _youtubeController?.seekTo(newPosition);
      } else {
        _audioPlayer?.seek(newPosition);
      }
    } else {
      if (widget.song.isYoutube) {
        _youtubeController?.seekTo(maxPosition);
      } else {
        _audioPlayer?.seek(maxPosition);
      }
    }
  }

  void _skipBackward() {
    final newPosition = _position - const Duration(seconds: 10);

    if (newPosition > Duration.zero) {
      if (widget.song.isYoutube) {
        _youtubeController?.seekTo(newPosition);
      } else {
        _audioPlayer?.seek(newPosition);
      }
    } else {
      if (widget.song.isYoutube) {
        _youtubeController?.seekTo(Duration.zero);
      } else {
        _audioPlayer?.seek(Duration.zero);
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  bool get _hasLyrics => _lyricsReadyOverride || _hasKaraokeLyrics;

  void _openMaterial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.50,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Reference Materials',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ReferenceMaterialScreen(
                    songId: widget.song.id,
                    showAppBar: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = screenWidth > 600 ? 30.0 : 26.0;
    final artistFontSize = screenWidth > 600 ? 20.0 : 18.0;
    final lyricsFontSize = screenWidth > 600 ? 16.0 : 14.0;

    final meAsync = ref.watch(meProvider);
    final isOwner = meAsync.maybeWhen(
      data: (user) => user.id == widget.song.userId,
      orElse: () => false,
    );

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
              color: _hasLyrics ? AppColors.primary : Colors.grey,
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildMedia(context),
                  const SizedBox(height: 40),
                  Text(
                    _currentSong?.lyrics ?? "Enjoy the music!",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: lyricsFontSize,
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.song.artist,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: artistFontSize,
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
                          if (isOwner)
                            IconButton(
                              tooltip: _hasLyrics
                                  ? 'Karaoke lyrics ready'
                                  : 'Set up lyrics',
                              icon: Icon(
                                Icons.lyrics,
                                color: _hasLyrics
                                    ? Colors.grey.shade600
                                    : AppColors.primary,
                                size: 28,
                              ),
                              onPressed: _hasLyrics || _isPreparingKaraoke
                                  ? null
                                  : () => _startLyricSetup(context, widget.song),
                            ),
                          if (isOwner) const SizedBox(height: 10),
                          const Icon(
                            Icons.favorite,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildActionButtons(isOwner),
                  const SizedBox(height: 24),
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
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isOwner) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: [
        _ActionButton(
          icon: Icons.description_outlined,
          label: 'Material',
          onTap: _openMaterial,
        ),
        // Karaoke button is visible to everyone — owner can set up lyrics,
        // anyone can sing if lyrics are already ready.
        _ActionButton(
          icon: Icons.mic_outlined,
          label: 'Karaoke',
          onTap: _hasLyrics
              ? () => _startKaraokeConversion(context, widget.song)
              : isOwner
                  ? () {
                      if (_isPreparingKaraoke) return;
                      _startLyricSetup(context, widget.song);
                    }
                  : null, // non-owner, no lyrics yet → greyed out
        ),
        _ActionButton(
          icon: Icons.grid_on_outlined,
          label: 'Chord',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildFeatureActions() {
    final enabled = _hasLyrics && !_isPreparingKaraoke;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonMaxWidth = screenWidth > 600 ? 320.0 : 260.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: buttonMaxWidth),
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
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
            shadowColor: AppColors.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    final controller = _youtubeController;
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 600 ? 600.0 : screenWidth;
    final youtubeHeight = (contentWidth - 48) * 0.55;

    if (widget.song.isYoutube && controller != null) {
      return Container(
        height: youtubeHeight,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 600 ? 600.0 : screenWidth;
    final albumArtSize = (contentWidth - 48) * 0.85;

    return Container(
      height: albumArtSize,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final playButtonSize = screenWidth > 600 ? 85.0 : 75.0;
    final playIconSize = screenWidth > 600 ? 56.0 : 50.0;
    final skipIconSize = screenWidth > 600 ? 52.0 : 48.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.replay_10, color: Colors.white, size: skipIconSize),
          onPressed: _skipBackward,
          tooltip: 'Rewind 10 seconds',
        ),
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            height: playButtonSize,
            width: playButtonSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppColors.primary,
              size: playIconSize,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.forward_10, color: Colors.white, size: skipIconSize),
          onPressed: _skipForward,
          tooltip: 'Forward 10 seconds',
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
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final controller = KaraokeController();
      final karaokeSong = await controller.convertSongToKaraoke(song);

      if (context.mounted) {
        Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                provider.ChangeNotifierProvider<KaraokeController>.value(
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

      if (mounted) {
        final savedSongs = controller.songs;
        final hasSaved = savedSongs.any(
          (s) => _isSongMatch(s, widget.song) && s.lyrics.isNotEmpty,
        );
        setState(() {
          _lyricsReadyOverride = hasSaved;
          _hasKaraokeLyrics = hasSaved;
        });
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

    if (_isPlaying) {
      _togglePlay();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final controller = KaraokeController();
      final karaokeSong = await controller.convertSongToKaraoke(song);

      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        if (karaokeSong.lyrics.isNotEmpty) {
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
                            provider.ChangeNotifierProvider<
                              KaraokeController
                            >.value(
                              value: controller,
                              child: LyricEditorScreen(
                                song: karaokeSong,
                                controller: controller,
                                sourceSongId: song.id,
                              ),
                            ),
                      ),
                    ).then((_) => _checkKaraokeLyricsStatus());
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
                            provider.ChangeNotifierProvider<
                              KaraokeController
                            >.value(
                              value: controller,
                              child: PlayerScreen(
                                song: karaokeSong,
                                controller: controller,
                              ),
                            ),
                      ),
                    ).then((_) => _checkKaraokeLyricsStatus());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('Play Karaoke'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No captions found. Opening editor to add lyrics.'),
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  provider.ChangeNotifierProvider<KaraokeController>.value(
                    value: controller,
                    child: LyricEditorScreen(
                      song: karaokeSong,
                      controller: controller,
                      sourceSongId: song.id,
                    ),
                  ),
            ),
          ).then((_) => _checkKaraokeLyricsStatus());
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Conversion failed: $e')));
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isEnabled ? AppColors.primary : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled ? AppColors.primary : Colors.white24,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? AppColors.primary : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

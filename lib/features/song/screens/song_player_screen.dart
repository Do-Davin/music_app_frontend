import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() async {
    final url = widget.song.audioUrl;
    if (url == null || url.isEmpty) {
      debugPrint("No playback URL found for song: ${widget.song.title}");
      return;
    }

    if (widget.song.isYoutube) {
      final videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            hideControls: true,
            disableDragSeek: true,
          ),
        )..addListener(() {
            if (mounted) {
              setState(() {
                _isPlaying = _youtubeController!.value.isPlaying;
                _position = _youtubeController!.value.position;
                _duration = _youtubeController!.metadata.duration;
              });
            }
          });
      } else {
        debugPrint("Could not extract YouTube ID from URL: $url");
      }
    } else {
      _audioPlayer = AudioPlayer();
      try {
        await _audioPlayer!.setUrl(url);
        _audioPlayer!.play();
      } catch (e) {
        debugPrint("Error loading audio: $e");
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

  @override
  Widget build(BuildContext context) {
    if (widget.song.isYoutube && _youtubeController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController!,
          onReady: () {
            debugPrint('YouTube Player is ready.');
          },
        ),
        builder: (context, player) {
          return _buildScaffold(context, player);
        },
      );
    }
    return _buildScaffold(context, null);
  }

  Widget _buildScaffold(BuildContext context, Widget? youtubePlayer) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category,
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildAlbumArt(context, youtubePlayer),
              const SizedBox(height: 40),
              Text(
                widget.song.lyrics ?? "Enjoy the music!",
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 30),

              // ── Song title, artist & favourite ──────────────────────────
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
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.song.artist,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.favorite,
                      color: AppColors.primary, size: 30),
                ],
              ),

              const SizedBox(height: 24),

              // ── Material / Karaoke / Chord buttons ──────────────────────
              _buildActionButtons(),

              const SizedBox(height: 24),

              // ── Progress bar & controls ─────────────────────────────────
              _buildProgressBar(),
              const SizedBox(height: 20),
              _buildPlayerControls(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _ActionButton(
          icon: Icons.description_outlined,
          label: 'Material',
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.mic_outlined,
          label: 'Karaoke',
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.grid_on_outlined,
          label: 'Chord',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildAlbumArt(BuildContext context, Widget? youtubePlayer) {
    return Container(
      height: MediaQuery.of(context).size.width * 0.85,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 25,
              offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (widget.song.coverImageUrl != null &&
                widget.song.coverImageUrl!.isNotEmpty)
              Image.network(widget.song.coverImageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity)
            else
              Container(
                  color: AppColors.surface,
                  child: const Center(
                      child: Icon(Icons.music_note,
                          color: Colors.white24, size: 80))),
            if (youtubePlayer != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.01,
                  child: youtubePlayer,
                ),
              ),
          ],
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
                  milliseconds: (v * _duration.inMilliseconds).toInt());
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
            Text(_formatDuration(_position),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            Text(_formatDuration(_duration),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
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
            icon: const Icon(Icons.skip_previous,
                color: Colors.white, size: 48),
            onPressed: () {}),
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            height: 75,
            width: 75,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppColors.surface),
            child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.primary,
                size: 50),
          ),
        ),
        IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 48),
            onPressed: () {}),
      ],
    );
  }
}

// ── Reusable pill-shaped action button ────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
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
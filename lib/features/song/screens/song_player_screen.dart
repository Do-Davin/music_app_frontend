import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/karaoke/presentation/controllers/karaoke_controller.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/lyric_editor_screen.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/player_screen.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/chord_viewer_screen.dart';
import 'package:music_app_frontend/features/karaoke/presentation/screens/lyric_chord_builder_screen.dart';
import 'package:music_app_frontend/features/references/screens/reference_material_screen.dart';
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/features/song/services/song_service.dart';
import 'package:provider/provider.dart' as provider;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:music_app_frontend/features/karaoke/data/repositories/karaoke_repository.dart';
import 'package:music_app_frontend/features/karaoke/data/models/karaoke_song.dart';
import 'package:music_app_frontend/core/utils/youtube_parser.dart';
import 'package:music_app_frontend/core/utils/song_matcher.dart';
import 'package:music_app_frontend/shared/widgets/favorite_icon_button.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/song/providers/song_provider.dart';
import 'package:music_app_frontend/features/song/providers/global_audio_player_provider.dart';

class SongPlayerScreen extends ConsumerStatefulWidget {
  final Song song;
  final String category;
  final bool isEmbedMode;

  const SongPlayerScreen({
    super.key,
    required this.song,
    required this.category,
    this.isEmbedMode = false,
  });

  @override
  ConsumerState<SongPlayerScreen> createState() => _SongPlayerScreenState();
}

class _SongPlayerScreenState extends ConsumerState<SongPlayerScreen> {
  bool _isPreparingKaraoke = false;
  bool _lyricsReadyOverride = false;
  bool _hasKaraokeLyrics = false;
  String? _lastSongId;
  Song? _currentSongDetails;

  @override
  void initState() {
    super.initState();
    _currentSongDetails = widget.song;
    _checkKaraokeLyricsStatus(widget.song);
    _loadLatestSongDetails(widget.song);
  }

  bool _isSongMatch(KaraokeSong karaoke, Song song) {
    return isSongMatch(karaoke, song);
  }

  void _checkKaraokeLyricsStatus(Song song) async {
    try {
      final repo = KaraokeRepository();
      final ownSongs = await repo.getAllSongs();
      final publicSongs = await repo.getPublicSongs();

      final hasSavedOwn = ownSongs.any(
        (s) => _isSongMatch(s, song) && s.lyrics.isNotEmpty,
      );
      final hasSavedPublic = publicSongs.any(
        (s) => _isSongMatch(s, song) && s.lyrics.isNotEmpty,
      );
      final hasSaved = hasSavedOwn || hasSavedPublic;

      if (mounted) {
        setState(() {
          _hasKaraokeLyrics = hasSaved;
        });
      }
    } catch (e) {
      debugPrint("Error checking karaoke lyrics status: $e");
    }
  }

  void _loadLatestSongDetails(Song song) async {
    try {
      final freshSong = await SongService().fetchSongById(song.id);
      if (freshSong != null && mounted) {
        setState(() {
          _currentSongDetails = freshSong;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch fresh song details in player: $e");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  bool get _hasLyrics => _lyricsReadyOverride || _hasKaraokeLyrics;

  void _openMaterial(Song song) {
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
                    songId: song.id,
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
    final playerState = ref.watch(globalAudioPlayerProvider);
    final song = playerState.currentSong ?? widget.song;

    // Track active song details
    if (song.id != _lastSongId) {
      _lastSongId = song.id;
      _currentSongDetails = song;
      Future.microtask(() {
        _checkKaraokeLyricsStatus(song);
        _loadLatestSongDetails(song);
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = screenWidth > 600 ? 30.0 : 26.0;
    final artistFontSize = screenWidth > 600 ? 20.0 : 18.0;
    final lyricsFontSize = screenWidth > 600 ? 16.0 : 14.0;

    final meAsync = ref.watch(meProvider);
    final isOwner = meAsync.maybeWhen(
      data: (user) => user.id == song.userId,
      orElse: () => false,
    );

    final isLikedAsync = ref.watch(isSongInLikedSongsProvider(song.id));
    final isLiked = isLikedAsync.valueOrNull ?? false;

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
          onPressed: () {
            if (widget.isEmbedMode) {
              ref.read(globalAudioPlayerProvider.notifier).setMaximized(false);
            } else {
              Navigator.pop(context);
            }
          },
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
        actions: const [SizedBox(width: 8)],
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
                  _buildMedia(context, song),
                  const SizedBox(height: 40),
                  Text(
                    _currentSongDetails?.lyrics ?? "Enjoy the music!",
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
                              song.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              song.artist,
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
                      FavoriteIconButton(
                        songId: song.id,
                        initialIsFavorite: isLiked,
                        iconSize: 28,
                        onToggle: () {
                          ref.invalidate(likedSongsPlaylistProvider);
                          ref.invalidate(likedSongsProvider);
                          ref.invalidate(isSongInLikedSongsProvider(song.id));
                          ref.read(myPlaylistsProvider.notifier).refreshPlaylists();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildActionButtons(isOwner, song),
                  const SizedBox(height: 24),
                  _buildProgressBar(playerState),
                  const SizedBox(height: 20),
                  _buildPlayerControls(playerState),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isOwner, Song song) {
    final bool isKaraokeDisabled = !isOwner && !_hasLyrics;

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: [
        _ActionButton(
          icon: Icons.description_outlined,
          label: 'Material',
          onTap: () => _openMaterial(song),
        ),
        _ActionButton(
          icon: Icons.mic_outlined,
          label: 'Karaoke',
          isDisabled: isKaraokeDisabled,
          onTap: isKaraokeDisabled
              ? () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Not Available', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: const Text(
                        'This song has not been converted to karaoke yet. Only the owner of this song can convert it.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }
              : (_hasLyrics
                  ? () => _startKaraokeConversion(context, song)
                  : () {
                      if (_isPreparingKaraoke) return;
                      _showConvertToKaraokeDialog(context, song);
                    }),
          showEditIcon: isOwner && _hasLyrics,
          onEditTap: isOwner && _hasLyrics
              ? () => _showEditLyricDialog(context, song)
              : null,
        ),
        _ActionButton(
          icon: Icons.grid_on_outlined,
          label: 'Chord',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChordViewerScreen(
                songId: widget.song.id,
                songTitle: widget.song.title,
                isOwner: isOwner,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedia(BuildContext context, Song song) {
    final ytController = ref.watch(globalAudioPlayerProvider.notifier).youtubeController;
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 600 ? 600.0 : screenWidth;
    final youtubeHeight = (contentWidth - 48) * 0.55;

    if (song.isYoutube && ytController != null) {
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
            controller: ytController,
            showVideoProgressIndicator: false,
          ),
        ),
      );
    }

    return _buildAlbumArt(context, song);
  }

  Widget _buildAlbumArt(BuildContext context, Song song) {
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
        child: (song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty)
            ? Image.network(
                song.coverImageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white24,
                      size: 80,
                    ),
                  ),
                ),
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

  Widget _buildProgressBar(GlobalPlayerState playerState) {
    double value = 0;
    final duration = playerState.duration;
    final position = playerState.position;

    if (duration.inMilliseconds > 0) {
      value = position.inMilliseconds / duration.inMilliseconds;
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
                milliseconds: (v * duration.inMilliseconds).toInt(),
              );
              ref.read(globalAudioPlayerProvider.notifier).seek(newPos);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(position),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatDuration(duration),
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

  Widget _buildPlayerControls(GlobalPlayerState playerState) {
    final screenWidth = MediaQuery.of(context).size.width;
    final playButtonSize = screenWidth > 600 ? 85.0 : 75.0;
    final playIconSize = screenWidth > 600 ? 56.0 : 50.0;
    final skipIconSize = screenWidth > 600 ? 52.0 : 48.0;

    final isPlaying = playerState.isPlaying;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.replay_10, color: Colors.white, size: skipIconSize),
          onPressed: () {
            final newPos = playerState.position - const Duration(seconds: 10);
            ref.read(globalAudioPlayerProvider.notifier).seek(
                  newPos > Duration.zero ? newPos : Duration.zero,
                );
          },
          tooltip: 'Rewind 10 seconds',
        ),
        IconButton(
          icon: Icon(Icons.skip_previous_rounded, color: Colors.white, size: skipIconSize),
          onPressed: () {
            ref.read(globalAudioPlayerProvider.notifier).previous();
          },
          tooltip: 'Previous song',
        ),
        GestureDetector(
          onTap: () {
            ref.read(globalAudioPlayerProvider.notifier).togglePlay();
          },
          child: Container(
            height: playButtonSize,
            width: playButtonSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppColors.primary,
              size: playIconSize,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.skip_next_rounded, color: Colors.white, size: skipIconSize),
          onPressed: () {
            ref.read(globalAudioPlayerProvider.notifier).next();
          },
          tooltip: 'Next song',
        ),
        IconButton(
          icon: Icon(Icons.forward_10, color: Colors.white, size: skipIconSize),
          onPressed: () {
            final newPos = playerState.position + const Duration(seconds: 10);
            ref.read(globalAudioPlayerProvider.notifier).seek(
                  newPos < playerState.duration ? newPos : playerState.duration,
                );
          },
          tooltip: 'Forward 10 seconds',
        ),
      ],
    );
  }

  void _startLyricSetup(BuildContext context, Song song) async {
    final isPlaying = ref.read(globalAudioPlayerProvider).isPlaying;
    if (isPlaying) {
      ref.read(globalAudioPlayerProvider.notifier).togglePlay();
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
          (s) => _isSongMatch(s, song) && s.lyrics.isNotEmpty,
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

    final isPlaying = ref.read(globalAudioPlayerProvider).isPlaying;
    if (isPlaying) {
      ref.read(globalAudioPlayerProvider.notifier).togglePlay();
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
      await controller.loadSongs();
      final ownSongs = controller.songs;
      final publicSongs = controller.publicSongs;

      KaraokeSong? matchingKaraoke;
      for (final s in ownSongs) {
        if (_isSongMatch(s, song) && s.lyrics.isNotEmpty) {
          matchingKaraoke = s;
          break;
        }
      }
      if (matchingKaraoke == null) {
        for (final s in publicSongs) {
          if (_isSongMatch(s, song) && s.lyrics.isNotEmpty) {
            matchingKaraoke = s;
            break;
          }
        }
      }

      final karaokeSong =
          matchingKaraoke ?? await controller.convertSongToKaraoke(song);

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                provider.ChangeNotifierProvider<KaraokeController>.value(
                  value: controller,
                  child: PlayerScreen(
                    song: karaokeSong,
                    controller: controller,
                  ),
                ),
          ),
        ).then((_) => _checkKaraokeLyricsStatus(song));
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

  void _showConvertToKaraokeDialog(BuildContext context, Song song) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1E2E), Color(0xFF2A1F3D)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.mic_none_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Create Karaoke Version',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Turn your song into a karaoke experience! '
                'We\'ll help you set up synchronized lyrics so you '
                'and others can sing along. 🎤',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startLyricSetup(context, song);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  child: const Text(
                    'Convert to Karaoke',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditLyricDialog(BuildContext context, Song song) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E2A1E), Color(0xFF1A2F3D)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.tealAccent.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.tealAccent.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.tealAccent.withValues(alpha: 0.2),
                      Colors.tealAccent.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.tealAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.tealAccent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Edit Karaoke Lyrics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Fine-tune your lyrics timing and text to make '
                'the karaoke experience even better! ✍️',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startLyricSetup(context, song);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    shadowColor: Colors.tealAccent.withValues(alpha: 0.4),
                  ),
                  child: const Text(
                    'Open Lyric Editor',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool showEditIcon;
  final VoidCallback? onEditTap;
  final bool isDisabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.showEditIcon = false,
    this.onEditTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null && !isDisabled;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 14, top: 8, bottom: 8, right: 6),
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
            if (showEditIcon) ...[
              Container(
                width: 1,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
              GestureDetector(
                onTap: onEditTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.edit_rounded,
                    color: AppColors.primary.withValues(alpha: 0.8),
                    size: 16,
                  ),
                ),
              ),
            ] else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

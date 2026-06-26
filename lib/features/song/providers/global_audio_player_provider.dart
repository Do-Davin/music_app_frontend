import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:music_app_frontend/features/song/models/song.dart';
import 'package:music_app_frontend/core/utils/youtube_parser.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class GlobalPlayerState {
  final Song? currentSong;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final List<Song> queue;
  final int currentIndex;
  final bool isMaximized;
  final bool isLoopMode;
  final String? errorMessage;

  GlobalPlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
    this.isMaximized = false,
    this.isLoopMode = false,
    this.errorMessage,
  });

  GlobalPlayerState copyWith({
    Song? currentSong,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    List<Song>? queue,
    int? currentIndex,
    bool? isMaximized,
    bool? isLoopMode,
    String? errorMessage,
    bool clearSong = false,
  }) {
    return GlobalPlayerState(
      currentSong: clearSong ? null : (currentSong ?? this.currentSong),
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isMaximized: isMaximized ?? this.isMaximized,
      isLoopMode: isLoopMode ?? this.isLoopMode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class GlobalAudioPlayerNotifier extends StateNotifier<GlobalPlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  YoutubePlayerController? _youtubeController;

  StreamSubscription? _justAudioPositionSub;
  StreamSubscription? _justAudioDurationSub;
  StreamSubscription? _justAudioStateSub;

  GlobalAudioPlayerNotifier() : super(GlobalPlayerState()) {
    _initJustAudioListeners();
  }

  YoutubePlayerController? get youtubeController => _youtubeController;

  void _initJustAudioListeners() {
    _justAudioPositionSub = _audioPlayer.positionStream.listen((pos) {
      if (state.currentSong != null && !state.currentSong!.isYoutube) {
        state = state.copyWith(position: pos);
      }
    });

    _justAudioDurationSub = _audioPlayer.durationStream.listen((dur) {
      if (state.currentSong != null && !state.currentSong!.isYoutube) {
        state = state.copyWith(duration: dur ?? Duration.zero);
      }
    });

    _justAudioStateSub = _audioPlayer.playerStateStream.listen((playerState) {
      if (state.currentSong != null && !state.currentSong!.isYoutube) {
        final isPlaying = playerState.playing;
        final processingState = playerState.processingState;
        final isLoading = processingState == ProcessingState.buffering ||
            processingState == ProcessingState.loading;

        state = state.copyWith(
          isPlaying: isPlaying,
          isLoading: isLoading,
        );

        if (processingState == ProcessingState.completed) {
          next(auto: true);
        }
      }
    });
  }

  void _initYoutubeListeners() {
    _youtubeController?.addListener(() {
      final ytController = _youtubeController;
      if (ytController != null && state.currentSong != null && state.currentSong!.isYoutube) {
        final ytState = ytController.value.playerState;
        final isPlaying = ytController.value.isPlaying ||
            (ytState != PlayerState.paused &&
             ytState != PlayerState.ended &&
             ytState != PlayerState.cued);
        final isBuffering = ytState == PlayerState.buffering;
        final position = ytController.value.position;
        final duration = ytController.metadata.duration;

        state = state.copyWith(
          isPlaying: isPlaying,
          isLoading: isBuffering,
          position: position,
          duration: duration,
        );

        if (ytState == PlayerState.ended) {
          next(auto: true);
        }
      }
    });
  }

  String? _resolvePlaybackUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    return url;
  }

  Future<void> playSong(Song song, {List<Song>? queue}) async {
    // Stop current playback
    await _stopCurrent();

    final resolvedQueue = List<Song>.from(queue ?? state.queue);
    int index = resolvedQueue.indexWhere((s) => s.id == song.id);
    if (index == -1 && queue == null) {
      resolvedQueue.add(song);
      index = resolvedQueue.length - 1;
    }

    state = state.copyWith(
      currentSong: song,
      isLoading: true,
      isPlaying: true,
      position: Duration.zero,
      duration: Duration.zero,
      queue: resolvedQueue,
      currentIndex: index,
    );

    final url = _resolvePlaybackUrl(song.audioUrl);
    if (url == null || url.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        errorMessage: 'No playback URL found.',
      );
      return;
    }

    try {
      if (song.isYoutube) {
        final videoId = extractYoutubeId(url);
        if (videoId == null) {
          state = state.copyWith(
            isLoading: false,
            isPlaying: false,
            errorMessage: 'Invalid YouTube URL.',
          );
          return;
        }

        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            hideControls: true,
            disableDragSeek: true,
          ),
        );
        _initYoutubeListeners();
      } else {
        _audioPlayer.play();
        await _audioPlayer.setUrl(url);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        errorMessage: 'Playback error: $e',
      );
    }
  }

  Future<void> _stopCurrent() async {
    if (state.currentSong == null) return;

    if (state.currentSong!.isYoutube) {
      _youtubeController?.dispose();
      _youtubeController = null;
    } else {
      await _audioPlayer.stop();
    }
  }

  void togglePlay() {
    final song = state.currentSong;
    if (song == null) return;

    if (song.isYoutube) {
      if (state.isPlaying) {
        _youtubeController?.pause();
      } else {
        _youtubeController?.play();
      }
    } else {
      if (state.isPlaying) {
        _audioPlayer.pause();
      } else {
        _audioPlayer.play();
      }
    }
  }

  void seek(Duration position) {
    final song = state.currentSong;
    if (song == null) return;

    if (song.isYoutube) {
      _youtubeController?.seekTo(position);
    } else {
      _audioPlayer.seek(position);
    }
  }

  bool _isTransitioning = false;

  void next({bool auto = false}) {
    if (state.queue.isEmpty || state.currentIndex == -1) return;

    if (state.currentIndex == state.queue.length - 1) {
      if (auto && !state.isLoopMode) {
        // Reset state FIRST so the stream listener sees currentSong == null
        // and immediately stops re-firing ProcessingState.completed.
        final wasYoutube = state.currentSong?.isYoutube ?? false;
        state = GlobalPlayerState(isLoopMode: state.isLoopMode);
        // Now stop the underlying player (safe fire-and-forget).
        if (wasYoutube) {
          _youtubeController?.dispose();
          _youtubeController = null;
        } else {
          _audioPlayer.stop();
        }
        _isTransitioning = false;
        return;
      }
    }

    // Guard against concurrent auto-advance calls.
    if (auto && _isTransitioning) return;
    _isTransitioning = auto;

    final nextIndex = (state.currentIndex + 1) % state.queue.length;
    playSong(state.queue[nextIndex]).then((_) {
      _isTransitioning = false;
    }).catchError((_) {
      _isTransitioning = false;
    });
  }

  void toggleLoopMode() {
    state = state.copyWith(isLoopMode: !state.isLoopMode);
  }

  void previous() {
    if (state.queue.isEmpty || state.currentIndex == -1) return;
    int prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = state.queue.length - 1;
    }
    playSong(state.queue[prevIndex]);
  }

  void setQueue(List<Song> queue, int index) {
    state = state.copyWith(queue: queue, currentIndex: index);
  }

  void setMaximized(bool max) {
    state = state.copyWith(isMaximized: max);
  }

  void setMuted(bool muted) {
    _audioPlayer.setVolume(muted ? 0.0 : 1.0);
    if (muted) {
      _youtubeController?.mute();
    } else {
      _youtubeController?.unMute();
    }
  }

  void clear() {
    _stopCurrent();
    state = GlobalPlayerState();
  }

  @override
  void dispose() {
    _justAudioPositionSub?.cancel();
    _justAudioDurationSub?.cancel();
    _justAudioStateSub?.cancel();
    _audioPlayer.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }
}

final globalAudioPlayerProvider =
    StateNotifierProvider<GlobalAudioPlayerNotifier, GlobalPlayerState>((ref) {
  return GlobalAudioPlayerNotifier();
});

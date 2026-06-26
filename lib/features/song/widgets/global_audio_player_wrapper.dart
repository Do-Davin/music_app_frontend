import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/song/providers/global_audio_player_provider.dart';
import 'package:music_app_frontend/features/song/widgets/sliding_player_panel.dart';

class GlobalAudioPlayerWrapper extends ConsumerWidget {
  final String currentPath;
  final Widget child;

  const GlobalAudioPlayerWrapper({
    super.key,
    required this.currentPath,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(globalAudioPlayerProvider);
    final currentSong = playerState.currentSong;

    // Do not show the player on auth / onboarding / splash screens
    final bool isAuthScreen = currentPath == Routes.root ||
        currentPath == Routes.splash ||
        currentPath == Routes.onboarding ||
        currentPath == Routes.login ||
        currentPath == Routes.register ||
        currentPath == Routes.forgotPassword ||
        currentPath == Routes.verifyAccount ||
        currentPath == Routes.newPassword;

    if (currentSong == null || isAuthScreen) {
      return child;
    }

    final bool isMain = currentPath == Routes.main;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // BottomNavigationBar height on main screen is usually around 56 + bottom safe padding.
    // If not on main screen, navHeight is 0 so the mini-player sits at the very bottom.
    final double navHeight = isMain ? (56.0 + bottomPadding) : 0.0;

    return SlidingPlayerPanel(
      body: child,
      currentPath: currentPath,
      navHeight: navHeight,
      currentSong: currentSong,
      isPlaying: playerState.isPlaying,
      isLoading: playerState.isLoading,
      position: playerState.position,
      duration: playerState.duration,
      isMaximized: playerState.isMaximized,
      onMinimize: () => ref.read(globalAudioPlayerProvider.notifier).setMaximized(false),
      onMaximize: () => ref.read(globalAudioPlayerProvider.notifier).setMaximized(true),
    );
  }
}

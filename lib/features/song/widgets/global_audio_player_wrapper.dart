import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/auth_provider.dart';
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
    final authState = ref.watch(authProvider);

    // If the user is unauthenticated, the root route is an auth screen.
    // If the user is authenticated, the root route is the MainScreen, which should show the player.
    final bool isUnauthenticated = !authState.isAuthenticated;
    final bool isAuthScreen = (currentPath == Routes.root && isUnauthenticated) ||
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

    // The MainScreen can reside on Routes.main or Routes.root.
    final bool isMain = currentPath == Routes.main || currentPath == Routes.root;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // BottomNavigationBar height on main screen is usually around 56 + bottom safe padding.
    // If not on main screen, navHeight is 0 so the mini-player sits at the very bottom.
    final double navHeight = isMain ? (56.0 + bottomPadding) : 0.0;

    debugPrint('🎵 GlobalAudioPlayerWrapper: path=$currentPath, song=${currentSong.title}, navHeight=$navHeight');

    return SlidingPlayerPanel(
      key: const ValueKey('global_audio_player_panel'),
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

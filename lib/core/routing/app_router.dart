import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/routing/auth_wrapper.dart';
import 'package:music_app_frontend/core/routing/routes.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/forgot_password/forgot_password_screen.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/forgot_password/new_password_screen.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/forgot_password/verify_account_screen.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/login/login_screen.dart';
import 'package:music_app_frontend/features/auth/presentation/screens/register/register_screen.dart';
import 'package:music_app_frontend/features/friends/screens/friends_screen.dart'
    show FriendsFilter, FriendsScreen;
import 'package:music_app_frontend/features/home/screens/main_screen.dart';
import 'package:music_app_frontend/features/onboarding/screens/onboarding_screen.dart';
import 'package:music_app_frontend/features/onboarding/screens/splash_screen.dart';
import 'package:music_app_frontend/features/playlist/screens/no_playlists_screen.dart';
import 'package:music_app_frontend/features/playlist/screens/playlist_detail_screen.dart';
import 'package:music_app_frontend/features/relationships/screens/follow_list_screen.dart';
import 'package:music_app_frontend/features/relationships/screens/user_detail_screen.dart';
import 'package:music_app_frontend/features/playlist/screens/liked_songs_screen.dart';
import 'package:music_app_frontend/features/song/screens/song_player_screen.dart';
import 'package:music_app_frontend/features/song/screens/no_results_screen.dart';
import 'package:music_app_frontend/shared/screens/stateless_status_screen.dart';
import 'package:music_app_frontend/features/song/models/song.dart' as real_song;
import 'package:music_app_frontend/features/song/widgets/global_audio_player_wrapper.dart';

class SongPlayerRouteData {
  const SongPlayerRouteData({required this.song, required this.category});

  final real_song.Song song;
  final String category;
}

// Fade + slight horizontal slide used for list-to-detail navigations.
CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: Routes.root,
  routes: [
    GoRoute(
      path: Routes.root,
      builder: (context, state) => const AuthWrapper(),
    ),
    GoRoute(
      path: Routes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: Routes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: Routes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: Routes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: Routes.verifyAccount,
      builder: (context, state) => const VerifyAccountScreen(),
    ),
    GoRoute(
      path: Routes.newPassword,
      builder: (context, state) => const CreateNewPasswordScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return GlobalAudioPlayerWrapper(
          currentPath: state.matchedLocation,
          child: child,
        );
      },
      routes: [
        GoRoute(path: Routes.main, builder: (context, state) => const MainScreen()),
        GoRoute(
          path: Routes.friends,
          builder: (context, state) {
            final extra = state.extra;
            return FriendsScreen(
              initialFilter: extra is FriendsFilter ? extra : null,
            );
          },
        ),
        GoRoute(
          path: Routes.followers,
          pageBuilder: (context, state) => _slidePage(
            state,
            const FollowListScreen(mode: FollowListMode.followers),
          ),
        ),
        GoRoute(
          path: Routes.following,
          pageBuilder: (context, state) => _slidePage(
            state,
            const FollowListScreen(mode: FollowListMode.following),
          ),
        ),
        GoRoute(
          path: Routes.userDetail,
          pageBuilder: (context, state) {
            final extra = state.extra;
            final child = extra is User
                ? UserDetailScreen(user: extra)
                : const StatelessStatusScreen(
                    icon: Icons.person_off_outlined,
                    appBarTitle: 'Profile',
                    title: 'Profile Unavailable',
                    subtitle: 'This profile could not be opened.',
                    iconColor: AppColors.error,
                    iconBackgroundColor: AppColors.errorBackground,
                  );
            return _slidePage(state, child);
          },
        ),
        GoRoute(
          path: Routes.status,
          builder: (context, state) => const StatelessStatusScreen(
            icon: Icons.signal_wifi_off,
            appBarTitle: 'Library',
            title: 'No Internet Connection',
            subtitle:
                'You\'re offline. Some content may not be available. Check your connection and try again.',
            iconColor: AppColors.error,
            iconBackgroundColor: Color(0x33FF5252),
            highlightWord: 'Internet',
          ),
        ),
        GoRoute(
          path: Routes.noPlaylists,
          builder: (context, state) => const NoPlaylistsScreen(),
        ),
        GoRoute(
          path: Routes.playlistDetail,
          pageBuilder: (context, state) {
            final id = state.pathParameters['id']!;
            return _slidePage(state, PlaylistDetailScreen(playlistId: id));
          },
        ),
        GoRoute(
          path: Routes.noResults,
          builder: (context, state) => const NoResultsScreen(),
        ),
        GoRoute(
          path: Routes.likedSongs,
          pageBuilder: (context, state) =>
              _slidePage(state, const LikedSongsPlaylistDetailWrapper()),
        ),
        GoRoute(
          path: Routes.song,
          pageBuilder: (context, state) {
            final extra = state.extra;
            final child = extra is SongPlayerRouteData
                ? SongPlayerScreen(song: extra.song, category: extra.category)
                : const NoResultsScreen();
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: child,
              transitionDuration: const Duration(milliseconds: 250),
              reverseTransitionDuration: const Duration(milliseconds: 250),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
            );
          },
        ),
      ],
    ),
  ],
);

class LikedSongsPlaylistDetailWrapper extends ConsumerWidget {
  const LikedSongsPlaylistDetailWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedSongsAsync = ref.watch(likedSongsPlaylistProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: likedSongsAsync.when(
        data: (playlist) => PlaylistDetailScreen(playlistId: playlist.id),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, st) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

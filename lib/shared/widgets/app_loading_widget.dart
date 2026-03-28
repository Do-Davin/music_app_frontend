import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppLoadingWidget — simple centered spinner with optional message
// Use this when you just need a quick loading indicator
//
// Example:
//   AppLoadingWidget()
//   AppLoadingWidget(message: 'Loading profile...')
// ─────────────────────────────────────────────────────────────────────────────
class AppLoadingWidget extends StatelessWidget {
  final String? message;

  const AppLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary, // orange spinner
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.body.copyWith(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileSkeletonLoader
// Mimics the exact layout of ProfileScreen while data is loading.
// Shows: avatar circle → name bar → email bar → button bar → playlist rows
// ─────────────────────────────────────────────────────────────────────────────
class ProfileSkeletonLoader extends StatefulWidget {
  const ProfileSkeletonLoader({super.key});

  @override
  State<ProfileSkeletonLoader> createState() => _ProfileSkeletonLoaderState();
}

class _ProfileSkeletonLoaderState extends State<ProfileSkeletonLoader>
    with SingleTickerProviderStateMixin {
  // AnimationController drives the shimmer pulse
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true); // loops: dim → bright → dim

    _shimmer = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose(); // always clean up controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        // shimmerColor pulses between dim and bright grey
        final color = Colors.grey[800]!.withValues(alpha: _shimmer.value);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              // ── Avatar circle placeholder ──────────────────────────────
              Center(
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Name bar ───────────────────────────────────────────────
              _bar(color, width: 160, height: 18),
              const SizedBox(height: 10),

              // ── Email bar ──────────────────────────────────────────────
              _bar(color, width: 200, height: 14),
              const SizedBox(height: 8),

              // ── Followers bar ──────────────────────────────────────────
              _bar(color, width: 140, height: 14),
              const SizedBox(height: 24),

              // ── Edit profile button placeholder ────────────────────────
              _bar(color, width: double.infinity, height: 48, radius: 30),
              const SizedBox(height: 32),

              // ── "Playlists" title bar ──────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: _bar(color, width: 100, height: 18),
              ),
              const SizedBox(height: 16),

              // ── Playlist row placeholders ──────────────────────────────
              _playlistRow(color),
              const SizedBox(height: 16),
              _playlistRow(color),
              const SizedBox(height: 16),
              _playlistRow(color),
            ],
          ),
        );
      },
    );
  }

  // ── Reusable grey bar (title, email, button shapes) ───────────────────────
  Widget _bar(
    Color color, {
    required double width,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ── Single playlist row placeholder ───────────────────────────────────────
  Widget _playlistRow(Color color) {
    return Row(
      children: [
        // Thumbnail square
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 16),
        // Title bar
        Expanded(child: _bar(color, width: double.infinity, height: 14)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HomeSkeletonLoader
// Mimics the exact layout of HomeScreen while data is loading.
// Shows: header → continue listening card → horizontal song rows
// ─────────────────────────────────────────────────────────────────────────────
class HomeSkeletonLoader extends StatefulWidget {
  const HomeSkeletonLoader({super.key});

  @override
  State<HomeSkeletonLoader> createState() => _HomeSkeletonLoaderState();
}

class _HomeSkeletonLoaderState extends State<HomeSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shimmer = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final color = Colors.grey[800]!.withValues(alpha: _shimmer.value);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: "Hello, ___!" ──────────────────────────────────
              _bar(color, width: 180, height: 28),
              const SizedBox(height: 32),

              // ── Section title ──────────────────────────────────────────
              _bar(color, width: 160, height: 18),
              const SizedBox(height: 16),

              // ── Continue Listening card ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF232323),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Album art placeholder
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _bar(color, width: 120, height: 16),
                          const SizedBox(height: 8),
                          _bar(color, width: 80, height: 13),
                          const SizedBox(height: 14),
                          // Progress bar placeholder
                          _bar(
                            color,
                            width: double.infinity,
                            height: 6,
                            radius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Section title ──────────────────────────────────────────
              _bar(color, width: 140, height: 18),
              const SizedBox(height: 16),

              // ── Horizontal song row ────────────────────────────────────
              _horizontalSongRow(color),
              const SizedBox(height: 32),

              // ── Section title ──────────────────────────────────────────
              _bar(color, width: 120, height: 18),
              const SizedBox(height: 16),

              // ── Second horizontal song row ─────────────────────────────
              _horizontalSongRow(color),
              const SizedBox(height: 32),

              // ── Section title ──────────────────────────────────────────
              _bar(color, width: 100, height: 18),
              const SizedBox(height: 16),

              // ── Favorites grid placeholder (2 wide cards) ──────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Reusable grey bar ──────────────────────────────────────────────────────
  Widget _bar(
    Color color, {
    required double width,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ── 3 song cards side by side ──────────────────────────────────────────────
  Widget _horizontalSongRow(Color color) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // NeverScrollableScrollPhysics so parent handles all scrolling
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art square
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            // Song title bar
            Container(
              width: 100,
              height: 13,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            // Artist bar
            Container(
              width: 70,
              height: 11,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

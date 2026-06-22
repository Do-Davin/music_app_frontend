import 'dart:async';

import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';

/// Premium dark-glass profile header card.
///
/// Shows a circular avatar (network image or initials/icon fallback),
/// the user's username, email, a profile-type badge and a short subtitle.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.username,
    required this.email,
    required this.profileType,
    this.avatarUrl,
  });

  final String username;
  final String email;
  final String profileType;
  final String? avatarUrl;

  bool get _isProfessional => profileType == User.professionalProfileType;

  String get _badgeLabel =>
      _isProfessional ? 'Professional Account' : 'Personal Account';

  String get _subtitle =>
      _isProfessional ? 'Practicing musician' : 'Music lover';

  @override
  Widget build(BuildContext context) {
    return _GradientGlassCard(
      isProfessional: _isProfessional,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
        child: Column(
          children: [
            _ProfileAvatar(username: username, avatarUrl: avatarUrl),
            const SizedBox(height: 16),
            Text(
              username,
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: AppTextStyles.body.copyWith(
                color: AppColors.hint,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            _ProfileTypeBadge(
              label: _badgeLabel,
              isProfessional: _isProfessional,
            ),
            const SizedBox(height: 10),
            Text(
              _subtitle,
              style: AppTextStyles.body.copyWith(
                color: AppColors.hint,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.username, this.avatarUrl});

  final String username;
  final String? avatarUrl;

  String get _initials {
    final cleaned = username.trim();
    if (cleaned.isEmpty) return '';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFFFFC04D)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: CircleAvatar(
        radius: 48,
        backgroundColor: AppColors.surface,
        backgroundImage: hasUrl ? NetworkImage(avatarUrl!) : null,
        onBackgroundImageError: hasUrl
            ? (exception, _) {
                debugPrint('[ProfileAvatar] Failed to load: $avatarUrl — $exception');
              }
            : null,
        child: hasUrl
            ? null
            : (_initials.isNotEmpty
                  ? Text(
                      _initials,
                      style: AppTextStyles.header.copyWith(
                        color: AppColors.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : const Icon(
                      Icons.music_note,
                      size: 44,
                      color: AppColors.primary,
                    )),
      ),
    );
  }
}

class _ProfileTypeBadge extends StatelessWidget {
  const _ProfileTypeBadge({required this.label, required this.isProfessional});

  final String label;
  final bool isProfessional;

  @override
  Widget build(BuildContext context) {
    final accent = isProfessional ? AppColors.primary : AppColors.hint;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isProfessional ? Icons.verified : Icons.person_outline,
            color: accent,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: accent,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientGlassCard extends StatefulWidget {
  const _GradientGlassCard({required this.isProfessional, required this.child});

  final bool isProfessional;
  final Widget child;

  @override
  State<_GradientGlassCard> createState() => _GradientGlassCardState();
}

class _GradientGlassCardState extends State<_GradientGlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _shineTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener(_handleAnimationStatus);

    if (widget.isProfessional) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _GradientGlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isProfessional != widget.isProfessional) {
      _shineTimer?.cancel();
      _controller.reset();
      if (widget.isProfessional) {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _shineTimer?.cancel();
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _controller.reset();
    _shineTimer?.cancel();
    _shineTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted || !widget.isProfessional) return;
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isProfessional
        ? AppColors.primary.withValues(alpha: 0.45)
        : AppColors.inputBorder;

    final base = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.card,
            AppColors.surface.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: widget.child,
    );

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: widget.isProfessional
          ? AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final value = _controller.value;
                final position = -1.3 + (value * 2.6);
                final opacityScale = value < 0.5
                    ? value * 2
                    : (1 - value) * 2;
                final peakAlpha = (0.05 * opacityScale.clamp(0.0, 1.0))
                    .toDouble();

                return Stack(
                  children: [
                    base,
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(
                                position - 0.45,
                                position - 0.45,
                              ),
                              end: Alignment(position + 0.45, position + 0.45),
                              colors: [
                                AppColors.primary.withValues(alpha: 0),
                                AppColors.primary.withValues(alpha: peakAlpha),
                                AppColors.primary.withValues(alpha: 0),
                              ],
                              stops: const [0.20, 0.50, 0.80],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          : base,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: card,
    );
  }
}

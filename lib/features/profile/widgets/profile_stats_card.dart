import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';

/// A single value/label/onTap entry for the stats row.
class ProfileStat {
  const ProfileStat({
    required this.label,
    required this.value,
    this.onTap,
    this.isLoading = false,
  });

  final String label;
  final int value;
  final VoidCallback? onTap;
  final bool isLoading;
}

/// Horizontal row of clickable stat columns (Friends / Followers / Following /
/// Playlists). Items with a null `onTap` render as static columns.
class ProfileStatsCard extends StatelessWidget {
  const ProfileStatsCard({super.key, required this.stats});

  final List<ProfileStat> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            Expanded(child: _StatColumn(stat: stats[i])),
            if (i != stats.length - 1) const _StatDivider(),
          ],
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.stat});

  final ProfileStat stat;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        children: [
          if (stat.isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            Text(
              _formatValue(stat.value),
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (stat.onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: stat.onTap,
      child: content,
    );
  }

  String _formatValue(int value) {
    if (value < 1000) return '$value';
    if (value < 1000000) {
      final v = value / 1000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}K';
    }
    final v = value / 1000000;
    return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}M';
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.inputBorder);
  }
}

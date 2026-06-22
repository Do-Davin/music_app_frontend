import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';

/// "Account" card with two navigation-style rows.
///
/// "Profile settings" was removed because it duplicated the main
/// "Edit profile" button. Two distinct actions remain:
///   - Account type (Personal / Professional, with upgrade path)
///   - Privacy & visibility (coming soon)
class ProfileAccountTools extends StatelessWidget {
  const ProfileAccountTools({
    super.key,
    required this.profileType,
    required this.onAccountType,
    required this.onPrivacy,
  });

  final String profileType;
  final VoidCallback onAccountType;
  final VoidCallback onPrivacy;

  String get _profileTypeLabel =>
      profileType == User.professionalProfileType ? 'Professional' : 'Personal';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          _ToolRow(
            icon: Icons.badge_outlined,
            label: 'Account type',
            trailingText: _profileTypeLabel,
            onTap: onAccountType,
          ),
          const _RowDivider(),
          _ToolRow(
            icon: Icons.lock_outline,
            label: 'Privacy & visibility',
            onTap: onPrivacy,
          ),
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.hint,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right, size: 20, color: AppColors.hint),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(height: 1, color: AppColors.inputBorder),
    );
  }
}

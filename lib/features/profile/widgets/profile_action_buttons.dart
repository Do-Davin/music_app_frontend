import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';

/// Single "Edit profile" action button shown below the stats card.
///
/// "Switch to Professional" has been moved exclusively into the Account Type
/// bottom sheet to avoid duplicating that action on the profile page.
class ProfileActionButtons extends StatelessWidget {
  const ProfileActionButtons({super.key, required this.onEditProfile});

  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onEditProfile,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.button,
        ),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Edit profile'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final profileType = user.profileType.trim();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Text(
          'Profile',
          style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 64,
                  backgroundColor: colorScheme.surface,
                  backgroundImage:
                      user.profileImageUrl != null &&
                          user.profileImageUrl!.isNotEmpty
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child:
                      user.profileImageUrl == null ||
                          user.profileImageUrl!.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 64,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.username,
                  style: AppTextStyles.header.copyWith(
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  user.email,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (profileType.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ProfileTypeBadge(profileType: profileType),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTypeBadge extends StatelessWidget {
  const _ProfileTypeBadge({required this.profileType});

  final String profileType;

  @override
  Widget build(BuildContext context) {
    final isProfessional = profileType == User.professionalProfileType;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isProfessional ? AppColors.primary : AppColors.inputBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isProfessional) ...[
            const Icon(Icons.verified, color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            isProfessional ? 'Professional Account' : profileType,
            style: AppTextStyles.body.copyWith(
              color: isProfessional ? AppColors.primary : AppColors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

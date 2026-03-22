import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';

class StatelessStatusScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String appBarTitle;
  final Color iconColor;
  final Color iconBackgroundColor;

  // NEW: the exact word in the title to highlight orange
  // e.g. for "No Playlists Yet" → highlightWord: 'Playlists'
  final String? highlightWord;

  // NEW: optional pill/badge text shown above the title
  // e.g. "0 results found" for the search empty state
  final String? badge;

  const StatelessStatusScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.appBarTitle = '',
    this.iconColor = AppColors.error,
    this.iconBackgroundColor = AppColors.errorBackground,
    this.highlightWord,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBarTitle.isNotEmpty
          ? AppBar(
              title: Text(
                appBarTitle,
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.primary,
                ),
              ),
              centerTitle: true,
              backgroundColor: AppColors.background,
              leading: IconButton(
                icon: const Icon(Icons.chevron_left, size: 28),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Double-ring circle effect matching Figma
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    // outer ring — very faint
                    color: iconColor.withValues(alpha: 0.15),
                    width: 12,
                  ),
                ),
                child: CircleAvatar(
                  radius: 63,
                  backgroundColor: iconBackgroundColor,
                  child: Icon(icon, size: 54, color: iconColor),
                ),
              ),

              const SizedBox(height: 28),

              // Optional badge pill — only shown when badge is provided
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    // dark olive/brown pill matching Figma
                    color: const Color(0xFF5C4A00),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Title with optional highlighted word
              _buildTitle(),

              const SizedBox(height: 10),

              Text(
                subtitle,
                style: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    // If no highlightWord, just render plain title
    if (highlightWord == null || !title.contains(highlightWord!)) {
      return Text(
        title,
        style: AppTextStyles.header.copyWith(fontSize: 24),
        textAlign: TextAlign.center,
      );
    }

    // Split title into 3 parts: before, the highlighted word, after
    final index = title.indexOf(highlightWord!);
    final before = title.substring(0, index); // e.g. "No "
    final highlight = highlightWord!; // e.g. "Playlists"
    final after = title.substring(index + highlight.length); // e.g. " Yet"

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTextStyles.header.copyWith(fontSize: 24),
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: highlight,
            style: AppTextStyles.header.copyWith(
              fontSize: 24,
              color: AppColors.primary, // always orange for highlight
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }
}

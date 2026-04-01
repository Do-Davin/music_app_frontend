import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/shared/widgets/app_primary_button.dart';

/// A reusable error widget shown when an API call fails or something goes wrong.
///
/// How to use:
///   AppErrorWidget(message: 'Failed to load songs')
///   AppErrorWidget(
///     message: 'No internet connection',
///     retryButtonText: 'Try Again',
///     onRetry: () => ref.refresh(songsProvider),
///   )
class AppErrorWidget extends StatelessWidget {
  /// The error message shown to the user (e.g. "Failed to load songs").
  final String message;

  /// Text on the retry button. Defaults to 'Try Again'.
  /// Only shown if [onRetry] is also provided.
  final String? retryButtonText;

  /// Callback when the user taps the retry button.
  /// If null, no retry button is shown.
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.retryButtonText = 'Try Again',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon inside a soft red circular background
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: AppColors.error,
              ),
            ),

            const SizedBox(height: 20),

            // Error title
            Text(
              'Something went wrong',
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.onSurface,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // The specific error message passed in by the caller
            Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            // Only show the retry button if a callback was provided
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 180,
                child: AppPrimaryButton(
                  label: retryButtonText ?? 'Try Again',
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

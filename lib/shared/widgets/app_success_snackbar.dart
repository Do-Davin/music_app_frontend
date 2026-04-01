import 'package:flutter/material.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';

/// Shows a floating success snackbar at the bottom of the screen.
///
/// How to use:
///   // Simple success message
///   showSuccessSnackbar(context, message: 'Song added successfully!');
///
///   // With an Undo button
///   showSuccessSnackbar(
///     context,
///     message: 'Song deleted',
///     undoLabel: 'Undo',
///     onUndo: () => restoreSong(),
///   );
void showSuccessSnackbar(
  BuildContext context, {
  required String message,

  /// Optional label for the action button (e.g. 'Undo').
  String? undoLabel,

  /// Callback when the user taps the action button.
  VoidCallback? onUndo,

  /// How long the snackbar stays visible. Defaults to 4 seconds.
  Duration duration = const Duration(seconds: 4),
}) {
  // Remove any existing snackbar first to avoid stacking
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      // The content row: checkmark icon + message text
      content: Row(
        children: [
          // Small green checkmark icon to signal success visually
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.green,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // The message text — flexible so it wraps if long
          Flexible(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF2E2E2E), // dark card surface
      behavior: SnackBarBehavior.floating, // floats above bottom nav
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // padding from edges
      duration: duration,
      // Only show action if both label and callback are provided
      action: (undoLabel != null && onUndo != null)
          ? SnackBarAction(
              label: undoLabel,
              textColor: AppColors.primary, // orange to match app accent
              onPressed: onUndo,
            )
          : null,
    ),
  );
}

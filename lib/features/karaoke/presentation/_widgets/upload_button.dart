import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/karaoke_controller.dart';

class UploadButton extends StatelessWidget {
  const UploadButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<KaraokeController>(
      builder: (context, controller, _) {
        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: controller.isLoading
                ? null
                : () => _showAddOptions(context),
            icon: controller.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.add, size: 28),
            label: Text(
              controller.isLoading ? 'Loading...' : 'Add Song',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[800],
              elevation: controller.isLoading ? 0 : 8,
              shadowColor: controller.isLoading
                  ? Colors.transparent
                  : const Color(0xFF7C4DFF).withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddOptions(BuildContext context) {
    // This is handled by the screen, button just triggers
    // The actual implementation is in KaraokeHomeScreen
  }
}

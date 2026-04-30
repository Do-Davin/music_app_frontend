import 'package:flutter/material.dart';

class LyricLine extends StatelessWidget {
  final String text;
  final bool isActive;
  final double height;

  const LyricLine({
    super.key,
    required this.text,
    required this.isActive,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: isActive ? 26 : 18,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
              height: 1.4,
              letterSpacing: isActive ? 0.5 : 0,
              shadows: isActive
                  ? [
                      Shadow(
                        color: const Color(0xFF7C4DFF)
                            .withValues(alpha: 0.6),
                        blurRadius: 24,
                        offset: const Offset(0, 4),
                      ),
                      Shadow(
                        color: const Color(0xFF7C4DFF)
                            .withValues(alpha: 0.3),
                        blurRadius: 48,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

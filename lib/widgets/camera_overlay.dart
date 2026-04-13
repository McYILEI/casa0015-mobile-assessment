import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CameraOverlay extends StatelessWidget {
  final String elapsed;
  final int setNumber;
  final bool paused;

  const CameraOverlay({
    super.key,
    required this.elapsed,
    required this.setNumber,
    this.paused = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (paused)
          Container(color: Colors.black.withAlpha(140)),
        // Top-left timer
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: AppColors.accent, size: 14),
                const SizedBox(width: 4),
                Text(
                  elapsed,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Top-right set number
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Set $setNumber',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (paused)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pause_circle_outline,
                    color: AppColors.text, size: 56),
                SizedBox(height: 8),
                Text(
                  'Paused',
                  style: TextStyle(color: AppColors.text, fontSize: 18),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

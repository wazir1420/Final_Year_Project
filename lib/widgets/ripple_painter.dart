import 'package:flutter/material.dart';

/// Draws up to 5 expanding ripple rings, each offset by [rippleSpacing].
/// [progress] drives a single looping animation (0→1).
class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int count;
  final double spacing; // px between ring radii

  const RipplePainter({
    required this.progress,
    this.color = const Color(0xFF2563EB),
    this.count = 5,
    this.spacing = 70,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < count; i++) {
      // Each ring is staggered by (i / count) within the 0→1 cycle
      final offset = i / count;
      final t = (progress + offset) % 1.0;

      // Radius grows from 45 to maxR over t=0→1
      final maxR = spacing * count * 0.8;
      final r = 45.0 + t * maxR;

      // Opacity: fade in quickly, hold, fade out near end
      final opacity = t < 0.15
          ? (t / 0.15) * 0.55
          : t < 0.7
          ? 0.55 * (1 - (t - 0.15) / 0.85)
          : 0.0;

      if (opacity <= 0) continue;

      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = color.withAlpha((opacity * 255).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(RipplePainter old) => old.progress != progress;
}

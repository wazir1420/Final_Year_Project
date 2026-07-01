import 'dart:math';
import 'package:flutter/material.dart';

/// Draws a spinning arc ring around the logo mark.
/// [angle] drives a full 2π rotation from AnimationController.
class ArcRingPainter extends CustomPainter {
  final double angle;

  const ArcRingPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 54.0;

    // Faint full circle track
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = const Color.fromRGBO(37, 99, 235, 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Bright arc — 110° sweep, rotated by [angle]
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(
      rect,
      angle,
      110 * pi / 180,
      false,
      Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    // Dim trailing arc — 60° just behind the bright one
    canvas.drawArc(
      rect,
      angle + 110 * pi / 180,
      60 * pi / 180,
      false,
      Paint()
        ..color = const Color.fromRGBO(37, 99, 235, 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );

    // Leading dot
    final dotX = cx + r * cos(angle);
    final dotY = cy + r * sin(angle);
    canvas.drawCircle(
      Offset(dotX, dotY),
      3,
      Paint()..color = const Color(0xFF60A5FA),
    );

    // Trailing dot
    final tAngle = angle + 110 * pi / 180;
    final tdX = cx + r * cos(tAngle);
    final tdY = cy + r * sin(tAngle);
    canvas.drawCircle(
      Offset(tdX, tdY),
      2,
      Paint()..color = const Color.fromRGBO(37, 99, 235, 0.4),
    );
  }

  @override
  bool shouldRepaint(ArcRingPainter old) => old.angle != angle;
}

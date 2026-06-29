import 'dart:math';
import 'package:flutter/material.dart';

class LogoPainter extends CustomPainter {
  final double arcProgress; // 0.0 → 1.0 (ring draws in)
  final double barsProgress; // 0.0 → 1.0 (bars rise up)
  final double lineProgress; // 0.0 → 1.0 (trend line draws)
  final double boltProgress; // 0.0 → 1.0 (bolt fades in)

  LogoPainter({
    required this.arcProgress,
    required this.barsProgress,
    required this.lineProgress,
    required this.boltProgress,
  });

  static const Color navy = Color(0xFF1E3A8A);
  static const Color indigo = Color(0xFF6366F1);
  static const Color blue1 = Color(0xFF93C5FD);
  static const Color blue2 = Color(0xFF6366F1);
  static const Color blue3 = Color(0xFF4338CA);
  static const Color amber = Color(0xFFFCD34D);
  static const Color ringBg = Color(0xFFE0E7FF);
  static const Color inner = Color(0xFFF8FAFF);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const r = 100.0;

    // ── Outer thin ring ──────────────────────────────────────────
    final ringPaint = Paint()
      ..color = ringBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), r, ringPaint);

    // ── Progress arc (navy, 270°) ─────────────────────────────────
    final arcPaint = Paint()
      ..color = navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    // start at -90° (top), sweep 270° clockwise
    canvas.drawArc(
      arcRect,
      -pi / 2,
      (3 * pi / 2) * arcProgress,
      false,
      arcPaint,
    );

    // Remaining arc (subtle)
    if (arcProgress >= 1.0) {
      final gapPaint = Paint()
        ..color = ringBg
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(arcRect, pi, pi / 2, false, gapPaint);
    }

    // ── Inner circle fill ─────────────────────────────────────────
    canvas.drawCircle(Offset(cx, cy), 80, Paint()..color = inner);

    // ── Bar chart ─────────────────────────────────────────────────
    final barData = [
      (cx - 44, blue1, 22.0),
      (cx - 26, blue2, 36.0),
      (cx - 8, blue3, 52.0),
      (cx + 10, navy, 62.0),
    ];

    final barBottom = cy + 32.0;

    for (final (x, color, fullH) in barData) {
      final h = fullH * barsProgress;
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, barBottom - h, 12, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(rr, Paint()..color = color);
    }

    // ── Trend line + dots ─────────────────────────────────────────
    final trendPoints = [
      Offset(cx - 38, barBottom - 22),
      Offset(cx - 20, barBottom - 36),
      Offset(cx - 2, barBottom - 52),
      Offset(cx + 16, barBottom - 62),
    ];

    if (lineProgress > 0) {
      final linePaint = Paint()
        ..color = amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      final totalSegments = trendPoints.length - 1;

      for (int i = 0; i < totalSegments; i++) {
        final segStart = i / totalSegments;
        final segEnd = (i + 1) / totalSegments;

        if (lineProgress <= segStart) break;

        final p1 = trendPoints[i];
        final p2 = trendPoints[i + 1];

        if (i == 0) path.moveTo(p1.dx, p1.dy);

        final t = ((lineProgress - segStart) / (segEnd - segStart)).clamp(
          0.0,
          1.0,
        );
        path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
      }
      canvas.drawPath(path, linePaint);

      // Dots
      final dotPaint = Paint()..color = amber;
      for (int i = 0; i < trendPoints.length; i++) {
        final threshold = i / (trendPoints.length - 1);
        if (lineProgress >= threshold) {
          canvas.drawCircle(trendPoints[i], 3.5, dotPaint);
        }
      }
    }

    // ── Lightning bolt (top-right of circle) ─────────────────────
    if (boltProgress > 0) {
      final boltPaint = Paint()
        // ignore: deprecated_member_use
        ..color = navy.withOpacity(boltProgress)
        ..style = PaintingStyle.fill;

      final bx = cx + 34.0;
      final by = cy - 76.0;

      final boltPath = Path()
        ..moveTo(bx + 4, by)
        ..lineTo(bx - 6, by + 22)
        ..lineTo(bx + 1, by + 22)
        ..lineTo(bx - 8, by + 42)
        ..lineTo(bx + 8, by + 16)
        ..lineTo(bx + 0, by + 16)
        ..close();

      canvas.drawPath(boltPath, boltPaint);
    }

    // ── Arc endpoint dots ─────────────────────────────────────────
    if (arcProgress >= 1.0) {
      canvas.drawCircle(Offset(cx, cy - r), 5, Paint()..color = navy);
      canvas.drawCircle(Offset(cx - r, cy), 5, Paint()..color = indigo);
    }
  }

  @override
  bool shouldRepaint(LogoPainter old) =>
      old.arcProgress != arcProgress ||
      old.barsProgress != barsProgress ||
      old.lineProgress != lineProgress ||
      old.boltProgress != boltProgress;
}

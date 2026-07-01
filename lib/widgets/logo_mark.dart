import 'package:flutter/material.dart';
import 'arc_ring_painter.dart';

class LogoMark extends StatelessWidget {
  final Animation<double> arcAngle;
  final Animation<double> pulseScale;

  const LogoMark({super.key, required this.arcAngle, required this.pulseScale});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring behind everything
          AnimatedBuilder(
            animation: pulseScale,
            builder: (context, child) => Transform.scale(
              scale: pulseScale.value,
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color.fromRGBO(96, 165, 250, 0.18),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),

          // Spinning arc ring
          AnimatedBuilder(
            animation: arcAngle,
            builder: (context, child) => CustomPaint(
              size: const Size(148, 148),
              painter: ArcRingPainter(angle: arcAngle.value),
            ),
          ),

          // Inner rounded square card
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(37, 99, 235, 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color.fromRGBO(96, 165, 250, 0.35),
                width: 1.5,
              ),
            ),
            child: const _BoltIcon(),
          ),
        ],
      ),
    );
  }
}

// ── Lightning bolt + analytics bars icon ──────────────────────────────────────
class _BoltIcon extends StatelessWidget {
  const _BoltIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BoltPainter());
  }
}

class _BoltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── Lightning bolt ───────────────────────────────────────────────────────
    final boltPath = Path()
      ..moveTo(cx + 4, cy - 18) // top point
      ..lineTo(cx - 8, cy + 2) // mid-left
      ..lineTo(cx, cy + 2) // mid notch
      ..lineTo(cx - 4, cy + 18) // bottom point
      ..lineTo(cx + 8, cy - 2) // mid-right
      ..lineTo(cx, cy - 2) // mid notch
      ..close();

    // White fill
    canvas.drawPath(boltPath, Paint()..color = Colors.white);

    // Blue stroke
    canvas.drawPath(
      boltPath,
      Paint()
        ..color = const Color(0xFF93C5FD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Mini bar chart — left side ────────────────────────────────────────────
    final barPaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;

    final dimPaint = Paint()
      ..color = const Color.fromRGBO(59, 130, 246, 0.4)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;

    // Left bars
    canvas.drawLine(
      Offset(cx - 22, cy + 6),
      Offset(cx - 22, cy + 14),
      barPaint,
    );
    canvas.drawLine(
      Offset(cx - 18, cy + 2),
      Offset(cx - 18, cy + 14),
      dimPaint,
    );

    // Right bars
    canvas.drawLine(
      Offset(cx + 18, cy + 4),
      Offset(cx + 18, cy + 14),
      barPaint,
    );
    canvas.drawLine(
      Offset(cx + 22, cy + 8),
      Offset(cx + 22, cy + 14),
      dimPaint,
    );

    // ── Tiny dots — upper corners ─────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx - 22, cy - 14),
      1.5,
      Paint()..color = const Color.fromRGBO(96, 165, 250, 0.6),
    );
    canvas.drawCircle(
      Offset(cx + 22, cy - 18),
      1.5,
      Paint()..color = const Color.fromRGBO(96, 165, 250, 0.6),
    );

    // ── Micro trend line — upper left ─────────────────────────────────────────
    final trendPath = Path()
      ..moveTo(cx - 26, cy - 8)
      ..quadraticBezierTo(cx - 20, cy - 14, cx - 14, cy - 10);

    canvas.drawPath(
      trendPath,
      Paint()
        ..color = const Color.fromRGBO(59, 130, 246, 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BoltPainter oldDelegate) => false;
}

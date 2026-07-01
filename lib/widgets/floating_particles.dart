import 'package:flutter/material.dart';

class FloatingParticles extends StatelessWidget {
  final Animation<double> animation;

  const FloatingParticles({super.key, required this.animation});

  static const _specs = [
    _ParticleSpec(
      top: 0.22,
      left: 0.14,
      size: 2.0,
      delay: 0.0,
      color: Color(0xFF60A5FA),
    ),
    _ParticleSpec(
      top: 0.38,
      left: 0.88,
      size: 3.0,
      delay: 0.2,
      color: Color(0xFF93C5FD),
    ),
    _ParticleSpec(
      top: 0.68,
      left: 0.16,
      size: 2.0,
      delay: 0.4,
      color: Color(0xFF3B82F6),
    ),
    _ParticleSpec(
      top: 0.62,
      left: 0.82,
      size: 2.0,
      delay: 0.6,
      color: Color(0xFF60A5FA),
    ),
    _ParticleSpec(
      top: 0.15,
      left: 0.78,
      size: 3.0,
      delay: 0.15,
      color: Color(0xFFBFDBFE),
    ),
    _ParticleSpec(
      top: 0.80,
      left: 0.55,
      size: 2.0,
      delay: 0.5,
      color: Color(0xFF93C5FD),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) => Stack(
        children: _specs.map((s) {
          final t = ((animation.value + s.delay) % 1.0);
          final opacity = t < 0.25
              ? t / 0.25 * 0.7
              : t < 0.75
              ? 0.7 * (1 - (t - 0.25) / 0.75)
              : 0.0;
          final dy = -20.0 * t;

          return Positioned(
            top: MediaQuery.of(context).size.height * s.top + dy,
            left: MediaQuery.of(context).size.width * s.left,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: s.size,
                height: s.size,
                decoration: BoxDecoration(
                  color: s.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ParticleSpec {
  final double top, left, size, delay;
  final Color color;
  const _ParticleSpec({
    required this.top,
    required this.left,
    required this.size,
    required this.delay,
    required this.color,
  });
}

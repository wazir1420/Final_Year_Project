import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../widgets/ripple_painter.dart';
import '../widgets/logo_mark.dart';
import '../widgets/floating_particles.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _rippleCtrl; // ripple wave loop
  late final AnimationController _arcCtrl; // spinning arc loop
  late final AnimationController _pulseCtrl; // pulse ring loop
  late final AnimationController _entryCtrl; // one-shot entry sequence
  late final AnimationController _loaderCtrl; // loader bar one-shot
  late final AnimationController _particleCtrl; // floating dots loop

  // ── Entry sequence animations ──────────────────────────────────────────────
  late final Animation<double> _markScale;
  late final Animation<double> _markOpacity;
  late final Animation<double> _markRotate;

  late final Animation<double> _brandSlide;
  late final Animation<double> _brandOpacity;

  late final Animation<double> _pillsOpacity;
  late final Animation<double> _loaderWidth;

  // ── Loop animations ────────────────────────────────────────────────────────
  late final Animation<double> _arcAngle;
  late final Animation<double> _pulseScale;

  // ── Colours ────────────────────────────────────────────────────────────────
  static const kNavy = Color(0xFF0B1929);

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();
    _startAnimations();
  }

  void _setupControllers() {
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    _arcCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5800),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _loaderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  void _setupAnimations() {
    // ── Logo mark: scale bounce in ───────────────────────────────────────────
    _markScale =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 0.3,
              end: 1.1,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 70,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 1.1,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInOut)),
            weight: 30,
          ),
        ]).animate(
          CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.5)),
        );

    _markOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.3)),
    );

    _markRotate = Tween(begin: -0.08, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // ── Brand text: slide up ─────────────────────────────────────────────────
    _brandSlide = Tween(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
      ),
    );
    _brandOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.3, 0.65)),
    );

    // ── Pills + loader ───────────────────────────────────────────────────────
    _pillsOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.6, 0.9)),
    );

    _loaderWidth = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loaderCtrl,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    // ── Arc ring: full 2π rotation ───────────────────────────────────────────
    _arcAngle = Tween(begin: 0.0, end: 6.2832).animate(_arcCtrl);

    // ── Pulse ring: scale 1.0 → 1.06 ────────────────────────────────────────
    _pulseScale = Tween(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _entryCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    _loaderCtrl.forward();

    // Ensure the app leaves the splash screen after the loader animation.
    Future.delayed(const Duration(milliseconds: 3600), () {
      if (mounted) {
        Get.offAllNamed(AppRoutes.dashboard);
      }
    });
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    _arcCtrl.dispose();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _loaderCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: Stack(
        children: [
          // ── Background grid (very faint) ────────────────────────────────────
          Positioned.fill(child: _GridBackground()),

          // ── Floating particles ───────────────────────────────────────────────
          Positioned.fill(child: FloatingParticles(animation: _particleCtrl)),

          // ── Ripple waves ─────────────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rippleCtrl,
              builder: (context, child) => CustomPaint(
                painter: RipplePainter(progress: _rippleCtrl.value),
              ),
            ),
          ),

          // ── Corner accents ───────────────────────────────────────────────────
          ..._cornerAccents(),

          // ── Main content ─────────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark
                AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (context, child) => Opacity(
                    opacity: _markOpacity.value,
                    child: Transform.rotate(
                      angle: _markRotate.value,
                      child: Transform.scale(
                        scale: _markScale.value,
                        alignment: Alignment.center,
                        child: LogoMark(
                          arcAngle: _arcAngle,
                          pulseScale: _pulseScale,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Brand name + tagline
                AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (context, child) => Opacity(
                    opacity: _brandOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _brandSlide.value),
                      child: _BrandText(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Divider line
                AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (context, child) => Opacity(
                    opacity: _pillsOpacity.value,
                    child: Container(
                      width: 48,
                      height: 1,
                      color: const Color.fromRGBO(96, 165, 250, 0.25),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Feature pills
                AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (context, child) => Opacity(
                    opacity: _pillsOpacity.value,
                    child: _FeaturePills(),
                  ),
                ),

                const SizedBox(height: 24),

                // Loader bar
                AnimatedBuilder(
                  animation: _loaderCtrl,
                  builder: (context, child) => Opacity(
                    opacity: _pillsOpacity.value,
                    child: _LoaderBar(progress: _loaderWidth.value),
                  ),
                ),
              ],
            ),
          ),

          // ── Version tag ───────────────────────────────────────────────────────
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _entryCtrl,
              builder: (context, child) => Opacity(
                opacity: _pillsOpacity.value,
                child: const Text(
                  'PowerInsight · FYP 2026',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Corner accent brackets ─────────────────────────────────────────────────
  List<Widget> _cornerAccents() => [
    _Corner(
      top: 30,
      left: 30,
      border: const Border(
        top: BorderSide(color: Color(0xFF60A5FA), width: 1.5),
        left: BorderSide(color: Color(0xFF60A5FA), width: 1.5),
      ),
    ),
    _Corner(
      top: 30,
      right: 30,
      border: const Border(
        top: BorderSide(color: Color(0xFF60A5FA), width: 1.5),
        right: BorderSide(color: Color(0xFF60A5FA), width: 1.5),
      ),
    ),
    _Corner(
      bottom: 30,
      left: 30,
      border: const Border(
        bottom: BorderSide(color: Color(0xFF60A5FA), width: 1.5),
        left: BorderSide(color: Color(0xFF60A5FA), width: 1.5),
      ),
    ),
    _Corner(
      bottom: 30,
      right: 30,
      border: const Border(
        bottom: BorderSide(color: Color(0xFF60A5FA), width: 1.5),
        right: BorderSide(color: Color(0xFF60A5FA), width: 1.5),
      ),
    ),
  ];
}

// ── Brand text widget ─────────────────────────────────────────────────────────
class _BrandText extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Power',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            TextSpan(
              text: 'Insight',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xFF60A5FA),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'SMART ENERGY ANALYTICS',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.8,
        ),
      ),
    ],
  );
}

// ── Feature pills ─────────────────────────────────────────────────────────────
class _FeaturePills extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Pill(dotColor: const Color(0xFF10B981), label: 'Live monitoring'),
      const SizedBox(width: 10),
      _Pill(dotColor: const Color(0xFF60A5FA), label: 'ML predictions'),
    ],
  );
}

class _Pill extends StatelessWidget {
  final Color dotColor;
  final String label;
  const _Pill({required this.dotColor, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: const Color.fromRGBO(37, 99, 235, 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color.fromRGBO(59, 130, 246, 0.25),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}

// ── Loader bar ────────────────────────────────────────────────────────────────
class _LoaderBar extends StatelessWidget {
  final double progress;
  const _LoaderBar({required this.progress});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 120,
    height: 2,
    child: Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.07),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Corner accent ─────────────────────────────────────────────────────────────
class _Corner extends StatelessWidget {
  final double? top, left, right, bottom;
  final Border border;
  const _Corner({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.border,
  });

  @override
  Widget build(BuildContext context) => Positioned(
    top: top,
    left: left,
    right: right,
    bottom: bottom,
    child: Opacity(
      opacity: 0.2,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(border: border),
      ),
    ),
  );
}

// ── Background grid ───────────────────────────────────────────────────────────
class _GridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GridPainter());
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(30, 58, 95, 0.35)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../painters/logo_painter.dart';
import '../routes/app_routes.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  // Four staged animations
  late final AnimationController _arcCtrl;
  late final AnimationController _barsCtrl;
  late final AnimationController _lineCtrl;
  late final AnimationController _boltCtrl;
  late final AnimationController _wordmarkCtrl;

  late final Animation<double> _arc;
  late final Animation<double> _bars;
  late final Animation<double> _line;
  late final Animation<double> _bolt;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkSlide;

  @override
  void initState() {
    super.initState();

    _arcCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _boltCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wordmarkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _arc = CurvedAnimation(parent: _arcCtrl, curve: Curves.easeInOut);
    _bars = CurvedAnimation(parent: _barsCtrl, curve: Curves.easeOut);
    _line = CurvedAnimation(parent: _lineCtrl, curve: Curves.easeInOut);
    _bolt = CurvedAnimation(parent: _boltCtrl, curve: Curves.easeIn);

    _wordmarkOpacity = CurvedAnimation(
      parent: _wordmarkCtrl,
      curve: Curves.easeIn,
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _wordmarkCtrl, curve: Curves.easeOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _arcCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _barsCtrl.forward();
    _lineCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _boltCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    await _wordmarkCtrl.forward();

    // Navigate to dashboard after splash
    await Future.delayed(const Duration(milliseconds: 800));
    Get.offNamed(AppRoutes.dashboard);
  }

  @override
  void dispose() {
    _arcCtrl.dispose();
    _barsCtrl.dispose();
    _lineCtrl.dispose();
    _boltCtrl.dispose();
    _wordmarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Animated logo mark ──────────────────────────────
            AnimatedBuilder(
              animation: Listenable.merge([
                _arcCtrl,
                _barsCtrl,
                _lineCtrl,
                _boltCtrl,
              ]),
              builder: (_, _) => CustomPaint(
                size: const Size(240, 240),
                painter: LogoPainter(
                  arcProgress: _arc.value,
                  barsProgress: _bars.value,
                  lineProgress: _line.value,
                  boltProgress: _bolt.value,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Wordmark ────────────────────────────────────────
            FadeTransition(
              opacity: _wordmarkOpacity,
              child: SlideTransition(
                position: _wordmarkSlide,
                child: Column(
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Power',
                            style: TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A8A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'Insight',
                            style: TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'SMART ENERGY MONITORING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:get/get.dart';

class SplashController extends GetxController {
  // ── Navigation ─────────────────────────────────────────────────────────────
  // Total splash duration before navigating to dashboard.
  // Adjust to match your animation length (loader fills at ~3.4s total).
  static const _splashDuration = Duration(milliseconds: 3600);

  @override
  void onInit() {
    super.onInit();
    _navigateAfterDelay();
  }

  void _navigateAfterDelay() {
    Future.delayed(_splashDuration, () {
      Get.offAllNamed('/dashboard');
    });
  }
}

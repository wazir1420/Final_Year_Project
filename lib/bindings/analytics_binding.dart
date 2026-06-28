// ─────────────────────────────────────────────────────────────
// lib/bindings/analytics_binding.dart
// ─────────────────────────────────────────────────────────────
import 'package:get/get.dart';
import '../controllers/analytics_controller.dart';

class AnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnalyticsController>(() => AnalyticsController());
  }
}

// ─────────────────────────────────────────────────────────────
// Add this GetPage to your existing AppRoutes.pages list:
// ─────────────────────────────────────────────────────────────
//
// GetPage(
//   name: '/analytics',
//   page: () => const AnalyticsView(),
//   binding: AnalyticsBinding(),
//   transition: Transition.rightToLeft,
// ),

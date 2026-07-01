import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
  }
}

// ─────────────────────────────────────────────────────────────
// Update your AppRoutes — add splash as the FIRST route
// and set initialRoute to '/splash':
// ─────────────────────────────────────────────────────────────
//
// static const splash    = '/splash';
// static const dashboard = '/dashboard';
//
// static final pages = [
//   GetPage(
//     name: splash,
//     page: () => const SplashView(),
//     binding: SplashBinding(),
//     transition: Transition.fadeIn,
//   ),
//   GetPage(
//     name: dashboard,
//     page: () => const DashboardView(),
//     binding: DashboardBinding(),
//     transition: Transition.fadeIn,    // smooth fade from splash
//   ),
//   // ... rest of your routes
// ];
//
// In GetMaterialApp:
//   initialRoute: AppRoutes.splash,

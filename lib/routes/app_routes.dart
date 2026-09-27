import 'package:finalyearproject/views/splash_view.dart';
import 'package:get/get.dart';

import '../bindings/splash_binding.dart';
import '../bindings/analytics_binding.dart';
import '../bindings/bills_binding.dart';
import '../bindings/settings_binding.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/meters_list_controller.dart';
import '../views/analytics_view.dart';
import '../views/bills_view.dart';
import '../views/dashboard_view.dart';
import '../views/meters_list_view.dart';
import '../views/ml_prediction_view.dart';
import '../views/settings_view.dart';

class AppRoutes {
  static const splash = '/splash';
  static const dashboard = '/dashboard';
  static const meters = '/meters';
  static const analytics = '/analytics';
  static const bills = '/bills';
  static const settings = '/settings';
  static const mlPrediction = '/ml-prediction';

  static final pages = [
    GetPage(
      name: splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: meters,
      page: () => const MetersListView(),
      binding: BindingsBuilder(() {
        Get.put(MetersListController());
      }),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: dashboard,
      page: () => const DashboardView(),
      binding: BindingsBuilder(() {
        final args = (Get.arguments as Map?) ?? {};
        final meterId = args['meterId']?.toString() ?? 'meter1';
        final meterName = args['meterName']?.toString() ?? '';

        // Purana controller (kisi aur meter ka ya khaali naam wala) zinda ho
        // to pehle hata dein, warna Get.put naya wala ignore kar deta hai.
        if (Get.isRegistered<DashboardController>()) {
          Get.delete<DashboardController>(force: true);
        }
        Get.put(DashboardController(meterId: meterId, meterName: meterName));
      }),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: analytics,
      page: () => const AnalyticsView(),
      binding: AnalyticsBinding(),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: bills,
      page: () => const BillsView(),
      binding: BillsBinding(),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: mlPrediction,
      page: () => const MlPredictionView(),
      transition: Transition.fadeIn,
    ),
  ];
}

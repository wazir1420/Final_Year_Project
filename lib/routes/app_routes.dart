import 'package:get/get.dart';

import '../bindings/dashboard_binding.dart';
import '../bindings/analytics_binding.dart';
import '../bindings/bills_binding.dart';
import '../views/analytics_view.dart';
import '../views/bills_view.dart';
import '../views/dashboard_view.dart';
import '../views/ml_prediction_view.dart';
import '../views/settings_view.dart';

class AppRoutes {
  static const dashboard = '/dashboard';

  static const analytics = '/analytics';

  static const bills = '/bills';

  static const settings = '/settings';

  static const mlPrediction = '/ml-prediction';

  static final pages = [
    GetPage(
      name: dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
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
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: mlPrediction,
      page: () => const MlPredictionView(),
      transition: Transition.fadeIn,
    ),
  ];
}

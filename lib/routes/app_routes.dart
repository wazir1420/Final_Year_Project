import 'package:finalyearproject/views/add_customer_view.dart';
import 'package:finalyearproject/views/splash_view.dart';
import 'package:get/get.dart';

import '../bindings/splash_binding.dart';
import '../bindings/analytics_binding.dart';
import '../bindings/bills_binding.dart';
import '../bindings/settings_binding.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/device_control_controller.dart';
import '../controllers/meters_list_controller.dart';
import '../controllers/login_controller.dart';
import '../controllers/admin_controller.dart';
import '../controllers/profile_controller.dart';
import '../views/analytics_view.dart';
import '../views/bills_view.dart';
import '../views/dashboard_view.dart';
import '../views/device_control_view.dart';
import '../views/meters_list_view.dart';
import '../views/ml_prediction_view.dart';
import '../views/settings_view.dart';
import '../views/login_view.dart';
import '../views/admin_panel_view.dart';
import '../views/profile_view.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const deviceControl = '/device-control';
  static const meters = '/meters';
  static const metersList =
      meters; // alias, taake login_controller mein naam match ho
  static const adminPanel = '/admin-panel';
  static const addCustomer = '/add-customer';
  static const analytics = '/analytics';
  static const bills = '/bills';
  static const settings = '/settings';
  static const profile = '/profile';
  static const mlPrediction = '/ml-prediction';

  static final pages = [
    GetPage(
      name: splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        if (Get.isRegistered<LoginController>()) {
          Get.delete<LoginController>(force: true);
        }
        Get.put(LoginController());
      }),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: adminPanel,
      page: () => const AdminPanelView(),
      binding: BindingsBuilder(() {
        if (Get.isRegistered<AdminController>()) {
          Get.delete<AdminController>(force: true);
        }
        Get.put(AdminController());
      }),
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
        final userName = args['userName']?.toString() ?? '';
        final userEmail = args['userEmail']?.toString() ?? '';
        final meterIds = (args['meterIds'] as List?)
            ?.whereType<String>()
            .toList();

        // Purana controller (kisi aur meter ka ya khaali naam wala) zinda ho
        // to pehle hata dein, warna Get.put naya wala ignore kar deta hai.
        if (Get.isRegistered<DashboardController>()) {
          Get.delete<DashboardController>(force: true);
        }
        Get.put(
          DashboardController(
            meterId: meterId,
            meterName: meterName,
            userName: userName,
            userEmail: userEmail,
            assignedMeterIds: meterIds,
          ),
        );
      }),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: deviceControl,
      page: () => const DeviceControlView(),
      binding: BindingsBuilder(() {
        Get.put(DeviceControlController());
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: addCustomer,
      page: () => const AddCustomerView(),
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
      name: profile,
      page: () => const ProfileView(),
      binding: BindingsBuilder(() {
        Get.put(ProfileController());
      }),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: mlPrediction,
      page: () => const MlPredictionView(),
      transition: Transition.fadeIn,
    ),
  ];
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dashboard_controller.dart';
import 'theme_controller.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/firebase_meters_list_service.dart';

class SettingsController extends GetxController {
  // Account summary — swap these for your AuthController / ProfileController
  // once that's wired up, e.g. Get.find<ProfileController>().name
  final userName = ''.obs;
  final userEmail = ''.obs;

  // Alerts
  final billThresholdAlert = true.obs;
  final highPowerAlert = true.obs;
  final dailySummary = false.obs;

  // Meter & connection
  final meterModel = 'Loading...'.obs;
  final isFirebaseConnected = false.obs;
  final AuthService _authService = AuthService();
  final FirebaseMetersListService _metersService = FirebaseMetersListService();
  Worker? _connectionStatusWorker;

  // App preferences
  final isDarkMode = false.obs;
  final language = 'English'.obs;
  final currency = 'PKR'.obs;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    final routeName = arguments is Map
        ? arguments['userName']?.toString().trim()
        : null;
    if (routeName != null && routeName.isNotEmpty) userName.value = routeName;
    final routeEmail = arguments is Map
        ? arguments['userEmail']?.toString().trim()
        : null;
    if (routeEmail != null && routeEmail.isNotEmpty) {
      userEmail.value = routeEmail;
    }
    if (Get.isRegistered<DashboardController>()) {
      final dashboardController = Get.find<DashboardController>();
      isFirebaseConnected.value = dashboardController.isMeterOnline.value;
      _connectionStatusWorker = ever(
        dashboardController.isMeterOnline,
        (isOnline) => isFirebaseConnected.value = isOnline,
      );
    }

    // initialize from global ThemeController so state stays in sync
    final themeCtrl = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController());
    isDarkMode.value = themeCtrl.isDark;
    _loadMeterModel();
  }

  @override
  void onClose() {
    _connectionStatusWorker?.dispose();
    super.onClose();
  }

  void toggleBillThresholdAlert(bool value) => billThresholdAlert.value = value;

  void toggleHighPowerAlert(bool value) => highPowerAlert.value = value;

  void toggleDailySummary(bool value) => dailySummary.value = value;

  void toggleDarkMode(bool value) {
    isDarkMode.value = value;
    // route theme changes through the global ThemeController (create if missing)
    final themeCtrl = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController());
    themeCtrl.isDark = value;
  }

  void goToProfile() => Get.toNamed('/profile');

  List<String> get _assignedMeterIds {
    final routeArguments = Get.arguments;
    final routeMeterIds = routeArguments is Map
        ? routeArguments['meterIds']
        : null;
    if (routeMeterIds is Iterable) {
      return routeMeterIds.whereType<String>().toList();
    }
    if (Get.isRegistered<DashboardController>()) {
      return Get.find<DashboardController>().assignedMeterIds;
    }
    return [];
  }

  Future<void> _loadMeterModel() async {
    final meters = await _metersService.fetchOnce(_assignedMeterIds);
    meterModel.value = meters.isEmpty
        ? 'No meter found'
        : meters.map((meter) => meter.name).join(', ');
  }

  void goToMeterConfig() {
    Get.toNamed(AppRoutes.meters, arguments: {'meterIds': _assignedMeterIds});
  }

  void selectLanguage() {
    _showPicker(
      title: 'Language',
      options: const ['English', 'Urdu'],
      current: language,
    );
  }

  void selectCurrency() {
    _showPicker(
      title: 'Currency',
      options: const ['PKR', 'USD'],
      current: currency,
    );
  }

  void _showPicker({
    required String title,
    required List<String> options,
    required RxString current,
  }) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...options.map(
              (option) => ListTile(
                title: Text(option),
                trailing: option == current.value
                    ? const Icon(Icons.check, color: Color(0xFF185FA5))
                    : null,
                onTap: () {
                  current.value = option;
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> signOut() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.clearSession();
      Get.offAllNamed('/login');
    }
  }
}

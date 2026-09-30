import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dashboard_controller.dart';
import 'theme_controller.dart';
import 'language_controller.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/firebase_meters_list_service.dart';

class SettingsController extends GetxController {
  // Account summary — swap these for your AuthController / ProfileController
  // once that's wired up, e.g. Get.find<ProfileController>().name
  final userName = ''.obs;
  final userEmail = ''.obs;
  final profilePhoto = ''.obs;

  // Alerts
  final billThresholdAlert = true.obs;
  final highPowerAlert = true.obs;
  final dailySummary = false.obs;

  // Meter & connection
  final meterModel = ''.obs;
  final isFirebaseConnected = false.obs;
  final AuthService _authService = AuthService();
  final FirebaseMetersListService _metersService = FirebaseMetersListService();
  Worker? _connectionStatusWorker;

  // App preferences
  final isDarkMode = false.obs;
  static const String _englishLabel = 'English';
  static const String _urduLabel = 'اردو';
  final language = _englishLabel.obs;
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
    _loadUserProfile();
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
    if (Get.isRegistered<LanguageController>()) {
      language.value = Get.find<LanguageController>().isUrdu
          ? _urduLabel
          : _englishLabel;
    }
    meterModel.value = 'loading'.tr;
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

  Future<void> goToProfile() async {
    final updatedPhoto = await Get.toNamed(
      '/profile',
      arguments: {'userName': userName.value, 'userEmail': userEmail.value},
    );
    if (updatedPhoto is String) profilePhoto.value = updatedPhoto;
  }

  Future<void> _loadUserProfile() async {
    final uid = await _authService.getCurrentUid();
    if (uid.isEmpty) return;
    final profile = await _authService.fetchUserProfile(uid);
    if (profile == null) return;
    if (profile.name.trim().isNotEmpty) userName.value = profile.name.trim();
    if (profile.email.trim().isNotEmpty) userEmail.value = profile.email.trim();
    profilePhoto.value = profile.profilePhoto;
  }

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
        ? 'no_meter_found'.tr
        : meters.map((meter) => meter.name).join(', ');
  }

  void goToMeterConfig() {
    Get.toNamed(AppRoutes.meters, arguments: {'meterIds': _assignedMeterIds});
  }

  void selectLanguage() {
    _showPicker(
      title: 'language'.tr,
      options: const [_englishLabel, _urduLabel],
      current: language,
      onSelected: (option) => Get.find<LanguageController>().setLanguage(
        option == _urduLabel ? 'ur' : 'en',
      ),
    );
  }

  void selectCurrency() {
    _showPicker(
      title: 'currency'.tr,
      options: const ['PKR', 'USD'],
      current: currency,
    );
  }

  void _showPicker({
    required String title,
    required List<String> options,
    required RxString current,
    void Function(String option)? onSelected,
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
                  onSelected?.call(option);
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
        title: Text('sign_out'.tr),
        content: Text('sign_out_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('sign_out'.tr),
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  // Account summary — swap these for your AuthController / ProfileController
  // once that's wired up, e.g. Get.find<ProfileController>().name
  final userName = 'Ahmed Khan'.obs;
  final userEmail = 'ahmed.khan@email.com'.obs;

  // Alerts
  final billThresholdAlert = true.obs;
  final highPowerAlert = true.obs;
  final dailySummary = false.obs;

  // Meter & connection
  final meterModel = 'CHINT DTSU666'.obs;
  final isFirebaseConnected = true.obs;

  // App preferences
  final isDarkMode = false.obs;
  final language = 'English'.obs;
  final currency = 'PKR'.obs;

  void toggleBillThresholdAlert(bool value) => billThresholdAlert.value = value;

  void toggleHighPowerAlert(bool value) => highPowerAlert.value = value;

  void toggleDailySummary(bool value) => dailySummary.value = value;

  void toggleDarkMode(bool value) {
    isDarkMode.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  void goToProfile() => Get.toNamed('/profile');

  void goToMeterConfig() => Get.toNamed('/meter-config');

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
      Get.offAllNamed('/login');
    }
  }
}

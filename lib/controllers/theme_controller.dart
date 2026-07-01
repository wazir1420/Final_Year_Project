import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  final _isDark = false.obs;

  bool get isDark => _isDark.value;

  // Expose the reactive so views can rebuild when theme changes
  RxBool get isDarkRx => _isDark;

  set isDark(bool v) {
    _isDark.value = v;
    Get.changeThemeMode(v ? ThemeMode.dark : ThemeMode.light);
  }

  void toggle(bool v) => isDark = v;

  @override
  void onInit() {
    super.onInit();
    _isDark.value = Get.isDarkMode;
  }
}

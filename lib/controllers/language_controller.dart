// lib/controllers/language_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App ki zubaan (English / Urdu).
///
/// Default aur HAR naye launch par zubaan English hoti hai. User jab Settings
/// mein Urdu chunta hai to wo poore session (sign-out ke baad login screen
/// samet) wahi rehti hai — app dobara kholne par phir English se shuru hoti
/// hai. Zubaan phone mein save nahi hoti (session-scoped).
class LanguageController extends GetxController {
  static const Locale english = Locale('en', 'US');
  static const Locale urdu = Locale('ur', 'PK');

  final Rx<Locale> locale = english.obs;

  bool get isUrdu => locale.value.languageCode == 'ur';

  /// App shuru hone par (main mein) call hota hai — hamesha default English.
  Future<void> load() async {
    locale.value = english;
  }

  /// [code] 'en' ya 'ur' — foran lagoo, is session ke liye yaad rehti hai.
  Future<void> setLanguage(String code) async {
    final next = code == 'ur' ? urdu : english;
    locale.value = next;
    Get.updateLocale(next);
  }
}

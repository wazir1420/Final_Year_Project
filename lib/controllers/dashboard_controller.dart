import 'dart:async';
import 'package:get/get.dart';

import '../models/meter_data_model.dart';
import '../models/bill_model.dart';
import '../routes/app_routes.dart';
import '../services/firebase_meter_service.dart';
import '../services/dummy_data_service.dart';
import 'settings_controller.dart';

class DashboardController extends GetxController {
  // Ab live meter reading Firebase se aa rahi hai (ESP32 wahan bhejta hai).
  // Testing abhi 1 phase (L1) par ho rahi hai — poore 3-phase setup ke baad
  // connectedPhases: 3 kar dein, baaki kuch change nahi karna hoga.
  final FirebaseMeterService _service = FirebaseMeterService(
    connectedPhases: 1,
  );

  // Monthly/daily history abhi Firebase mein save nahi ho rahi (agla step),
  // isliye chart data filhal simulate hi hota hai — live readings real hain.
  final DummyDataService _historyService = DummyDataService();

  // Observable variables
  final RxBool isLoading = true.obs;
  final RxBool isLive = false.obs;

  // Agar Firebase se 10 second tak koi naya data na aaye, ye false ho jata hai
  // aur UI "Meter Offline" dikhata hai — purani values ko live samajh kar
  // dikhate rehne se bachata hai.
  final RxBool isMeterOnline = true.obs;
  static const int _offlineThresholdSeconds = 10;
  Timer? _livenessTimer;

  final Rx<MeterData> meterData = MeterData.empty().obs;

  final RxDouble monthlyKwh = 0.0.obs;

  final RxList<DailyUsage> dailyUsage = <DailyUsage>[].obs;

  final Rx<BillEstimate> bill = BillEstimate.empty().obs;

  final RxDouble mlPredicted = 0.0.obs;

  final RxDouble mlChange = 0.0.obs;
  final RxInt selectedTab = 0.obs;

  // Tariff
  static const double ratePerKwh = 24.0;
  static const double fixedCharge = 150.0;
  static const double taxRate = 0.17;

  StreamSubscription<MeterData>? _meterSub;

  @override
  void onInit() {
    super.onInit();

    loadMonthlyData();
    startMeterStream();
  }

  @override
  void onClose() {
    _meterSub?.cancel();
    _livenessTimer?.cancel();

    super.onClose();
  }

  void loadMonthlyData() {
    final monthly = _historyService.getMonthlyData();

    monthlyKwh.value = monthly.totalKwh;

    dailyUsage.assignAll(monthly.daily);

    calculateBill();

    runMlProjection();
  }

  void startMeterStream() async {
    meterData.value = await _service.fetchOnce();

    isLoading.value = false;

    isLive.value = true;

    _meterSub = _service.meterStream.listen((reading) {
      meterData.value = reading;
    });

    // Har 2 second check karta hai ke aakhri reading kitni purani hai —
    // meterData khud update na bhi ho (meter band ho jaye), ye timer
    // phir bhi chalta rehta hai aur UI ko "Offline" dikha deta hai.
    _livenessTimer?.cancel();
    _livenessTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final age = DateTime.now()
          .difference(meterData.value.timestamp)
          .inSeconds;
      isMeterOnline.value = age < _offlineThresholdSeconds;
    });
  }

  void calculateBill() {
    final units = monthlyKwh.value;

    final energy = units * ratePerKwh;

    final subtotal = energy + fixedCharge;

    final taxes = subtotal * taxRate;

    bill.value = BillEstimate(
      unitsUsed: units,

      ratePerKwh: ratePerKwh,

      fixedCharge: fixedCharge,

      taxes: taxes,

      total: subtotal + taxes,
    );
  }

  void runMlProjection() {
    final now = DateTime.now();

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final daysPassed = now.day.clamp(1, daysInMonth).toInt();

    final projected = (monthlyKwh.value / daysPassed) * daysInMonth;

    final projectedBill =
        ((projected * ratePerKwh + fixedCharge) * (1 + taxRate));

    mlPredicted.value = projectedBill;

    final current = bill.value.total;

    mlChange.value = current > 0
        ? ((projectedBill - current) / current) * 100
        : 0;
  }

  String get connectedMeterName {
    if (Get.isRegistered<SettingsController>()) {
      return Get.find<SettingsController>().meterModel.value;
    }

    final fallback = SettingsController();
    Get.put<SettingsController>(fallback);
    return fallback.meterModel.value;
  }

  /// "Meter Offline" agar data purana ho, warna "Testing 1 of 3 phases" waghera
  String get phaseStatusLabel {
    if (!isMeterOnline.value) return 'Meter Offline';
    return meterData.value.phaseStatusLabel;
  }

  String get mlChangeLabel {
    final sign = mlChange.value >= 0 ? "+" : "";

    return "$sign${mlChange.value.toStringAsFixed(1)}%";
  }

  bool get mlIsIncrease => mlChange.value >= 0;

  void refreshData() {
    isLoading.value = true;

    _meterSub?.cancel();

    loadMonthlyData();

    startMeterStream();
  }

  // Tab state

  void selectTab(int index) {
    selectedTab.value = index;
  }

  // Navigation

  void goToAnalytics() {
    Get.toNamed(AppRoutes.analytics);
  }

  void goToBills() {
    Get.toNamed(AppRoutes.bills);
  }

  void goToSettings() {
    Get.toNamed(AppRoutes.settings);
  }

  void goToMlDetail() {
    Get.toNamed(AppRoutes.mlPrediction);
  }
}

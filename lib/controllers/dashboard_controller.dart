import 'dart:async';
import 'package:get/get.dart';

import '../models/meter_data_model.dart';
import '../models/bill_model.dart';
import '../routes/app_routes.dart';
import '../services/dummy_data_service.dart';
import 'settings_controller.dart';

class DashboardController extends GetxController {
  // Testing with only L1 of the CHINT DTSU666 wired up for now.
  // Change to 3 once the full industrial three-phase connection is live —
  // nothing else in the controller or views needs to change.
  final DummyDataService _service = DummyDataService(connectedPhases: 1);

  // Observable variables
  final RxBool isLoading = true.obs;
  final RxBool isLive = false.obs;

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

    super.onClose();
  }

  void loadMonthlyData() {
    final monthly = _service.getMonthlyData();

    monthlyKwh.value = monthly.totalKwh;

    dailyUsage.assignAll(monthly.daily);

    calculateBill();

    runMlProjection();
  }

  void startMeterStream() {
    meterData.value = _service.generateReading();

    isLoading.value = false;

    isLive.value = true;

    _meterSub = _service.meterStream.listen((reading) {
      meterData.value = reading;
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

  /// "Testing 1 of 3 phases" while on partial wiring, "Three-phase" once full.
  String get phaseStatusLabel => meterData.value.phaseStatusLabel;

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

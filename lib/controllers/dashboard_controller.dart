import 'dart:async';
import 'package:get/get.dart';

import '../models/meter_data_model.dart';
import '../models/bill_model.dart';
import '../routes/app_routes.dart';
import '../services/firebase_meter_service.dart';
import '../services/firebase_history_service.dart';

class DashboardController extends GetxController {
  final String meterId;
  final String meterName;

  DashboardController({required this.meterId, this.meterName = ''});

  late final FirebaseMeterService _service = FirebaseMeterService(
    meterId: meterId,
    meterName: meterName,
    connectedPhases: 1,
  );

  // Monthly/daily history ab isi meter ke Firebase '/history' se aati hai —
  // meter ke real cumulative energy readings se calculate hoti hai.
  late final FirebaseHistoryService _historyService = FirebaseHistoryService(
    meterId: meterId,
  );

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

  void loadMonthlyData() async {
    final monthly = await _historyService.fetchMonthlyData();

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

  /// Ab isi meter ka asli naam dikhata hai (jo ESP32 ne Firebase mein register
  /// kiya tha), taake har meter ka apna sahi naam dikhe, na ke hamesha ek hi
  /// fixed naam (jaisa Settings-based approach mein hota tha).
  String get connectedMeterName {
    final liveName = meterData.value.meterName;
    if (liveName.isNotEmpty) return liveName;
    if (meterName.isNotEmpty) return meterName;
    return meterId;
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

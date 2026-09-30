import 'dart:async';
import 'package:get/get.dart';

import '../models/meter_data_model.dart';
import '../models/bill_model.dart';
import '../models/ke_tariff_model.dart';
import '../routes/app_routes.dart';
import '../services/firebase_meter_service.dart';
import '../services/firebase_history_service.dart';
import '../services/firebase_meters_list_service.dart';
import '../services/auth_service.dart';
import '../services/ke_tariff_profile_service.dart';

class DashboardController extends GetxController {
  final String meterId;
  final String meterName;
  final String userName;
  final String userEmail;
  final List<String> assignedMeterIds;

  DashboardController({
    required this.meterId,
    this.meterName = '',
    this.userName = '',
    this.userEmail = '',
    List<String>? assignedMeterIds,
  }) : assignedMeterIds = assignedMeterIds?.toList() ?? [meterId];

  String get userInitials {
    final parts = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

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
  final AuthService _authService = AuthService();
  final KETariffProfileService _tariffProfileService = KETariffProfileService();

  // Observable variables
  final RxBool isLoading = true.obs;
  final RxBool isLive = false.obs;

  // Agar Firebase se 10 second tak koi naya data na aaye, ye false ho jata hai
  // aur UI "Meter Offline" dikhata hai — purani values ko live samajh kar
  // dikhate rehne se bachata hai.
  final RxBool isMeterOnline = false.obs;
  static const int _offlineThresholdSeconds = 20;
  Timer? _livenessTimer;

  // Liveness phone aur meter ki ghari mila kar nahi, "kya timestamp badal raha
  // hai" dekh kar Tay hota hai — dono taraf ke clock skew se immunity.
  DateTime? _lastNewReadingAt;
  int _lastReadingTimestampMs = -1;

  // Header mein "Welcome, <naam>" sirf shuru ke 2 minute dikhta hai, us ke
  // baad meter ka naam.
  static const Duration _welcomeDuration = Duration(minutes: 2);
  final RxBool showWelcome = true.obs;
  Timer? _welcomeTimer;

  final Rx<MeterData> meterData = MeterData.empty().obs;

  final RxDouble monthlyKwh = 0.0.obs;
  List<DatedDailyUsage> _allUsage = [];

  final RxList<DailyUsage> dailyUsage = <DailyUsage>[].obs;

  final Rx<BillEstimate> bill = BillEstimate.empty().obs;

  final RxDouble mlPredicted = 0.0.obs;

  final RxDouble mlChange = 0.0.obs;
  final RxInt selectedTab = 0.obs;
  final RxString _registeredMeterName = ''.obs;
  final RxString profilePhoto = ''.obs;
  final Rx<KETariffProfile> tariffProfile = const KETariffProfile().obs;

  StreamSubscription<MeterData>? _meterSub;

  @override
  void onInit() {
    super.onInit();

    _welcomeTimer = Timer(_welcomeDuration, () => showWelcome.value = false);
    if (meterName.isEmpty) _loadRegisteredMeterName();
    loadProfilePhoto();
    loadTariffProfile();
    loadMonthlyData();
    startMeterStream();
  }

  Future<void> _loadRegisteredMeterName() async {
    final meter = await FirebaseMetersListService().fetchMeter(meterId);
    if (meter != null && meter.name.isNotEmpty) {
      _registeredMeterName.value = meter.name;
    }
  }

  @override
  void onClose() {
    _meterSub?.cancel();
    _livenessTimer?.cancel();
    _welcomeTimer?.cancel();

    super.onClose();
  }

  void loadMonthlyData() async {
    _allUsage = await _historyService.fetchDailyUsage();
    final now = DateTime.now();
    final thisMonth = _allUsage
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();

    monthlyKwh.value = thisMonth.fold(0.0, (t, e) => t + e.kwh);

    dailyUsage.assignAll(
      thisMonth.map((e) => DailyUsage(day: e.date.day, kwh: e.kwh)),
    );

    calculateBill();

    runMlProjection();
  }

  void startMeterStream() async {
    // Pehli dafa load hote waqt agar fetch fail ho jaye, khaali state dikhayein
    // (koi purani value hai hi nahi is se pehle) — baad ke updates mein
    // service khud null par purani value ko chhoo nahi degi.
    meterData.value = await _service.fetchOnce() ?? MeterData.empty();
    _trackLiveness(meterData.value);

    isLoading.value = false;

    isLive.value = true;

    _meterSub = _service.meterStream.listen((reading) {
      meterData.value = reading;
      _trackLiveness(reading);
    });

    // Har 2 second check karta hai ke aakhri NAYA reading kitni der pehle aaya
    // tha — meter band ho jaye to timestamp jam jata hai, ye timer phir bhi
    // chalta rehta hai aur UI ko "Offline" dikha deta hai.
    _livenessTimer?.cancel();
    _livenessTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateMeterOnlineStatus();
    });
  }

  /// Naya reading (timestamp pehle se alag) aane par freshness ka mark lagata
  /// hai. MeterData.empty() ka timestamp epoch(0) hota hai — use fresh nahi
  /// ginte, warna bina data ke bhi online dikhne lagta.
  void _trackLiveness(MeterData reading) {
    final tsMs = reading.timestamp.millisecondsSinceEpoch;
    if (tsMs > 0 && tsMs != _lastReadingTimestampMs) {
      _lastReadingTimestampMs = tsMs;
      _lastNewReadingAt = DateTime.now();
    }
    _updateMeterOnlineStatus();
  }

  void _updateMeterOnlineStatus() {
    final last = _lastNewReadingAt;
    if (last == null) {
      isMeterOnline.value = false;
      return;
    }
    final since = DateTime.now().difference(last).inSeconds;
    isMeterOnline.value = since >= 0 && since < _offlineThresholdSeconds;
  }

  void calculateBill() {
    if (dailyUsage.isEmpty) {
      bill.value = BillEstimate.empty();
      return;
    }
    final now = DateTime.now();
    final estimate = KETariffCalculator.calculate(
      units: monthlyKwh.value,
      profile: tariffProfile.value,
      billingMonth: now,
      fcaUnits: KETariffCalculator.fcaUnitsFromUsage(_allUsage, now),
    );

    bill.value = BillEstimate(
      unitsUsed: estimate.units,
      ratePerKwh: estimate.baseRatePerUnit,
      // "Other KE charges": fixed + PHL + FCA + quarterly adjustment (+ TV).
      fixedCharge: estimate.total - estimate.taxes - estimate.variableCharges,
      taxes: estimate.taxes,
      total: estimate.total,
    );
  }

  Future<void> loadTariffProfile() async {
    try {
      tariffProfile.value = await _tariffProfileService.fetch(meterId);
    } catch (_) {
      // Keep defaults if the tariff profile cannot be read.
    }
    calculateBill();
    runMlProjection();
  }

  bool get hasMonthlyAdjustments =>
      tariffProfile.value.adjustmentsFor(DateTime.now()).isConfigured;

  void runMlProjection() {
    if (dailyUsage.isEmpty) {
      mlPredicted.value = 0;
      mlChange.value = 0;
      return;
    }
    final now = DateTime.now();

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final daysPassed = now.day.clamp(1, daysInMonth).toInt();

    final projected = (monthlyKwh.value / daysPassed) * daysInMonth;

    final projectedBill = KETariffCalculator.calculate(
      units: projected,
      profile: tariffProfile.value,
      billingMonth: now,
      fcaUnits: KETariffCalculator.fcaUnitsFromUsage(_allUsage, now),
    );

    mlPredicted.value = projectedBill.total;

    final current = bill.value.total;

    mlChange.value = current > 0
        ? ((projectedBill.total - current) / current) * 100
        : 0;
  }

  /// Ab isi meter ka asli naam dikhata hai (jo ESP32 ne Firebase mein register
  /// kiya tha), taake har meter ka apna sahi naam dikhe, na ke hamesha ek hi
  /// fixed naam (jaisa Settings-based approach mein hota tha).
  String get connectedMeterName {
    final liveName = meterData.value.meterName;
    if (liveName.isNotEmpty) return liveName;
    if (meterName.isNotEmpty) return meterName;
    if (_registeredMeterName.value.isNotEmpty) {
      return _registeredMeterName.value;
    }
    return meterId;
  }

  String get headerSubtitle {
    final name = userName.trim();
    if (showWelcome.value && name.isNotEmpty) {
      return 'welcome_user'.trParams({'name': name});
    }
    return connectedMeterName;
  }

  /// "Meter Offline" agar data purana ho, warna "Testing 1 of 3 phases" waghera
  String get phaseStatusLabel {
    if (!isMeterOnline.value) return 'meter_offline'.tr;
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
    Get.toNamed(AppRoutes.analytics, arguments: _dashboardArguments);
  }

  void goToBills() {
    Get.toNamed(AppRoutes.bills, arguments: _dashboardArguments);
  }

  void goToSettings() {
    Get.toNamed(AppRoutes.settings, arguments: _dashboardArguments);
  }

  Future<void> goToProfile() async {
    final result = await Get.toNamed(
      AppRoutes.profile,
      arguments: {'userName': userName, 'userEmail': userEmail},
    );
    if (result is String) profilePhoto.value = result;
  }

  Future<void> loadProfilePhoto() async {
    final uid = await _authService.getCurrentUid();
    if (uid.isEmpty) return;
    final profile = await _authService.fetchUserProfile(uid);
    if (profile != null) profilePhoto.value = profile.profilePhoto;
  }

  Map<String, dynamic> get _dashboardArguments => {
    'meterId': meterId,
    'meterName': meterName,
    'meterIds': assignedMeterIds,
    'userName': userName,
    'userEmail': userEmail,
  };

  void goToMlDetail() {
    Get.toNamed(AppRoutes.mlPrediction);
  }
}

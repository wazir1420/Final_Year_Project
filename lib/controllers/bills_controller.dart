import 'package:finalyearproject/models/bills_model.dart';
import 'package:finalyearproject/models/ke_tariff_model.dart';
import 'package:finalyearproject/models/meter_data_model.dart';
import 'package:get/get.dart';
import '../services/firebase_history_service.dart';
import '../services/ke_tariff_profile_service.dart';

class BillsController extends GetxController {
  late final FirebaseHistoryService _historyService;
  final KETariffProfileService _tariffProfileService = KETariffProfileService();
  List<DatedDailyUsage> _allUsage = [];

  late final Rx<BillMonth> selectedMonth;
  final isLoading = true.obs;
  final Rxn<MonthBill> bill = Rxn();
  final tariffProfile = const KETariffProfile().obs;
  final RxList<DailyCost> dailyCosts = <DailyCost>[].obs;
  final RxList<MonthComparison> comparisons = <MonthComparison>[].obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    selectedMonth = BillMonth(year: now.year, month: now.month).obs;
    final arguments = Get.arguments;
    final meterId = arguments is Map
        ? arguments['meterId']?.toString() ?? 'meter1'
        : 'meter1';
    _historyService = FirebaseHistoryService(meterId: meterId);
    _load();
  }

  void prevMonth() {
    selectedMonth.value = selectedMonth.value.prev();
    _updateSelectedMonth();
  }

  void nextMonth() {
    if (!canGoNext) return;
    selectedMonth.value = selectedMonth.value.next();
    _updateSelectedMonth();
  }

  bool get canGoNext => !selectedMonth.value.isCurrentMonth;

  bool get hasMonthlyAdjustments => tariffProfile.value
      .adjustmentsFor(
        DateTime(selectedMonth.value.year, selectedMonth.value.month),
      )
      .isConfigured;

  Future<void> _load() async {
    isLoading.value = true;
    _allUsage = await _historyService.fetchDailyUsage();
    try {
      tariffProfile.value = await _tariffProfileService.fetch(
        _historyService.meterId,
      );
    } catch (_) {
      tariffProfile.value = const KETariffProfile();
    }
    _updateSelectedMonth();
    isLoading.value = false;
  }

  Future<void> saveTariffProfile(KETariffProfile profile) async {
    await _tariffProfileService.save(_historyService.meterId, profile);
    tariffProfile.value = profile;
    _updateSelectedMonth();
  }

  void _updateSelectedMonth() {
    final period = selectedMonth.value;
    final usage = _usageForMonth(period);
    final units = _totalKwh(usage);
    final daysInMonth = DateTime(period.year, period.month + 1, 0).day;
    final currentDay = DateTime.now().day;
    final projected = period.isCurrentMonth && usage.isNotEmpty
        ? units / currentDay * daysInMonth
        : units;
    final calculation = _calculate(period, units);

    bill.value = MonthBill(
      period: period,
      unitsKwh: units,
      projectedUnitsKwh: projected,
      lineItems: calculation.toInvoiceItems(),
      subtotalRs: calculation.electricityCharges,
      gstRs: calculation.salesTax,
      incomeTaxRs: calculation.incomeTax,
      totalRs: calculation.total,
      dueDate: null,
      isPaid: false,
    );

    dailyCosts.assignAll(
      usage.map(
        (reading) => DailyCost(
          day: reading.date.day,
          costRs: units > 0 ? calculation.total * reading.kwh / units : 0,
          kwh: reading.kwh,
        ),
      ),
    );

    final monthlyComparisons = <MonthComparison>[];
    var comparisonPeriod = period;
    for (var index = 0; index < 5; index++) {
      final comparisonUsage = _usageForMonth(comparisonPeriod);
      if (comparisonUsage.isNotEmpty) {
        final comparisonTotal = _calculate(
          comparisonPeriod,
          _totalKwh(comparisonUsage),
        ).total;
        final previousUsage = _usageForMonth(comparisonPeriod.prev());
        final previousPeriod = comparisonPeriod.prev();
        final previousTotal = previousUsage.isEmpty
            ? 0.0
            : _calculate(previousPeriod, _totalKwh(previousUsage)).total;
        final deltaPct = previousTotal > 0
            ? (comparisonTotal - previousTotal) / previousTotal * 100
            : 0.0;
        monthlyComparisons.add(
          MonthComparison(
            period: comparisonPeriod,
            totalRs: comparisonTotal,
            deltaPct: deltaPct,
          ),
        );
      }
      comparisonPeriod = comparisonPeriod.prev();
    }
    comparisons.assignAll(monthlyComparisons);
  }

  /// Ek hi jagah se KE calculation — FCA units (2 mahine pehle ke bill ke
  /// units) history se le kar.
  KETariffCalculation _calculate(BillMonth period, double units) {
    final month = DateTime(period.year, period.month);
    return KETariffCalculator.calculate(
      units: units,
      profile: tariffProfile.value,
      billingMonth: month,
      fcaUnits: KETariffCalculator.fcaUnitsFromUsage(_allUsage, month),
    );
  }

  List<DatedDailyUsage> _usageForMonth(BillMonth period) => _allUsage
      .where(
        (entry) =>
            entry.date.year == period.year && entry.date.month == period.month,
      )
      .toList();

  double _totalKwh(List<DatedDailyUsage> usage) =>
      usage.fold(0.0, (total, entry) => total + entry.kwh);

  String get cycleProgressLabel {
    final b = bill.value;
    if (b == null) return '';
    if (!b.period.isCurrentMonth) {
      return 'bills_consumed'.trParams({
        'units': b.unitsKwh.toStringAsFixed(1),
      });
    }
    return 'bills_projected'.trParams({
      'units': b.unitsKwh.toStringAsFixed(1),
      'projected': b.projectedUnitsKwh.toStringAsFixed(0),
    });
  }

  String get dueDateLabel {
    final b = bill.value;
    if (b == null) return '';
    return 'bills_estimate_only'.tr;
  }

  bool get isBillPaid => bill.value?.isPaid ?? false;

  double get maxDailyCost {
    if (dailyCosts.isEmpty) return 1.0;
    return dailyCosts.map((d) => d.costRs).reduce((a, b) => a > b ? a : b);
  }

  double get maxComparisonTotal {
    if (comparisons.isEmpty) return 1.0;
    return comparisons.map((c) => c.totalRs).reduce((a, b) => a > b ? a : b);
  }

  double get avgDailyCost {
    if (dailyCosts.isEmpty) return 0;
    return dailyCosts.fold(0.0, (s, d) => s + d.costRs) / dailyCosts.length;
  }

  double get avgMonthlyBill {
    if (comparisons.isEmpty) return 0;
    return comparisons.fold(0.0, (s, c) => s + c.totalRs) / comparisons.length;
  }

  List<DailyCost> get displayedDailyCosts {
    if (dailyCosts.length <= 14) return dailyCosts;
    return dailyCosts.where((d) => d.day % 2 == 1).toList();
  }

  void goBack() => Get.back();
}

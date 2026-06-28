import 'package:get/get.dart';
import '../models/analytics_model.dart';
import '../services/analytics_dummy_service.dart';

enum AnalyticsPeriod { day, week, month }

class AnalyticsController extends GetxController {
  final _service = AnalyticsDummyService();

  // ── Observables ─────────────────────────────────────────────────────────
  final selectedPeriod = AnalyticsPeriod.week.obs;
  final summary = Rxn<AnalyticsSummary>();
  final dailyStats = <DailyStats>[].obs;
  final hourlyTrend = <HourlyPoint>[].obs;
  final heatmapCells = <HeatmapCell>[].obs;

  // Derived display helpers
  String get periodLabel {
    switch (selectedPeriod.value) {
      case AnalyticsPeriod.day:
        return 'Day';
      case AnalyticsPeriod.week:
        return 'Week';
      case AnalyticsPeriod.month:
        return 'Month';
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _load();
  }

  // ── Period switching ─────────────────────────────────────────────────────
  void selectDay() => _setPeriod(AnalyticsPeriod.day);
  void selectWeek() => _setPeriod(AnalyticsPeriod.week);
  void selectMonth() => _setPeriod(AnalyticsPeriod.month);

  void _setPeriod(AnalyticsPeriod p) {
    if (selectedPeriod.value == p) return;
    selectedPeriod.value = p;
    _load();
  }

  // ── Data loading ─────────────────────────────────────────────────────────
  void _load() {
    final label = periodLabel;
    summary.value = _service.getSummary(label);
    dailyStats.value = _service.getDailyStats(label);
    hourlyTrend.value = _service.getHourlyTrend(label);
    heatmapCells.value = _service.getHeatmap(label);
  }

  // ── Formatters used in the View ──────────────────────────────────────────
  String deltaLabel(double pct) {
    final sign = pct >= 0 ? '↑' : '↓';
    return '$sign ${pct.abs().toStringAsFixed(1)}%';
  }

  bool isPositiveDelta(double pct) => pct >= 0;

  // For bar chart: max kWh across both this + prev so bars are consistent
  double get maxKwh {
    if (dailyStats.isEmpty) return 1.0;
    return dailyStats
        .expand((d) => [d.kwh, d.prevKwh])
        .reduce((a, b) => a > b ? a : b);
  }

  // For cost bars
  double get maxCost {
    if (dailyStats.isEmpty) return 1.0;
    return dailyStats.map((d) => d.costRs).reduce((a, b) => a > b ? a : b);
  }

  // For trend line: normalise kW to 0..1 for painting
  double get maxKw {
    if (hourlyTrend.isEmpty) return 1.0;
    return hourlyTrend.map((p) => p.kw).reduce((a, b) => a > b ? a : b);
  }

  // Week total cost
  double get weekTotalCost => dailyStats.fold(0.0, (s, d) => s + d.costRs);

  // Navigation
  void goBack() => Get.back();
}

import 'package:get/get.dart';
import '../models/analytics_model.dart';
import '../models/ke_tariff_model.dart';
import '../models/meter_data_model.dart';
import '../controllers/language_controller.dart';
import '../services/firebase_history_service.dart';
import '../services/ke_tariff_profile_service.dart';

enum AnalyticsPeriod { day, week, month }

class AnalyticsController extends GetxController {
  late final FirebaseHistoryService _historyService;
  final KETariffProfileService _tariffProfileService = KETariffProfileService();
  List<DatedDailyUsage> _allUsage = [];
  List<HourlyUsage> _allHourly = [];
  int _loadVersion = 0;

  // ── Observables ─────────────────────────────────────────────────────────
  final selectedPeriod = AnalyticsPeriod.week.obs;
  final isLoading = true.obs;
  final summary = Rxn<AnalyticsSummary>();
  final dailyStats = <DailyStats>[].obs;
  final trendPoints = <TrendPoint>[].obs;
  final heatmap = <HeatmapCell>[].obs;
  final tariffProfile = const KETariffProfile().obs;

  bool get hasMonthlyAdjustments =>
      tariffProfile.value.adjustmentsFor(DateTime.now()).isConfigured;

  // Derived display helpers
  /// Tab selection ke liye stable key (language-independent).
  String get periodKey => selectedPeriod.value.name;

  /// Tab aur delta labels ke liye translated naam (Day/Week/Month → دن/ہفتہ/مہینہ).
  String get periodLabel => 'analytics_period_${selectedPeriod.value.name}'.tr;

  /// Deltas ke liye lowercase form; Urdu mein lowercase nahi hota to wahi
  /// translated word return karte hain.
  String get periodLabelLower => isEnglish
      ? periodLabel.toLowerCase()
      : periodLabel;

  bool get isEnglish {
    if (Get.isRegistered<LanguageController>()) {
      return !Get.find<LanguageController>().isUrdu;
    }
    return (Get.locale?.languageCode ?? 'en') == 'en';
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    final meterId = arguments is Map
        ? arguments['meterId']?.toString() ?? 'meter1'
        : 'meter1';
    _historyService = FirebaseHistoryService(meterId: meterId);
    _load();
  }

  // ── Period switching ─────────────────────────────────────────────────────
  void selectDay() => _setPeriod(AnalyticsPeriod.day);
  void selectWeek() => _setPeriod(AnalyticsPeriod.week);
  void selectMonth() => _setPeriod(AnalyticsPeriod.month);

  void _setPeriod(AnalyticsPeriod p) {
    if (selectedPeriod.value == p) return;
    selectedPeriod.value = p;
    _updatePeriod();
  }

  // ── Data loading ─────────────────────────────────────────────────────────
  Future<void> _load() async {
    final version = ++_loadVersion;
    isLoading.value = true;
    _allUsage = await _historyService.fetchDailyUsage();
    _allHourly = await _historyService.fetchHourlyUsage();
    try {
      tariffProfile.value = await _tariffProfileService.fetch(
        _historyService.meterId,
      );
    } catch (_) {
      tariffProfile.value = const KETariffProfile();
    }
    if (version != _loadVersion) return;
    _updatePeriod();
    isLoading.value = false;
  }

  Future<void> reload() => _load();

  void _updatePeriod() {
    final today = _dateOnly(DateTime.now());
    late final DateTime start;
    late final DateTime end;
    late final DateTime previousStart;
    late final DateTime previousEnd;

    switch (selectedPeriod.value) {
      case AnalyticsPeriod.day:
        start = today;
        end = today;
        previousStart = today.subtract(const Duration(days: 1));
        previousEnd = previousStart;
      case AnalyticsPeriod.week:
        start = today.subtract(Duration(days: today.weekday - 1));
        end = start.add(const Duration(days: 6));
        previousStart = start.subtract(const Duration(days: 7));
        previousEnd = start.subtract(const Duration(days: 1));
      case AnalyticsPeriod.month:
        start = DateTime(today.year, today.month);
        end = today;
        previousStart = DateTime(today.year, today.month - 1);
        final previousMonthDays = DateTime(
          previousStart.year,
          previousStart.month + 1,
          0,
        ).day;
        previousEnd = DateTime(
          previousStart.year,
          previousStart.month,
          today.day < previousMonthDays ? today.day : previousMonthDays,
        );
    }

    final current = _range(start, end);
    final previous = _range(previousStart, previousEnd);
    final currentTotal = _total(current);
    final previousTotal = _total(previous);
    final currentCost = _estimateRangeCost(current);
    final previousCost = _estimateRangeCost(previous);
    final hasPreviousData = previous.isNotEmpty && previousTotal > 0;
    final highestUsage = current.isEmpty
        ? null
        : current.reduce((a, b) => a.kwh >= b.kwh ? a : b);

    summary.value = AnalyticsSummary(
      totalKwh: currentTotal,
      avgDailyCostRs: current.isEmpty ? 0 : currentCost / current.length,
      kwhDeltaPct: hasPreviousData
          ? ((currentTotal - previousTotal) / previousTotal) * 100
          : 0,
      costDeltaPct: hasPreviousData
          ? ((currentCost - previousCost) / previousCost) * 100
          : 0,
      maxDailyKwh: highestUsage?.kwh ?? 0,
      maxDailyLabel: highestUsage == null
          ? 'analytics_max_daily_none'.tr
          : _dateLabel(highestUsage.date),
      daysWithReadings: current.length,
      hasPreviousData: hasPreviousData,
    );
    if (current.isEmpty) {
      dailyStats.clear();
      _rebuildTrend(start, end);
      _rebuildHeatmap(start, end);
      return;
    }
    dailyStats.assignAll(_buildStats(start, end, previousStart, previousEnd));
    _rebuildTrend(start, end);
    _rebuildHeatmap(start, end);
  }

  /// Peak hours heatmap: rows = time slots (6,9,12,15,18,21),
  /// columns period ke hisaab se:
  /// - Day → 1 column (aaj ka slot pattern)
  /// - Week → 7 columns (Mon..Sun = peak days)
  /// - Month → week columns (W1..W5 = peak weeks)
  void _rebuildHeatmap(DateTime start, DateTime end) {
    final endExclusive = end.add(const Duration(days: 1));
    final inRange = _allHourly
        .where(
          (entry) =>
              !entry.hourStart.isBefore(start) &&
              entry.hourStart.isBefore(endExclusive),
        )
        .toList();
    if (inRange.isEmpty) {
      heatmap.clear();
      return;
    }

    const slots = [6, 9, 12, 15, 18, 21];

    // Column key: Day → sab 1; Week → weekday (1..7); Month → week bucket
    int columnKeyFor(DateTime ts) {
      switch (selectedPeriod.value) {
        case AnalyticsPeriod.day:
          return 1;
        case AnalyticsPeriod.week:
          return ts.weekday;
        case AnalyticsPeriod.month:
          return ((ts.day - 1) ~/ 7) + 1;
      }
    }

    int columnCount() {
      switch (selectedPeriod.value) {
        case AnalyticsPeriod.day:
          return 1;
        case AnalyticsPeriod.week:
          return 7;
        case AnalyticsPeriod.month:
          return ((DateTime(start.year, start.month + 1, 0).day - 1) ~/ 7) + 1;
      }
    }

    final byCell = <String, List<double>>{};
    for (final entry in inRange) {
      final slot = slots.lastWhere((s) => entry.hour >= s, orElse: () => 0);
      if (slot == 0) continue; // 0–5 baje wali readings heatmap se bahar
      final key = '${columnKeyFor(entry.hourStart)}-$slot';
      byCell.putIfAbsent(key, () => []).add(entry.kwh);
    }
    final cellAvgs = <String, double>{};
    for (final cell in byCell.entries) {
      final values = cell.value;
      cellAvgs[cell.key] = values.reduce((a, b) => a + b) / values.length;
    }
    final maxCell = cellAvgs.values.fold(0.0, (m, v) => v > m ? v : m);
    heatmap.clear();
    if (maxCell <= 0) return;
    for (final slot in slots) {
      for (int c = 1; c <= columnCount(); c++) {
        final avg = cellAvgs['$c-$slot'] ?? 0.0;
        heatmap.add(
          HeatmapCell(
            hour: slot,
            day: _heatmapColumnLabel(c),
            dayKey: c,
            intensity: (avg / maxCell).clamp(0.0, 1.0),
          ),
        );
      }
    }
  }

  String _heatmapColumnLabel(int c) {
    switch (selectedPeriod.value) {
      case AnalyticsPeriod.day:
        return 'today'.tr;
      case AnalyticsPeriod.week:
        return 'weekday_$c'.tr;
      case AnalyticsPeriod.month:
        return 'W$c';
    }
  }

  /// Trend graph period ke hisaab se:
  /// - Day → aaj ke 24 ghante (hourly readings se; baghair hourly ke khali)
  /// - Week → current week ke 7 din (Mon..Sun, daily history se)
  /// - Month → current month ke hafte (W1..W5, daily history se)
  void _rebuildTrend(DateTime start, DateTime end) {
    switch (selectedPeriod.value) {
      case AnalyticsPeriod.day:
        trendPoints.assignAll(_trendFromHourly(start, end));
      case AnalyticsPeriod.week:
        trendPoints.assignAll(_trendFromDaily(start, end));
      case AnalyticsPeriod.month:
        trendPoints.assignAll(_trendFromDailyBucketed(start, end));
    }
  }

  /// Day view: fixed 0h–24h axis — guzar chuke ghante par dots/line,
  /// future ghante khali (curve har ghante aage barhta hai).
  List<TrendPoint> _trendFromHourly(DateTime start, DateTime end) {
    final endExclusive = end.add(const Duration(days: 1));
    final inRange = _allHourly
        .where(
          (entry) =>
              !entry.hourStart.isBefore(start) &&
              entry.hourStart.isBefore(endExclusive),
        )
        .toList();
    if (inRange.isEmpty) return const [];

    final byHour = List.generate(24, (_) => 0.0);
    final hourHasData = List.generate(24, (_) => false);
    for (final entry in inRange) {
      byHour[entry.hour] += entry.kwh;
      hourHasData[entry.hour] = true;
    }
    return List.generate(
      24,
      (h) => TrendPoint(
        label: '$h',
        value: byHour[h],
        hasData: hourHasData[h],
      ),
    );
  }

  /// Week view: 7 din ke slots — din COMPLETE hone par slot bharta hai.
  List<TrendPoint> _trendFromDaily(DateTime start, DateTime end) {
    final inRange = _range(start, end);
    final today = _dateOnly(DateTime.now());
    final byWeekday = List.generate(7, (_) => 0.0);
    for (final entry in inRange) {
      final idx = entry.date.weekday - 1; // Mon=0..Sun=6
      if (idx >= 0 && idx < 7) byWeekday[idx] += entry.kwh;
    }
    return List.generate(7, (i) {
      final dayDate = start.add(Duration(days: i));
      final slotDone = dayDate.isBefore(today); // din poora guzar gaya
      return TrendPoint(
        label: 'weekday_${i + 1}'.tr,
        value: byWeekday[i],
        hasData: slotDone,
      );
    });
  }

  /// Month view: W1..Wn — hafta COMPLETE hone par slot bharta hai.
  List<TrendPoint> _trendFromDailyBucketed(DateTime start, DateTime end) {
    final inRange = _range(start, end);
    final count = (DateTime(start.year, start.month + 1, 0).day + 6) ~/ 7;
    final today = _dateOnly(DateTime.now());
    final byBucket = List.generate(count, (_) => 0.0);
    for (final entry in inRange) {
      final bucket = (entry.date.day - 1) ~/ 7;
      if (bucket < count) byBucket[bucket] += entry.kwh;
    }
    return List.generate(count, (i) {
      final weekLastDay = DateTime(start.year, start.month, i * 7 + 7);
      final slotDone = weekLastDay.isBefore(today); // hafta poora guzar gaya
      return TrendPoint(
        label: 'W${i + 1}',
        value: byBucket[i],
        hasData: slotDone,
      );
    });
  }

  List<DatedDailyUsage> _range(DateTime start, DateTime end) => _allUsage
      .where((entry) => !entry.date.isBefore(start) && !entry.date.isAfter(end))
      .toList();

  List<DailyStats> _buildStats(
    DateTime start,
    DateTime end,
    DateTime previousStart,
    DateTime previousEnd,
  ) {
    final current = _range(start, end);
    final previous = _range(previousStart, previousEnd);
    final currentByBucket = _bucketUsage(current, start);
    final previousByBucket = _bucketUsage(previous, previousStart);
    final count = switch (selectedPeriod.value) {
      AnalyticsPeriod.day => 1,
      AnalyticsPeriod.week => 7,
      AnalyticsPeriod.month =>
        (DateTime(start.year, start.month + 1, 0).day + 6) ~/ 7,
    };
    final labels = switch (selectedPeriod.value) {
      AnalyticsPeriod.day => ['today'.tr],
      AnalyticsPeriod.week => List.generate(7, (i) => 'weekday_${i + 1}'.tr),
      AnalyticsPeriod.month => List.generate(count, (index) => 'W${index + 1}'),
    };
    final currentTotal = _total(current);
    final totalCost = _estimateRangeCost(current);

    return List.generate(count, (index) {
      final kwh = currentByBucket[index] ?? 0;
      return DailyStats(
        day: labels[index],
        kwh: kwh,
        prevKwh: previousByBucket[index] ?? 0,
        costRs: currentTotal > 0 ? totalCost * kwh / currentTotal : 0,
      );
    });
  }

  double _estimateRangeCost(List<DatedDailyUsage> entries) {
    final entriesByMonth = <String, List<DatedDailyUsage>>{};
    for (final entry in entries) {
      final key = KETariffProfile.monthKey(entry.date);
      entriesByMonth.putIfAbsent(key, () => []).add(entry);
    }

    var estimate = 0.0;
    for (final monthEntries in entriesByMonth.values) {
      final monthDate = monthEntries.first.date;
      final monthStart = DateTime(monthDate.year, monthDate.month);
      final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0);
      final monthUsage = _range(monthStart, monthEnd);
      final monthTotal = _total(monthUsage);
      if (monthTotal <= 0) continue;

      final monthEstimate = KETariffCalculator.calculate(
        units: monthTotal,
        profile: tariffProfile.value,
        billingMonth: monthStart,
        fcaUnits: KETariffCalculator.fcaUnitsFromUsage(_allUsage, monthStart),
      ).total;
      estimate += monthEstimate * _total(monthEntries) / monthTotal;
    }
    return estimate;
  }

  Map<int, double> _bucketUsage(List<DatedDailyUsage> entries, DateTime start) {
    final result = <int, double>{};
    for (final entry in entries) {
      final bucket = switch (selectedPeriod.value) {
        AnalyticsPeriod.day => 0,
        AnalyticsPeriod.week => entry.date.difference(start).inDays,
        AnalyticsPeriod.month => (entry.date.day - 1) ~/ 7,
      };
      result.update(
        bucket,
        (value) => value + entry.kwh,
        ifAbsent: () => entry.kwh,
      );
    }
    return result;
  }

  double _total(List<DatedDailyUsage> entries) =>
      entries.fold(0.0, (total, entry) => total + entry.kwh);

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dateLabel(DateTime date) {
    return '${'weekday_${date.weekday}'.tr} ${date.day}';
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

  // Total estimated energy cost for the selected period
  double get weekTotalCost => dailyStats.fold(0.0, (s, d) => s + d.costRs);

  // Navigation
  void goBack() => Get.back();
}

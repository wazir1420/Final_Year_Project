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

  final dayStartHour = 0.obs;
  final dayEndHour = 23.obs;
  final weekStartDay = 1.obs;
  final weekEndDay = 7.obs;
  final monthFilterStart = Rxn<DateTime>();
  final monthFilterEnd = Rxn<DateTime>();

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
  String get periodLabelLower =>
      isEnglish ? periodLabel.toLowerCase() : periodLabel;

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

  bool get hasActiveFilter => switch (selectedPeriod.value) {
    AnalyticsPeriod.day => dayStartHour.value != 0 || dayEndHour.value != 23,
    AnalyticsPeriod.week => weekStartDay.value != 1 || weekEndDay.value != 7,
    AnalyticsPeriod.month => monthFilterStart.value != null,
  };

  DateTime get selectedMonthStart =>
      monthFilterStart.value ??
      DateTime(DateTime.now().year, DateTime.now().month);

  DateTime get selectedMonthEnd =>
      monthFilterEnd.value ?? _dateOnly(DateTime.now());

  DateTime get historyStartDate {
    final dates = [
      ..._allUsage.map((entry) => entry.date),
      ..._allHourly.map((entry) => _dateOnly(entry.hourStart)),
    ];
    if (dates.isEmpty) return _dateOnly(DateTime.now());
    return dates.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime get historyEndDate {
    final dates = [
      ..._allUsage.map((entry) => entry.date),
      ..._allHourly.map((entry) => _dateOnly(entry.hourStart)),
    ];
    if (dates.isEmpty) return _dateOnly(DateTime.now());
    return dates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  void applyDayFilter({required int startHour, required int endHour}) {
    if (startHour < 0 || endHour > 23 || startHour > endHour) return;
    dayStartHour.value = startHour;
    dayEndHour.value = endHour;
    _updatePeriod();
  }

  void applyWeekFilter({required int startDay, required int endDay}) {
    if (startDay < 1 || endDay > 7 || startDay > endDay) return;
    weekStartDay.value = startDay;
    weekEndDay.value = endDay;
    _updatePeriod();
  }

  void applyMonthFilter({required DateTime start, required DateTime end}) {
    final first = _dateOnly(start);
    final last = _dateOnly(end);
    if (last.isBefore(first) ||
        first.month != last.month ||
        first.year != last.year) {
      return;
    }
    monthFilterStart.value = first;
    monthFilterEnd.value = last;
    _updatePeriod();
  }

  void resetCurrentFilter() {
    switch (selectedPeriod.value) {
      case AnalyticsPeriod.day:
        dayStartHour.value = 0;
        dayEndHour.value = 23;
      case AnalyticsPeriod.week:
        weekStartDay.value = 1;
        weekEndDay.value = 7;
      case AnalyticsPeriod.month:
        monthFilterStart.value = null;
        monthFilterEnd.value = null;
    }
    _updatePeriod();
  }

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
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        start = weekStart.add(Duration(days: weekStartDay.value - 1));
        end = weekStart.add(Duration(days: weekEndDay.value - 1));
        previousStart = start.subtract(const Duration(days: 7));
        previousEnd = end.subtract(const Duration(days: 7));
      case AnalyticsPeriod.month:
        start = _dateOnly(selectedMonthStart);
        end = _dateOnly(selectedMonthEnd);
        final previousMonth = DateTime(start.year, start.month - 1);
        final previousMonthDays = DateTime(
          previousMonth.year,
          previousMonth.month + 1,
          0,
        ).day;
        previousStart = DateTime(
          previousMonth.year,
          previousMonth.month,
          start.day < previousMonthDays ? start.day : previousMonthDays,
        );
        previousEnd = DateTime(
          previousMonth.year,
          previousMonth.month,
          end.day < previousMonthDays ? end.day : previousMonthDays,
        );
    }

    final current = selectedPeriod.value == AnalyticsPeriod.day
        ? _hourlyDailyUsage(start, dayStartHour.value, dayEndHour.value)
        : _range(start, end);
    final previous = selectedPeriod.value == AnalyticsPeriod.day
        ? _hourlyDailyUsage(previousStart, dayStartHour.value, dayEndHour.value)
        : _range(previousStart, previousEnd);
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
    dailyStats.assignAll(_buildStats(start, current, previous, previousStart));
    _rebuildTrend(start, end);
    _rebuildHeatmap(start, end);
  }

  List<DatedDailyUsage> _hourlyDailyUsage(
    DateTime date,
    int startHour,
    int endHour,
  ) {
    final entries = _allHourly.where((entry) {
      final entryDate = _dateOnly(entry.hourStart);
      return entryDate == date &&
          entry.hour >= startHour &&
          entry.hour <= endHour;
    });
    final matching = entries.toList();
    if (matching.isEmpty) return const [];
    return [
      DatedDailyUsage(
        date: date,
        kwh: matching.fold(0.0, (total, entry) => total + entry.kwh),
      ),
    ];
  }

  /// Usage heatmap: rows = three-hour slots covering the full day,
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
              entry.hourStart.isBefore(endExclusive) &&
              (selectedPeriod.value != AnalyticsPeriod.day ||
                  (entry.hour >= dayStartHour.value &&
                      entry.hour <= dayEndHour.value)),
        )
        .toList();
    if (inRange.isEmpty) {
      heatmap.clear();
      return;
    }

    const slots = [0, 3, 6, 9, 12, 15, 18, 21];

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

    List<int> columnKeys() {
      switch (selectedPeriod.value) {
        case AnalyticsPeriod.day:
          return [1];
        case AnalyticsPeriod.week:
          return List.generate(
            weekEndDay.value - weekStartDay.value + 1,
            (index) => weekStartDay.value + index,
          );
        case AnalyticsPeriod.month:
          return [1, 2, 3, 4, 5];
      }
    }

    final byCell = <String, List<double>>{};
    for (final entry in inRange) {
      final slot = slots.lastWhere((startHour) => entry.hour >= startHour);
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
      for (final c in columnKeys()) {
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
        return 'Week$c';
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
              entry.hourStart.isBefore(endExclusive) &&
              entry.hour >= dayStartHour.value &&
              entry.hour <= dayEndHour.value,
        )
        .toList();

    final byHour = List.generate(24, (_) => 0.0);
    final hourHasData = List.generate(24, (_) => false);
    for (final entry in inRange) {
      byHour[entry.hour] += entry.kwh;
      hourHasData[entry.hour] = true;
    }
    return List.generate(
          dayEndHour.value - dayStartHour.value + 1,
          (index) => dayStartHour.value + index,
        )
        .map(
          (hour) => TrendPoint(
            label: _hourLabel(hour),
            value: byHour[hour],
            hasData: hourHasData[hour],
          ),
        )
        .toList();
  }

  /// Week view: 7 din ke slots — din COMPLETE hone par slot bharta hai.
  List<TrendPoint> _trendFromDaily(DateTime start, DateTime end) {
    final inRange = _range(start, end);
    final today = _dateOnly(DateTime.now());
    final count = end.difference(start).inDays + 1;
    final byWeekday = List.generate(count, (_) => 0.0);
    for (final entry in inRange) {
      final idx = entry.date.difference(start).inDays;
      if (idx >= 0 && idx < count) byWeekday[idx] += entry.kwh;
    }
    return List.generate(count, (i) {
      final dayDate = start.add(Duration(days: i));
      final slotDone = dayDate.isBefore(today); // din poora guzar gaya
      return TrendPoint(
        label: 'weekday_${dayDate.weekday}'.tr,
        value: byWeekday[i],
        hasData: slotDone,
      );
    });
  }

  /// Month view: W1..Wn — hafta COMPLETE hone par slot bharta hai.
  List<TrendPoint> _trendFromDailyBucketed(DateTime start, DateTime end) {
    final inRange = _range(start, end);
    const count = 5;
    final today = _dateOnly(DateTime.now());
    final byBucket = List.generate(count, (_) => 0.0);
    for (final entry in inRange) {
      final bucket = (entry.date.day - 1) ~/ 7;
      if (bucket < count) byBucket[bucket] += entry.kwh;
    }
    return List.generate(count, (i) {
      final weekStart = DateTime(start.year, start.month, i * 7 + 1);
      final lastMonthDay = DateTime(start.year, start.month + 1, 0).day;
      final weekEnd = DateTime(
        start.year,
        start.month,
        i * 7 + 7 < lastMonthDay ? i * 7 + 7 : lastMonthDay,
      );
      final overlapsFilter =
          !weekEnd.isBefore(start) && !weekStart.isAfter(end);
      final slotDone = overlapsFilter && weekEnd.isBefore(today);
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
    List<DatedDailyUsage> current,
    List<DatedDailyUsage> previous,
    DateTime previousStart,
  ) {
    final currentByBucket = _bucketUsage(current, start);
    final previousByBucket = _bucketUsage(previous, previousStart);
    final count = switch (selectedPeriod.value) {
      AnalyticsPeriod.day => 1,
      AnalyticsPeriod.week => weekEndDay.value - weekStartDay.value + 1,
      AnalyticsPeriod.month => 5,
    };
    final labels = switch (selectedPeriod.value) {
      AnalyticsPeriod.day => ['today'.tr],
      AnalyticsPeriod.week => List.generate(
        count,
        (index) => 'weekday_${start.add(Duration(days: index)).weekday}'.tr,
      ),
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

  String _hourLabel(int hour) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12 ${hour < 12 ? 'AM' : 'PM'}';
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

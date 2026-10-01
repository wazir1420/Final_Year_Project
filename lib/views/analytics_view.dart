import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/analytics_controller.dart';
import '../controllers/theme_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/analytics_widgets.dart';
import '../widgets/app_bottom_nav_item.dart';
import '../services/route_observer.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> with RouteAware {
  final controller = Get.find<AnalyticsController>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {});
    controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final _ = Get.find<ThemeController>().isDarkRx.value;
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(),
            Expanded(child: _Body()),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(top: false, child: _BottomNav()),
    );
  }
}

// ── Header with title + period tabs ──────────────────────────────────────────
class _Header extends GetView<AnalyticsController> {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kCard,
      border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'nav_analytics'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ),
              Obx(
                () => IconButton(
                  icon: Icon(
                    controller.hasActiveFilter
                        ? Icons.filter_alt_rounded
                        : Icons.filter_alt_outlined,
                    color: controller.hasActiveFilter ? kBlue : kMuted,
                  ),
                  onPressed: () => _showAnalyticsFilter(context, controller),
                  tooltip: 'analytics_filter'.tr,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: kMuted,
                  size: 18,
                ),
                onPressed: controller.goBack,
                tooltip: 'back'.tr,
              ),
            ],
          ),
        ),
        // Period tab bar
        Obx(
          () => PeriodTabBar(
            selected: controller.periodKey,
            onDay: controller.selectDay,
            onWeek: controller.selectWeek,
            onMonth: controller.selectMonth,
          ),
        ),
      ],
    ),
  );
}

void _showAnalyticsFilter(
  BuildContext context,
  AnalyticsController controller,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AnalyticsFilterSheet(controller: controller),
  );
}

class _AnalyticsFilterSheet extends StatefulWidget {
  final AnalyticsController controller;

  const _AnalyticsFilterSheet({required this.controller});

  @override
  State<_AnalyticsFilterSheet> createState() => _AnalyticsFilterSheetState();
}

class _AnalyticsFilterSheetState extends State<_AnalyticsFilterSheet> {
  late int _startHour;
  late int _endHour;
  late int _startDay;
  late int _endDay;
  late DateTimeRange _monthRange;
  String? _error;

  AnalyticsController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _startHour = controller.dayStartHour.value;
    _endHour = controller.dayEndHour.value;
    _startDay = controller.weekStartDay.value;
    _endDay = controller.weekEndDay.value;
    _monthRange = _boundedMonthRange();
  }

  DateTimeRange _boundedMonthRange() {
    final first = DateUtils.dateOnly(controller.historyStartDate);
    final last = DateUtils.dateOnly(controller.historyEndDate);
    var start = DateUtils.dateOnly(controller.selectedMonthStart);
    var end = DateUtils.dateOnly(controller.selectedMonthEnd);
    if (start.isBefore(first)) start = first;
    if (start.isAfter(last)) start = last;
    if (end.isAfter(last)) end = last;
    if (end.isBefore(start)) end = start;
    return DateTimeRange(start: start, end: end);
  }

  Future<void> _pickMonthRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateUtils.dateOnly(controller.historyStartDate),
      lastDate: DateUtils.dateOnly(controller.historyEndDate),
      initialDateRange: _monthRange,
      helpText: 'analytics_filter_choose_dates'.tr,
    );
    if (range == null || !mounted) return;
    setState(() {
      _monthRange = DateTimeRange(
        start: DateUtils.dateOnly(range.start),
        end: DateUtils.dateOnly(range.end),
      );
      _error = null;
    });
  }

  void _apply() {
    switch (controller.selectedPeriod.value) {
      case AnalyticsPeriod.day:
        if (_startHour > _endHour) {
          setState(() => _error = 'analytics_filter_invalid_range'.tr);
          return;
        }
        controller.applyDayFilter(startHour: _startHour, endHour: _endHour);
      case AnalyticsPeriod.week:
        if (_startDay > _endDay) {
          setState(() => _error = 'analytics_filter_invalid_range'.tr);
          return;
        }
        controller.applyWeekFilter(startDay: _startDay, endDay: _endDay);
      case AnalyticsPeriod.month:
        if (_monthRange.start.year != _monthRange.end.year ||
            _monthRange.start.month != _monthRange.end.month) {
          setState(() => _error = 'analytics_filter_same_month'.tr);
          return;
        }
        controller.applyMonthFilter(
          start: _monthRange.start,
          end: _monthRange.end,
        );
    }
    Navigator.pop(context);
  }

  void _reset() {
    controller.resetCurrentFilter();
    Navigator.pop(context);
  }

  String _hourLabel(int hour) {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12 ${hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final period = controller.selectedPeriod.value;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'analytics_filter_title'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 20),
            if (period == AnalyticsPeriod.day)
              Row(
                children: [
                  Expanded(
                    child: _dropdown<int>(
                      label: 'analytics_filter_start_time'.tr,
                      value: _startHour,
                      items: List.generate(
                        24,
                        (hour) => DropdownMenuItem(
                          value: hour,
                          child: Text(_hourLabel(hour)),
                        ),
                      ),
                      onChanged: (value) => setState(() {
                        _startHour = value!;
                        _error = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dropdown<int>(
                      label: 'analytics_filter_end_time'.tr,
                      value: _endHour,
                      items: List.generate(
                        24,
                        (hour) => DropdownMenuItem(
                          value: hour,
                          child: Text(_hourLabel(hour)),
                        ),
                      ),
                      onChanged: (value) => setState(() {
                        _endHour = value!;
                        _error = null;
                      }),
                    ),
                  ),
                ],
              )
            else if (period == AnalyticsPeriod.week)
              Row(
                children: [
                  Expanded(
                    child: _weekdayDropdown(
                      label: 'analytics_filter_start_day'.tr,
                      value: _startDay,
                      onChanged: (value) => setState(() {
                        _startDay = value!;
                        _error = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _weekdayDropdown(
                      label: 'analytics_filter_end_day'.tr,
                      value: _endDay,
                      onChanged: (value) => setState(() {
                        _endDay = value!;
                        _error = null;
                      }),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickMonthRange,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  '${MaterialLocalizations.of(context).formatMediumDate(_monthRange.start)} – ${MaterialLocalizations.of(context).formatMediumDate(_monthRange.end)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt),
                  label: Text('analytics_filter_reset'.tr),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _apply,
                  icon: const Icon(Icons.check),
                  label: Text('analytics_filter_apply'.tr),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekdayDropdown({
    required String label,
    required int value,
    required ValueChanged<int?> onChanged,
  }) => _dropdown<int>(
    label: label,
    value: value,
    items: List.generate(
      7,
      (index) => DropdownMenuItem(
        value: index + 1,
        child: Text('weekday_${index + 1}'.tr),
      ),
    ),
    onChanged: onChanged,
  );

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    items: items,
    onChanged: onChanged,
  );
}

// ── Scrollable body ───────────────────────────────────────────────────────────
class _Body extends GetView<AnalyticsController> {
  @override
  Widget build(BuildContext context) => Obx(
    () => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.isLoading.value) const LinearProgressIndicator(),
          if (!controller.hasMonthlyAdjustments)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'analytics_adjustments_missing'.tr,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          SectionLabel('analytics_summary'.tr),
          _KpiGrid(),
          SectionLabel('analytics_power_trend'.tr),
          _PowerTrend(),
          SectionLabel(_peakSectionTitle(controller.selectedPeriod.value).tr),
          _PeakHours(
            title: _peakSectionTitle(controller.selectedPeriod.value).tr,
          ),
          SectionLabel('analytics_consumption'.tr),
          _ComparisonChart(),
          SectionLabel('analytics_estimated_cost'.tr),
          _CostChart(),
        ],
      ),
    ),
  );
}

// ── KPI grid ─────────────────────────────────────────────────────────────────
class _KpiGrid extends GetView<AnalyticsController> {
  @override
  Widget build(BuildContext context) => Obx(() {
    final s = controller.summary.value;
    if (s == null) return const SizedBox.shrink();
    if (s.daysWithReadings == 0) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('analytics_no_history'.tr),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.50,
      children: [
        KpiCard(
          label: 'analytics_kpi_total_units'.tr,
          value: '${s.totalKwh.toStringAsFixed(1)} kWh',
          delta: s.hasPreviousData
              ? '${controller.deltaLabel(s.kwhDeltaPct)} ${'analytics_vs_prev'.trParams({'period': controller.periodLabelLower})}'
              : 'analytics_no_previous'.tr,
          deltaIsGood: !controller.isPositiveDelta(s.kwhDeltaPct),
        ),
        KpiCard(
          label: 'analytics_kpi_avg_cost'.tr,
          value: 'Rs. ${s.avgDailyCostRs.toStringAsFixed(0)}',
          delta: s.hasPreviousData
              ? '${controller.deltaLabel(s.costDeltaPct)} ${'analytics_vs_prev'.trParams({'period': controller.periodLabelLower})}'
              : 'analytics_no_previous'.tr,
          deltaIsGood: !controller.isPositiveDelta(s.costDeltaPct),
        ),
        KpiCard(
          label: 'analytics_kpi_highest_use'.tr,
          value: '${s.maxDailyKwh.toStringAsFixed(1)} kWh',
          delta: s.maxDailyLabel,
          deltaIsGood: true,
        ),
        KpiCard(
          label: 'analytics_kpi_days_readings'.tr,
          value: '${s.daysWithReadings}',
          delta: 'analytics_in_period'.trParams({
            'period': controller.periodLabelLower,
          }),
          deltaIsGood: true,
        ),
      ],
    );
  });
}

// ── Power trend (period-aware: hours/days/weeks) ─────────────────────────
class _PowerTrend extends GetView<AnalyticsController> {
  @override
  Widget build(BuildContext context) => Obx(() {
    final data = controller.trendPoints.toList();
    final dataPoints = data.where((p) => p.hasData).toList();
    if (data.isEmpty || dataPoints.isEmpty) {
      // Koi complete slot nahi — data collect ho raha hai (hint dikhe).
      return _HourlyMissingHint();
    }
    final peak = dataPoints.reduce((a, b) => a.value >= b.value ? a : b);
    final value = peak.value.toStringAsFixed(1);
    final label = 'analytics_peak_at'.trParams({'point': peak.label});
    return PowerTrendChart(
      data: data,
      maxValue: peak.value <= 0 ? 1.0 : peak.value,
      peakLabel: '$value kWh · $label',
    );
  });
}

// ── Peak hours heatmap ─────────────────────────────────────────────────
class _PeakHours extends GetView<AnalyticsController> {
  final String title;

  const _PeakHours({required this.title});

  @override
  Widget build(BuildContext context) => Obx(() {
    final cells = controller.heatmap.toList();
    if (cells.isEmpty) return _HourlyMissingHint();
    return PeakHoursHeatmap(
      cells: cells,
      title: title,
      isMonthView: controller.selectedPeriod.value == AnalyticsPeriod.month,
    );
  });
}

/// Peak section ka title period ke hisaab se:
/// Day → Peak hours, Week → Peak days, Month → Peak weeks
String _peakSectionTitle(AnalyticsPeriod period) {
  switch (period) {
    case AnalyticsPeriod.day:
      return 'analytics_peak_hours';
    case AnalyticsPeriod.week:
      return 'analytics_peak_days';
    case AnalyticsPeriod.month:
      return 'analytics_peak_weeks';
  }
}

class _HourlyMissingHint extends GetView<AnalyticsController> {
  const _HourlyMissingHint();

  /// Message period ke hisaab se — kab tak ka wait hai:
  /// Day → ~1 ghanta, Week → kal (pehla din complete), Month → kuch din
  String get _message {
    final when = switch (controller.selectedPeriod.value) {
      AnalyticsPeriod.day => 'analytics_when_hour'.tr,
      AnalyticsPeriod.week => 'analytics_when_day'.tr,
      AnalyticsPeriod.month => 'analytics_when_week'.tr,
    };
    return 'analytics_data_collecting'.trParams({'when': when});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Text(_message, style: TextStyle(color: kMuted, fontSize: 13)),
    );
  }
}

// ── Comparison bar chart ──────────────────────────────────────────────────────
class _ComparisonChart extends GetView<AnalyticsController> {
  @override
  Widget build(BuildContext context) => Obx(() {
    final data = controller.dailyStats.toList();
    return ComparisonBarChart(
      data: data,
      maxKwh: controller.maxKwh,
      currentLabel: 'analytics_this_period'.trParams({
        'period': controller.periodLabelLower,
      }),
    );
  });
}

// ── Cost chart ────────────────────────────────────────────────────────────────
class _CostChart extends GetView<AnalyticsController> {
  @override
  Widget build(BuildContext context) => Obx(() {
    final data = controller.dailyStats.toList();
    return CostBarChart(
      data: data,
      maxCost: controller.maxCost,
      totalCost: controller.weekTotalCost,
    );
  });
}

// ── Bottom nav ────────────────────────────────────────────────────────────────
class _BottomNav extends GetView<AnalyticsController> {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kCard,
      border: Border(top: BorderSide(color: kBorder, width: 0.5)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            AppBottomNavItem(
              Icons.dashboard_rounded,
              'nav_dashboard'.tr,
              false,
              () => Get.offNamed('/dashboard', arguments: Get.arguments),
            ),
            AppBottomNavItem(
              Icons.show_chart_rounded,
              'nav_analytics'.tr,
              true,
              () {},
            ),
            AppBottomNavItem(
              Icons.receipt_long_rounded,
              'nav_bills'.tr,
              false,
              () => Get.toNamed('/bills', arguments: Get.arguments),
            ),
            AppBottomNavItem(
              Icons.settings_rounded,
              'nav_settings'.tr,
              false,
              () => Get.toNamed(AppRoutes.settings, arguments: Get.arguments),
            ),
          ],
        ),
      ),
    ),
  );
}

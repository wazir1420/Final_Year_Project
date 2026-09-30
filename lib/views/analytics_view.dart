import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/analytics_controller.dart';
import '../controllers/theme_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/analytics_widgets.dart';
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
          _PeakHours(title: _peakSectionTitle(controller.selectedPeriod.value).tr),
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
    return PeakHoursHeatmap(cells: cells, title: title);
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
            _NavItem(
              Icons.dashboard_rounded,
              'nav_dashboard'.tr,
              false,
              () => Get.offNamed('/dashboard', arguments: Get.arguments),
            ),
            _NavItem(Icons.show_chart_rounded, 'nav_analytics'.tr, true, () {}),
            _NavItem(
              Icons.receipt_long_rounded,
              'nav_bills'.tr,
              false,
              () => Get.toNamed('/bills', arguments: Get.arguments),
            ),
            _NavItem(
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem(this.icon, this.label, this.isActive, this.onTap);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? kBlue : kMuted;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

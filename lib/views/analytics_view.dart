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
  void didPopNext() => setState(() {});

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
                  'Analytics',
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
                tooltip: 'Back',
              ),
            ],
          ),
        ),
        // Period tab bar
        Obx(
          () => PeriodTabBar(
            selected: controller.periodLabel,
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
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Summary'),
        _KpiGrid(),
        const SectionLabel('Consumption'),
        _ComparisonChart(),
        const SectionLabel('Power trend'),
        _TrendChart(),
        const SectionLabel('Peak hours'),
        _Heatmap(),
        const SectionLabel('Cost'),
        _CostChart(),
      ],
    ),
  );
}

// ── KPI grid ─────────────────────────────────────────────────────────────────
class _KpiGrid extends GetView<AnalyticsController> {
  @override
  Widget build(BuildContext context) => Obx(() {
    final s = controller.summary.value;
    if (s == null) return const SizedBox.shrink();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.50,
      children: [
        KpiCard(
          label: 'Total units',
          value: '${s.totalKwh.toStringAsFixed(1)} kWh',
          delta:
              '${controller.deltaLabel(s.kwhDeltaPct)} vs prev ${controller.periodLabel.toLowerCase()}',
          deltaIsGood: !controller.isPositiveDelta(s.kwhDeltaPct),
        ),
        KpiCard(
          label: 'Avg daily cost',
          value: 'Rs. ${s.avgDailyCostRs.toStringAsFixed(0)}',
          delta:
              '${controller.deltaLabel(s.costDeltaPct)} vs prev ${controller.periodLabel.toLowerCase()}',
          deltaIsGood: !controller.isPositiveDelta(s.costDeltaPct),
        ),
        KpiCard(
          label: 'Peak demand',
          value: '${s.peakKw.toStringAsFixed(1)} kW',
          delta: s.peakLabel,
          deltaIsGood: true,
        ),
        KpiCard(
          label: 'Avg power factor',
          value: s.avgPowerFactor.toStringAsFixed(2),
          delta: s.avgPowerFactor >= 0.9 ? '↑ Good' : '↓ Low',
          deltaIsGood: s.avgPowerFactor >= 0.9,
        ),
      ],
    );
  });
}

// ── Comparison bar chart ──────────────────────────────────────────────────────
class _ComparisonChart extends GetView<AnalyticsController> {
  @override
  Widget build(BuildContext context) => Obx(() {
    final data = controller.dailyStats.toList();
    return ComparisonBarChart(
      data: data,
      maxKwh: controller.maxKwh,
      currentLabel: 'This ${controller.periodLabel.toLowerCase()}',
    );
  });
}

// ── Power trend line ──────────────────────────────────────────────────────────
class _TrendChart extends GetView<AnalyticsController> {
  @override
  Widget build(BuildContext context) => Obx(() {
    final s = controller.summary.value;
    final trendData = controller.hourlyTrend.toList();
    return PowerTrendChart(
      data: trendData,
      maxKw: controller.maxKw,
      peakLabel:
          '${s?.peakKw.toStringAsFixed(1) ?? '--'} kW · ${s?.peakLabel ?? ''}',
    );
  });
}

// ── Heatmap ───────────────────────────────────────────────────────────────────
class _Heatmap extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Obx(() {
    final cells = Get.find<AnalyticsController>().heatmapCells.toList();
    return PeakHoursHeatmap(cells: cells);
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
              'Dashboard',
              false,
              () => Get.offNamed('/dashboard'),
            ),
            _NavItem(Icons.show_chart_rounded, 'Analytics', true, () {}),
            _NavItem(
              Icons.receipt_long_rounded,
              'Bills',
              false,
              () => Get.toNamed('/bills'),
            ),
            _NavItem(
              Icons.settings_rounded,
              'Settings',
              false,
              () => Get.toNamed(AppRoutes.settings),
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

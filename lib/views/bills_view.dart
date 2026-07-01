import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bills_controller.dart';
import '../controllers/theme_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/bills_widgets.dart';
import '../services/route_observer.dart';

class BillsView extends StatefulWidget {
  const BillsView({super.key});

  @override
  State<BillsView> createState() => _BillsViewState();
}

class _BillsViewState extends State<BillsView> with RouteAware {
  final controller = Get.find<BillsController>();

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
        child: Column(
          children: [
            _Header(),
            Expanded(child: _Body()),
            _BottomNav(),
          ],
        ),
      ),
    );
  }
}

class _Header extends GetView<BillsController> {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
    decoration: BoxDecoration(
      color: kCard,
      border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Bill',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: kPrimary,
          ),
        ),
        Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: controller.prevMonth,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 22,
                    color: kMuted,
                  ),
                ),
              ),
              Text(
                controller.selectedMonth.value.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kPrimary,
                ),
              ),
              GestureDetector(
                onTap: controller.nextMonth,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: controller.canGoNext
                        ? kMuted
                        : const Color(0xFFD0D0D0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Body extends GetView<BillsController> {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('This month'),
        _HeroCard(),
        const SectionLabel('Invoice breakdown'),
        _Invoice(),
        const SectionLabel('Daily cost'),
        _DailyChart(),
        const SizedBox(height: 10),
        const SectionLabel('Monthly comparison'),
        _ComparisonChart(),
        const SizedBox(height: 28),
      ],
    ),
  );
}

class _HeroCard extends GetView<BillsController> {
  @override
  Widget build(BuildContext context) => Obx(() {
    final b = controller.bill.value;
    if (b == null) return const SizedBox.shrink();
    return BillHeroCard(
      monthLabel: b.period.shortLabel,
      totalRs: b.totalRs,
      progressLabel: controller.cycleProgressLabel,
      cycleProgress: b.cycleProgress,
      daysRemaining: b.daysRemainingInCycle,
      dueDateLabel: controller.dueDateLabel,
      isPaid: b.isPaid,
    );
  });
}

class _Invoice extends GetView<BillsController> {
  @override
  Widget build(BuildContext context) => Obx(() {
    final b = controller.bill.value;
    if (b == null) return const SizedBox.shrink();
    return InvoiceCard(
      monthLabel: b.period.label,
      items: b.lineItems,
      totalRs: b.totalRs,
    );
  });
}

class _DailyChart extends GetView<BillsController> {
  @override
  Widget build(BuildContext context) => Obx(
    () => DailyCostChart(
      data: controller.displayedDailyCosts,
      maxCost: controller.maxDailyCost,
      avgCost: controller.avgDailyCost,
    ),
  );
}

class _ComparisonChart extends GetView<BillsController> {
  @override
  Widget build(BuildContext context) => Obx(
    () => MonthComparisonChart(
      data: controller.comparisons,
      maxTotal: controller.maxComparisonTotal,
      avgTotal: controller.avgMonthlyBill,
      currentMonth: controller.selectedMonth.value,
    ),
  );
}

class _BottomNav extends StatelessWidget {
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
            _NavItem(
              Icons.show_chart_rounded,
              'Analytics',
              false,
              () => Get.offNamed('/analytics'),
            ),
            _NavItem(Icons.receipt_long_rounded, 'Bills', true, () {}),
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

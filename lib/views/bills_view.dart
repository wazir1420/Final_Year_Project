import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bills_controller.dart';
import '../controllers/theme_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/bills_widgets.dart';
import '../widgets/app_bottom_nav_item.dart';
import '../widgets/ke_tariff_settings_sheet.dart';
import '../services/route_observer.dart';

void _showTariffSettings(BillsController controller) {
  Get.bottomSheet(
    KETariffSettingsSheet(controller: controller),
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
  );
}

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
          'bills_title'.tr,
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
  Widget build(BuildContext context) => Obx(() {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.dailyCosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('bills_no_history'.tr),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('bills_selected_month'.tr),
          if (!controller.hasMonthlyAdjustments)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'bills_adjustments_missing'.tr,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showTariffSettings(controller),
                      child: Text('bills_set_tariff'.tr),
                    ),
                  ],
                ),
              ),
            ),
          _HeroCard(),
          SectionLabel('bills_invoice_breakdown'.tr),
          _Invoice(),
          SectionLabel('bills_daily_cost'.tr),
          _DailyChart(),
          const SizedBox(height: 10),
          SectionLabel('bills_monthly_comparison'.tr),
          _ComparisonChart(),
          const SizedBox(height: 28),
        ],
      ),
    );
  });
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

// ── Bottom nav ────────────────────────────────────────────────────────────────
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
            AppBottomNavItem(
              Icons.dashboard_rounded,
              'nav_dashboard'.tr,
              false,
              () => Get.offNamed('/dashboard', arguments: Get.arguments),
            ),
            AppBottomNavItem(
              Icons.show_chart_rounded,
              'nav_analytics'.tr,
              false,
              () => Get.offNamed('/analytics', arguments: Get.arguments),
            ),
            AppBottomNavItem(
              Icons.receipt_long_rounded,
              'nav_bills'.tr,
              true,
              () {},
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_widgets.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: _Header(),
      ),
      body: SafeArea(
        top: false,
        child: Obx(
          () => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator(color: kBlue))
              : _Body(),
        ),
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends GetView<DashboardController> {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning',
                style: TextStyle(fontSize: 13, color: kMuted),
              ),
              const SizedBox(height: 2),
              const Text(
                'Energy Monitor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => controller.isLive.value
                    ? const LiveBadge()
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        Column(
          children: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: kMuted, size: 20),
              onPressed: controller.refreshData,
              tooltip: 'Refresh',
            ),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: kBlueTint,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'SM',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ── Scrollable body ───────────────────────────────────────────────────────────
class _Body extends GetView<DashboardController> {
  @override
  Widget build(BuildContext context) => Obx(
    () => IndexedStack(
      index: controller.selectedTab.value,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Total consumption'),
              _PowerCard(),
              const SectionLabel('Phase parameters'),
              _PhaseGrid(),
              const SectionLabel('This month'),
              _BarChart(),
              const SizedBox(height: 10),
              const SectionLabel('Bill estimate'),
              _BillCard(),
              const SizedBox(height: 10),
              _MlBadge(),
              const SizedBox(height: 28),
            ],
          ),
        ),
        const _AnalyticsTab(),
        const _BillsTab(),
        const _SettingsTab(),
      ],
    ),
  );
}

// ── Power hero card ───────────────────────────────────────────────────────────
class _PowerCard extends GetView<DashboardController> {
  @override
  Widget build(BuildContext context) => Obx(() {
    final m = controller.meterData.value;
    return PowerHeroCard(
      activePower: m.activePower,
      avgVoltage: m.avgVoltage,
      totalCurrent: m.totalCurrent,
      powerFactor: m.powerFactor,
      frequency: m.frequency,
    );
  });
}

// ── Phase grid ────────────────────────────────────────────────────────────────
class _PhaseGrid extends GetView<DashboardController> {
  @override
  Widget build(BuildContext context) => Obx(() {
    final m = controller.meterData.value;
    return Row(
      children: [
        Expanded(
          child: PhaseParamCard(
            icon: Icons.bolt_rounded,
            iconBg: kBlueTint,
            iconColor: kBlue,
            label: 'Voltage',
            value: m.avgVoltage.toStringAsFixed(0),
            unit: 'V',
            l1: m.voltageL1,
            l2: m.voltageL2,
            l3: m.voltageL3,
            fmt: (v) => v.toStringAsFixed(0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PhaseParamCard(
            icon: Icons.electric_meter_rounded,
            iconBg: kAmberTint,
            iconColor: kAmber,
            label: 'Current',
            value: m.totalCurrent.toStringAsFixed(1),
            unit: 'A',
            l1: m.currentL1,
            l2: m.currentL2,
            l3: m.currentL3,
            fmt: (v) => v.toStringAsFixed(1),
          ),
        ),
      ],
    );
  });
}

// ── Bar chart ─────────────────────────────────────────────────────────────────
class _BarChart extends GetView<DashboardController> {
  @override
  Widget build(BuildContext context) =>
      Obx(() => DailyBarChart(data: controller.dailyUsage.toList()));
}

// ── Bill card ─────────────────────────────────────────────────────────────────
class _BillCard extends GetView<DashboardController> {
  @override
  Widget build(BuildContext context) => Obx(() {
    final b = controller.bill.value;
    return BillEstimateCard(
      units: b.formattedUnits,
      rate: b.formattedRate,
      fixed: b.formattedFixed,
      taxes: b.formattedTaxes,
      total: b.formattedTotal,
    );
  });
}

// ── Analytics tab ─────────────────────────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Analytics'),
        const SizedBox(height: 12),
        Row(
          children: const [
            _AnalyticsMetricCard(
              title: 'Monthly use',
              value: '185 kWh',
              subtitle: 'this month',
            ),
            SizedBox(width: 10),
            _AnalyticsMetricCard(
              title: 'Peak day',
              value: '26.4 kWh',
              subtitle: 'day 22',
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionLabel('Usage trend'),
        const SizedBox(height: 12),
        _BarChart(),
        const SizedBox(height: 18),
        const SectionLabel('Forecast'),
        const SizedBox(height: 12),
        const _AnalyticsInfoCard(
          title: 'Projected bill',
          description: 'Your expected bill is based on month-to-date usage.',
        ),
      ],
    ),
  );
}

// ── Bills tab ─────────────────────────────────────────────────────────────────
class _BillsTab extends StatelessWidget {
  const _BillsTab();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Bills'),
        const SizedBox(height: 12),
        const _BillSummaryCard(),
        const SizedBox(height: 18),
        const SectionLabel('Payment details'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder, width: 0.5),
          ),
          child: Column(
            children: const [
              ListTile(
                leading: Icon(Icons.calendar_today_rounded, color: kBlue),
                title: Text('Due date'),
                subtitle: Text('5 July 2026'),
              ),
              Divider(height: 1, color: kBorder),
              ListTile(
                leading: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: kAmber,
                ),
                title: Text('Last payment'),
                subtitle: Text('Rs. 2,920 on 10 June'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Settings tab ──────────────────────────────────────────────────────────────
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Settings'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder, width: 0.5),
          ),
          child: Column(
            children: const [
              _SettingsTile(
                icon: Icons.notifications_rounded,
                title: 'Live updates',
                subtitle: 'Refresh meter readings automatically',
              ),
              Divider(height: 1, color: kBorder),
              _SettingsTile(
                icon: Icons.sync_rounded,
                title: 'Auto refresh',
                subtitle: 'Every 2 seconds while dashboard is active',
              ),
              Divider(height: 1, color: kBorder),
              _SettingsTile(
                icon: Icons.person_rounded,
                title: 'Account',
                subtitle: 'SM · energy.monitor@example.com',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AnalyticsMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _AnalyticsMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: kMuted)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: kSecondary),
          ),
        ],
      ),
    ),
  );
}

class _AnalyticsInfoCard extends StatelessWidget {
  final String title;
  final String description;

  const _AnalyticsInfoCard({required this.title, required this.description});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder, width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(description, style: const TextStyle(fontSize: 13, color: kMuted)),
      ],
    ),
  );
}

class _BillSummaryCard extends GetView<DashboardController> {
  const _BillSummaryCard();

  @override
  Widget build(BuildContext context) => Obx(() {
    final bill = controller.bill.value;
    return BillEstimateCard(
      units: bill.formattedUnits,
      rate: bill.formattedRate,
      fixed: bill.formattedFixed,
      taxes: bill.formattedTaxes,
      total: bill.formattedTotal,
    );
  });
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: kBlue),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 13, color: kMuted),
    ),
    trailing: const Icon(Icons.chevron_right_rounded, color: kMuted),
  );
}

// ── ML badge ──────────────────────────────────────────────────────────────────
class _MlBadge extends GetView<DashboardController> {
  @override
  Widget build(BuildContext context) => Obx(
    () => MlPredictionBadge(
      predictedBill: 'Rs. ${controller.mlPredicted.value.toStringAsFixed(0)}',
      changeLabel: controller.mlChangeLabel,
      isIncrease: controller.mlIsIncrease,
      onTap: controller.goToMlDetail,
    ),
  );
}

// ── Bottom nav ────────────────────────────────────────────────────────────────
class _BottomNav extends GetView<DashboardController> {
  @override
  Widget build(BuildContext context) => Obx(() {
    final selected = controller.selectedTab.value;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
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
                selected == 0,
                () => controller.selectTab(0),
              ),
              _NavItem(
                Icons.show_chart_rounded,
                'Analytics',
                selected == 1,
                controller.goToAnalytics,
              ),
              _NavItem(
                Icons.receipt_long_rounded,
                'Bills',
                selected == 2,
                controller.goToBills,
              ),
              _NavItem(
                Icons.settings_rounded,
                'Settings',
                selected == 3,
                controller.goToSettings,
              ),
            ],
          ),
        ),
      ),
    );
  });
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

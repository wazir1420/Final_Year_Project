import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/meters_list_controller.dart';
import '../models/meter_summary_model.dart';
import '../widgets/dashboard_widgets.dart';

class MetersListView extends GetView<MetersListController> {
  const MetersListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        title: Text('meters_title'.tr),
        elevation: 0,
        backgroundColor: kCard,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: kBlue));
        }
        if (controller.meters.isEmpty) {
          return Center(
            child: Text('meters_empty'.tr, style: TextStyle(color: kMuted)),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TotalCard(totalPower: controller.totalPower),
            const SizedBox(height: 16),
            ...controller.meters.map(
              (m) => _MeterCard(meter: m, onTap: () => controller.openMeter(m)),
            ),
          ],
        );
      }),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double totalPower;
  const _TotalCard({required this.totalPower});

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
          'meters_total_power'.tr,
          style: TextStyle(fontSize: 12, color: kMuted),
        ),
        const SizedBox(height: 6),
        Text(
          '${totalPower.toStringAsFixed(2)} kW',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: kPrimary,
          ),
        ),
      ],
    ),
  );
}

class _MeterCard extends StatelessWidget {
  final MeterSummary meter;
  final VoidCallback onTap;
  const _MeterCard({required this.meter, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: meter.isOnline
                  ? const Color(0xFF3B6D11)
                  : const Color(0xFF991F1F),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meter.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meter.isOnline
                      ? '${meter.activePower.toStringAsFixed(2)} kW · ${meter.avgVoltage.toStringAsFixed(0)} V'
                      : 'offline'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: meter.isOnline ? kMuted : const Color(0xFF991F1F),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: kMuted),
        ],
      ),
    ),
  );
}

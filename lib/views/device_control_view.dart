import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/device_control_controller.dart';
import '../models/device_status_model.dart';
import '../widgets/dashboard_widgets.dart';

class DeviceControlView extends GetView<DeviceControlController> {
  const DeviceControlView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kSurface,
    appBar: AppBar(
      title: Text('device_control'.tr),
      backgroundColor: kCard,
      actions: [
        Obx(
          () => IconButton(
            tooltip: 'refresh'.tr,
            onPressed: controller.isLoading.value
                ? null
                : controller.refreshDevices,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
    ),
    body: Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: kBlue));
      }

      return RefreshIndicator(
        color: kBlue,
        onRefresh: controller.refreshDevices,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _ConnectionStatus(isError: controller.hasError.value),
            const SizedBox(height: 8),
            ...controller.devices.map(
              (device) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _DeviceTile(
                  device: device,
                  isUpdating: controller.updatingDevices.contains(device.id),
                  onChanged: (value) =>
                      controller.setDeviceState(device, value),
                ),
              ),
            ),
          ],
        ),
      );
    }),
  );
}

class _ConnectionStatus extends StatelessWidget {
  final bool isError;

  const _ConnectionStatus({required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB42318) : kGreen;
    final background = isError ? const Color(0xFFFEF3F2) : kGreenTint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? kCard : background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
            size: 19,
            color: isError ? color : kGreenDot,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isError
                  ? 'device_connection_error'.tr
                  : 'device_connection_live'.tr,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final DeviceStatus device;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  const _DeviceTile({
    required this.device,
    required this.isUpdating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isWaiting = device.desiredState != device.appliedState;
    final isOn = device.appliedState;
    final accent = isOn ? kGreenDot : kMuted;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isOn ? kGreenTint : kBlueTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(device.icon, color: isOn ? kGreen : kBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.nameKey.tr,
                  style: TextStyle(
                    color: kPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isWaiting
                      ? 'device_waiting'.tr
                      : isOn
                      ? 'device_on'.tr
                      : 'device_off'.tr,
                  style: TextStyle(
                    color: isWaiting ? kAmber : accent,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'device_power_unavailable'.tr,
                  style: TextStyle(color: kMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: device.desiredState,
            onChanged: isUpdating ? null : onChanged,
            activeTrackColor: kGreenDot,
          ),
          if (isUpdating)
            const Padding(
              padding: EdgeInsets.only(left: 4, right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: kBlue),
              ),
            ),
        ],
      ),
    );
  }
}

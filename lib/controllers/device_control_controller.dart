import 'dart:async';

import 'package:get/get.dart';

import '../models/device_status_model.dart';
import '../services/firebase_device_service.dart';

class DeviceControlController extends GetxController {
  final FirebaseDeviceService _service = FirebaseDeviceService();
  final RxList<DeviceStatus> devices = FirebaseDeviceService.devices
      .toList()
      .obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxSet<String> updatingDevices = <String>{}.obs;
  Timer? _pollTimer;
  bool _isFetching = false;

  @override
  void onInit() {
    super.onInit();
    refreshDevices();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => refreshDevices(),
    );
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<void> refreshDevices() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final latest = await _service.fetchDevices();
      for (var index = 0; index < devices.length; index++) {
        final current = devices[index];
        final fetched = latest[current.id];
        if (fetched != null && !updatingDevices.contains(current.id)) {
          devices[index] = fetched;
        }
      }
      hasError.value = false;
    } catch (_) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
      _isFetching = false;
    }
  }

  Future<void> setDeviceState(DeviceStatus device, bool state) async {
    if (updatingDevices.contains(device.id)) return;
    final index = devices.indexWhere((item) => item.id == device.id);
    if (index < 0) return;

    final previousState = devices[index].desiredState;
    updatingDevices.add(device.id);
    devices[index] = devices[index].copyWith(desiredState: state);
    try {
      await _service.setDesiredState(device.id, state);
    } catch (_) {
      devices[index] = devices[index].copyWith(desiredState: previousState);
      Get.snackbar(
        'device_update_failed'.tr,
        'device_update_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      updatingDevices.remove(device.id);
    }
  }
}

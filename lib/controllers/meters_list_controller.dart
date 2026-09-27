import 'dart:async';
import 'package:get/get.dart';

import '../models/meter_summary_model.dart';
import '../services/firebase_meters_list_service.dart';
import '../routes/app_routes.dart';

class MetersListController extends GetxController {
  final FirebaseMetersListService _service = FirebaseMetersListService();

  final RxBool isLoading = true.obs;
  final RxList<MeterSummary> meters = <MeterSummary>[].obs;

  StreamSubscription<List<MeterSummary>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _load() async {
    meters.assignAll(await _service.fetchOnce());
    isLoading.value = false;

    _sub = _service.metersStream.listen((list) {
      meters.assignAll(list);
    });
  }

  void openMeter(MeterSummary meter) {
    Get.toNamed(
      AppRoutes.dashboard,
      arguments: {'meterId': meter.id, 'meterName': meter.name},
    );
  }

  double get totalPower => meters.fold(0.0, (sum, m) => sum + m.activePower);
}

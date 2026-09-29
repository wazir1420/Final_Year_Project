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

  List<String> get _assignedMeterIds {
    final arguments = Get.arguments;
    if (arguments is! Map) return [];
    final meterIds = arguments['meterIds'];
    if (meterIds is! Iterable) return [];
    return meterIds.whereType<String>().toList();
  }

  String get _userName {
    final arguments = Get.arguments;
    return arguments is Map ? arguments['userName']?.toString() ?? '' : '';
  }

  String get _userEmail {
    final arguments = Get.arguments;
    return arguments is Map ? arguments['userEmail']?.toString() ?? '' : '';
  }

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
    final meterIds = _assignedMeterIds;
    meters.assignAll(await _service.fetchOnce(meterIds));
    isLoading.value = false;

    _sub = _service.metersStream(meterIds).listen((list) {
      meters.assignAll(list);
    });
  }

  void openMeter(MeterSummary meter) {
    Get.toNamed(
      AppRoutes.dashboard,
      arguments: {
        'meterId': meter.id,
        'meterName': meter.name,
        'meterIds': _assignedMeterIds,
        'userName': _userName,
        'userEmail': _userEmail,
      },
    );
  }

  double get totalPower => meters.fold(0.0, (sum, m) => sum + m.activePower);
}

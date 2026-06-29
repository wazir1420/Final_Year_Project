import 'package:finalyearproject/models/bills_model.dart';
import 'package:get/get.dart';
import '../services/bills_dummy_service.dart';

class BillsController extends GetxController {
  final _service = BillsDummyService();

  late final Rx<BillMonth> selectedMonth;
  final Rxn<MonthBill> bill = Rxn();
  final RxList<DailyCost> dailyCosts = <DailyCost>[].obs;
  final RxList<MonthComparison> comparisons = <MonthComparison>[].obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    selectedMonth = BillMonth(year: now.year, month: now.month).obs;
    _load();
  }

  void prevMonth() {
    selectedMonth.value = selectedMonth.value.prev();
    _load();
  }

  void nextMonth() {
    if (!canGoNext) return;
    selectedMonth.value = selectedMonth.value.next();
    _load();
  }

  bool get canGoNext => !selectedMonth.value.isCurrentMonth;

  void _load() {
    bill.value = _service.getBill(selectedMonth.value);
    dailyCosts.value = _service.getDailyCosts(selectedMonth.value);
    comparisons.value = _service.getComparisons(count: 5);
  }

  String get cycleProgressLabel {
    final b = bill.value;
    if (b == null) return '';
    if (!b.period.isCurrentMonth) {
      return '${b.unitsKwh.toStringAsFixed(1)} kWh consumed';
    }
    return '${b.unitsKwh.toStringAsFixed(1)} / ~${b.projectedUnitsKwh.toStringAsFixed(0)} kWh projected';
  }

  String get dueDateLabel {
    final b = bill.value;
    if (b == null) return '';
    if (b.isPaid) return 'Paid';
    final d = b.dueDate;
    if (d == null) return '';
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Due ~${m[d.month]} ${d.day}';
  }

  bool get isBillPaid => bill.value?.isPaid ?? false;

  double get maxDailyCost {
    if (dailyCosts.isEmpty) return 1.0;
    return dailyCosts.map((d) => d.costRs).reduce((a, b) => a > b ? a : b);
  }

  double get maxComparisonTotal {
    if (comparisons.isEmpty) return 1.0;
    return comparisons.map((c) => c.totalRs).reduce((a, b) => a > b ? a : b);
  }

  double get avgDailyCost {
    if (dailyCosts.isEmpty) return 0;
    return dailyCosts.fold(0.0, (s, d) => s + d.costRs) / dailyCosts.length;
  }

  double get avgMonthlyBill {
    if (comparisons.isEmpty) return 0;
    return comparisons.fold(0.0, (s, c) => s + c.totalRs) / comparisons.length;
  }

  List<DailyCost> get displayedDailyCosts {
    if (dailyCosts.length <= 14) return dailyCosts;
    return dailyCosts.where((d) => d.day % 2 == 1).toList();
  }

  void goBack() => Get.back();
}

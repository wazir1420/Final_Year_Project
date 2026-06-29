import 'package:get/get.dart';
import '../controllers/bills_controller.dart';

class BillsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillsController>(() => BillsController());
  }
}

// ── Add to your AppRoutes.pages list ─────────────────────────────────────────
//
// GetPage(
//   name: '/bills',
//   page: () => const BillsView(),
//   binding: BillsBinding(),
//   transition: Transition.rightToLeft,
// ),

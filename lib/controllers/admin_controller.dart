import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/admin_service.dart';

class AdminController extends GetxController {
  final AdminService _service = AdminService();

  final RxBool isLoading = true.obs;
  final RxList<AdminCustomer> customers = <AdminCustomer>[].obs;
  final RxList<MeterRequest> pendingRequests = <MeterRequest>[].obs;

  final searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  // "Add customer" form ke fields
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final meterIdController = TextEditingController();
  final meterNameController = TextEditingController();
  final RxBool isSaving = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxString formError = ''.obs;
  String? _requestIdBeingAdded;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    loadData();
  }

  @override
  void onClose() {
    searchController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    meterIdController.dispose();
    meterNameController.dispose();
    super.onClose();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    customers.assignAll(await _service.fetchCustomers());
    pendingRequests.assignAll(await _service.fetchPendingRequests());
    isLoading.value = false;
  }

  /// Search box mein jo likha hai, usi ke hisaab se filtered list
  List<AdminCustomer> get filteredCustomers {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return customers;
    return customers.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  int get totalMeters => customers.fold(0, (sum, c) => sum + c.meterIds.length);

  void prepareNewCustomerForm() {
    _requestIdBeingAdded = null;
    isPasswordVisible.value = false;
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    meterIdController.clear();
    meterNameController.clear();
    formError.value = '';
  }

  void prepareCustomerFromRequest(MeterRequest request) {
    prepareNewCustomerForm();
    _requestIdBeingAdded = request.id;
    nameController.text = request.customerName;
    emailController.text = request.customerEmail;
  }

  Future<bool> deletePendingRequest(String requestId) async {
    try {
      await _service.deleteRequest(requestId);
      pendingRequests.removeWhere((request) => request.id == requestId);
      return true;
    } catch (e) {
      Get.snackbar(
        'Delete failed',
        e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> submitNewCustomer() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final meterId = meterIdController.text.trim();
    final meterName = meterNameController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || meterId.isEmpty) {
      formError.value = 'Naam, email, password, aur meter ID zaroori hain';
      return false;
    }

    isSaving.value = true;
    formError.value = '';

    try {
      await _service.createCustomerWithMeter(
        name: name,
        email: email,
        password: password,
        meterId: meterId,
        meterName: meterName.isEmpty ? meterId : meterName,
      );
      final requestId = _requestIdBeingAdded;
      if (requestId != null) {
        await _service.markRequestFulfilled(requestId);
        _requestIdBeingAdded = null;
      }

      // Form clear karein aur list refresh karein
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      meterIdController.clear();
      meterNameController.clear();
      await loadData();

      isSaving.value = false;
      return true;
    } catch (e) {
      formError.value = e.toString().replaceFirst('Exception: ', '');
      isSaving.value = false;
      return false;
    }
  }

  Future<void> fulfilRequest(
    MeterRequest request,
    String meterId,
    String meterName,
  ) async {
    await _service.addMeterToCustomer(
      customerUid: request.customerUid,
      meterId: meterId,
      meterName: meterName.isEmpty ? meterId : meterName,
    );
    await _service.markRequestFulfilled(request.id);
    await loadData();
  }
}

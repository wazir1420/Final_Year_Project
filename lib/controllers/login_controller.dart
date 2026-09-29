import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/access_request_service.dart';
import '../routes/app_routes.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final requestNameController = TextEditingController();
  final requestEmailController = TextEditingController();
  final requestMessageController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isRequestSubmitting = false.obs;
  final RxString requestError = ''.obs;
  final AccessRequestService _accessRequestService = AccessRequestService();

  Future<bool> submitAccessRequest() async {
    final name = requestNameController.text.trim();
    final email = requestEmailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      requestError.value = 'Name and email are required';
      return false;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      requestError.value = 'Enter a valid email address';
      return false;
    }

    isRequestSubmitting.value = true;
    requestError.value = '';
    try {
      await _accessRequestService.submit(
        name: name,
        email: email,
        message: requestMessageController.text.trim(),
      );
      requestNameController.clear();
      requestEmailController.clear();
      requestMessageController.clear();
      return true;
    } catch (e) {
      requestError.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isRequestSubmitting.value = false;
    }
  }

  Future<void> signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      errorMessage.value = 'Email aur password dono dalein';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final uid = await _authService.signIn(email, password);

      final profile = await _authService.fetchUserProfile(uid);

      if (profile == null) {
        errorMessage.value =
            'Account mila lekin profile set nahi hai — Admin se rabta karein';
        isLoading.value = false;
        return;
      }

      final displayName = profile.name.trim().isNotEmpty
          ? profile.name.trim()
          : email.split('@').first;
      final displayEmail = profile.email.trim().isNotEmpty
          ? profile.email.trim()
          : email;

      if (profile.isAdmin) {
        Get.offAllNamed(AppRoutes.adminPanel);
      } else if (profile.meterIds.length == 1) {
        // Sirf 1 meter hai to seedha Dashboard khol dein
        Get.offAllNamed(
          AppRoutes.dashboard,
          arguments: {
            'meterId': profile.meterIds.first,
            'meterName': '',
            'meterIds': profile.meterIds,
            'userName': displayName,
            'userEmail': displayEmail,
          },
        );
      } else {
        // 1 se zyada (ya 0) meters hain to Meters List dikhayein
        Get.offAllNamed(
          AppRoutes.metersList,
          arguments: {
            'meterIds': profile.meterIds,
            'userName': displayName,
            'userEmail': displayEmail,
          },
        );
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    requestNameController.dispose();
    requestEmailController.dispose();
    requestMessageController.dispose();
    super.onClose();
  }
}

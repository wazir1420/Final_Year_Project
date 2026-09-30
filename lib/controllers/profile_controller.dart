import 'dart:convert';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/firebase_meters_list_service.dart';

class ProfileController extends GetxController {
  final userName = ''.obs;
  final userEmail = ''.obs;
  final userId = ''.obs;
  final accountRole = ''.obs;
  final meterIds = <String>[].obs;
  final meterNames = <String, String>{}.obs;
  final profilePhoto = ''.obs;
  final isLoading = true.obs;
  final isUploading = false.obs;

  final AuthService _authService = AuthService();
  final FirebaseMetersListService _metersService = FirebaseMetersListService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    if (arguments is Map) {
      userName.value = arguments['userName']?.toString() ?? '';
      userEmail.value = arguments['userEmail']?.toString() ?? '';
    }
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final uid = await _authService.getCurrentUid();
      if (uid.isNotEmpty) {
        userId.value = uid;
        final profile = await _authService.fetchUserProfile(uid);
        if (profile != null) {
          if (profile.name.trim().isNotEmpty) {
            userName.value = profile.name.trim();
          }
          if (profile.email.trim().isNotEmpty) {
            userEmail.value = profile.email.trim();
          }
          accountRole.value = profile.role;
          meterIds.assignAll(profile.meterIds);
          if (profile.meterIds.isNotEmpty) {
            final meters = await _metersService.fetchOnce(profile.meterIds);
            meterNames.assignAll({
              for (final meter in meters) meter.id: meter.name,
            });
          }
          profilePhoto.value = profile.profilePhoto;
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndUploadPhoto() async {
    if (isUploading.value) return;
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 35,
      );
      if (image == null) return;

      final uid = await _authService.getCurrentUid();
      if (uid.isEmpty) {
        throw Exception('profile_error_session_expired'.tr);
      }

      isUploading.value = true;
      final photoBase64 = base64Encode(await image.readAsBytes());
      await _authService.updateProfilePhoto(uid, photoBase64);
      profilePhoto.value = photoBase64;
      Get.back(result: photoBase64);
    } catch (error) {
      Get.snackbar(
        'profile_error_upload_title'.tr,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isUploading.value = false;
    }
  }
}

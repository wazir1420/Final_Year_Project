import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';

const kNavy = Color(0xFF0C2340);
const kBlueAccent = Color(0xFF378ADD);
const kMutedText = Color(0xFF8A8F98);
const kBorderLight = Color(0xFFE2E5EA);

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorderLight, width: 0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: kNavy,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: kBlueAccent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 18),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: 'Power',
                          style: TextStyle(color: Color(0xFF0B0F19)),
                        ),
                        TextSpan(
                          text: 'Insight',
                          style: TextStyle(color: kBlueAccent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'login_subtitle'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      color: kMutedText,
                    ),
                  ),
                  const SizedBox(height: 22),

                  _FieldLabel('login_email_label'.tr),
                  const SizedBox(height: 4),
                  TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('name@example.com'),
                  ),
                  const SizedBox(height: 14),

                  _FieldLabel('login_password_label'.tr),
                  const SizedBox(height: 4),
                  Obx(
                    () => TextField(
                      controller: controller.passwordController,
                      obscureText: !controller.isPasswordVisible.value,
                      decoration: _inputDecoration(
                        'login_password_hint'.tr,
                        suffixIcon: IconButton(
                          tooltip: controller.isPasswordVisible.value
                              ? 'common_hide_password'.tr
                              : 'common_show_password'.tr,
                          onPressed: controller.isPasswordVisible.toggle,
                          icon: Icon(
                            controller.isPasswordVisible.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => controller.signIn(),
                    ),
                  ),

                  Obx(() {
                    if (controller.errorMessage.value.isEmpty) {
                      return const SizedBox(height: 20);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Text(
                        controller.errorMessage.value,
                        style: const TextStyle(
                          color: Color(0xFF991F1F),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }),

                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'login_sign_in'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _showAccessRequestForm,
                    style: TextButton.styleFrom(
                      foregroundColor: kMutedText,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(
                      'login_contact_provider'.tr,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: kMutedText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kBlueAccent),
        ),
      );

  void _showAccessRequestForm() {
    controller.requestError.value = '';
    Get.dialog<void>(
      AlertDialog(
        title: Text('login_request_access'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller.requestNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              TextField(
                controller: controller.requestEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: controller.requestMessageController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'login_message_optional'.tr,
                ),
              ),
              Obx(() {
                if (controller.requestError.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    controller.requestError.value,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
          Obx(
            () => FilledButton(
              onPressed: controller.isRequestSubmitting.value
                  ? null
                  : () async {
                      if (await controller.submitAccessRequest()) {
                        Get.back();
                        await Get.dialog<void>(
                          AlertDialog(
                            title: Text('login_request_sent_title'.tr),
                            content: Text('login_request_sent_msg'.tr),
                            actions: [
                              TextButton(
                                onPressed: Get.back,
                                child: Text('common_ok'.tr),
                              ),
                            ],
                          ),
                        );
                      }
                    },
              child: controller.isRequestSubmitting.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('login_send_request'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: kMutedText,
        letterSpacing: 0.5,
      ),
    ),
  );
}

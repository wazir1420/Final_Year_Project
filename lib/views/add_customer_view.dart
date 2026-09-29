import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';

const _kBlueAccent = Color(0xFF378ADD);
const _kMutedText = Color(0xFF8A8F98);
const _kBorderLight = Color(0xFFE2E5EA);

class AddCustomerView extends GetView<AdminController> {
  const AddCustomerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        title: const Text('Add customer'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0B0F19),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorderLight, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('CUSTOMER NAME'),
              _field(controller.nameController, 'e.g. Ahmed Khan'),
              const SizedBox(height: 14),

              const _Label('EMAIL'),
              Obx(
                () => _field(
                  controller.emailController,
                  'customer@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  errorText: controller.emailError.value.isEmpty
                      ? null
                      : controller.emailError.value,
                  onChanged: controller.validateCustomerEmail,
                ),
              ),
              const SizedBox(height: 14),

              const _Label('PASSWORD'),
              Obx(
                () => _field(
                  controller.passwordController,
                  'Kam az kam 6 characters',
                  obscure: !controller.isPasswordVisible.value,
                  suffixIcon: IconButton(
                    tooltip: controller.isPasswordVisible.value
                        ? 'Hide password'
                        : 'Show password',
                    onPressed: controller.isPasswordVisible.toggle,
                    icon: Icon(
                      controller.isPasswordVisible.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Divider(color: _kBorderLight),
              const SizedBox(height: 10),
              const Text(
                'Pehla meter',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              const _Label('METER ID'),
              _field(
                controller.meterIdController,
                'e.g. meter1 (ESP32 code mein bhi yahi ID hona chahiye)',
              ),
              const SizedBox(height: 14),

              const _Label('METER NAAM (OPTIONAL)'),
              _field(
                controller.meterNameController,
                'e.g. ABB B24 - Main line',
              ),

              Obx(() {
                if (controller.formError.value.isEmpty) {
                  return const SizedBox(height: 20);
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Text(
                    controller.formError.value,
                    style: const TextStyle(
                      color: Color(0xFF991F1F),
                      fontSize: 12,
                    ),
                  ),
                );
              }),

              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : () async {
                            final success = await controller
                                .submitNewCustomer();
                            if (success) {
                              await Get.dialog<void>(
                                AlertDialog(
                                  title: const Text(
                                    'Customer added successfully',
                                  ),
                                  content: const Text(
                                    'The customer account and meter were added.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: Get.back,
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              Get.back();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: controller.isSaving.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create customer',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: _kMutedText),
        errorText: errorText,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBlueAccent),
        ),
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      color: _kMutedText,
      letterSpacing: 0.5,
    ),
  );
}

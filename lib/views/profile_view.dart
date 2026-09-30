import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  ImageProvider<Object>? _photo(String value) {
    if (value.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(value));
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('profile_title'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final photo = _photo(controller.profilePhoto.value);
        final role = controller.accountRole.value;
        final roleLabel = role.isEmpty
            ? 'profile_account'.tr
            : role == 'admin'
            ? 'profile_role_admin'.tr
            : 'profile_role_customer'.tr;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: colors.surfaceContainerHighest,
                  backgroundImage: photo,
                  child: photo == null
                      ? Icon(Icons.person, size: 56, color: colors.primary)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  controller.userName.value.isEmpty
                      ? 'profile_no_name'.tr
                      : controller.userName.value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  controller.userEmail.value.isEmpty
                      ? 'profile_no_email'.tr
                      : controller.userEmail.value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  roleLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colors.primary),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: controller.isUploading.value
                      ? null
                      : controller.pickAndUploadPhoto,
                  icon: controller.isUploading.value
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_outlined),
                  label: Text(
                    controller.isUploading.value
                        ? 'profile_uploading'.tr
                        : 'profile_change_photo'.tr,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, 'profile_account_details'.tr),
            const SizedBox(height: 8),
            _detailsPanel(context, [
              _detailRow(
                context,
                icon: Icons.alternate_email,
                label: 'profile_email_address'.tr,
                value: controller.userEmail.value.isEmpty
                    ? 'common_not_available'.tr
                    : controller.userEmail.value,
              ),
              const Divider(height: 1),
              _detailRow(
                context,
                icon: Icons.badge_outlined,
                label: 'profile_account_type'.tr,
                value: roleLabel,
              ),
              const Divider(height: 1),
              _detailRow(
                context,
                icon: Icons.fingerprint,
                label: 'profile_user_id'.tr,
                value: controller.userId.value.isEmpty
                    ? 'common_not_available'.tr
                    : controller.userId.value,
              ),
            ]),
            const SizedBox(height: 24),
            _sectionTitle(
              context,
              'profile_assigned_meters'.tr,
              trailing: Text(
                '${controller.meterIds.length}',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (controller.meterIds.isEmpty)
              _detailsPanel(context, [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.electrical_services, color: colors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'profile_no_meters'.tr,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ])
            else
              _detailsPanel(context, [
                for (
                  var index = 0;
                  index < controller.meterIds.length;
                  index++
                ) ...[
                  if (index > 0) const Divider(height: 1),
                  _detailRow(
                    context,
                    icon: Icons.electrical_services,
                    label:
                        controller.meterNames[controller.meterIds[index]] ??
                        'profile_meter_n'.trParams({'n': '${index + 1}'}),
                    value: 'ID: ${controller.meterIds[index]}',
                  ),
                ],
              ]),
          ],
        );
      }),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title, {
    Widget? trailing,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      ?trailing,
    ],
  );

  Widget _detailsPanel(BuildContext context, List<Widget> children) =>
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(children: children),
      );

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}

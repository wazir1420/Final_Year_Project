import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAccountRow(),
          const SizedBox(height: 20),
          _sectionLabel('Alerts'),
          _buildAlertsCard(),
          const SizedBox(height: 12),
          _sectionLabel('Meter and connection'),
          _buildMeterCard(),
          const SizedBox(height: 12),
          _sectionLabel('App preferences'),
          _buildPreferencesCard(),
          const SizedBox(height: 24),
          _buildSignOutButton(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Theme.of(Get.context!).cardColor,
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(children: children),
  );

  Widget _divider() => const Divider(height: 1);

  // ignore: unused_element
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  ImageProvider<Object>? _profileImage(String value) {
    if (value.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(value));
    } on FormatException {
      return null;
    }
  }

  Widget _buildAccountRow() {
    return InkWell(
      onTap: controller.goToProfile,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          final image = _profileImage(controller.profilePhoto.value);
          return Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE6F1FB),
                backgroundImage: image,
                child: image == null
                    ? Text(
                        _initials(controller.userName.value),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.userName.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.userEmail.value,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAlertsCard() {
    return _card(
      children: [
        Obx(
          () => ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bill threshold alert'),
            trailing: Switch(
              value: controller.billThresholdAlert.value,
              onChanged: controller.toggleBillThresholdAlert,
              activeThumbColor: Theme.of(Get.context!).colorScheme.primary,
            ),
          ),
        ),
        _divider(),
        Obx(
          () => ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('High power alert'),
            trailing: Switch(
              value: controller.highPowerAlert.value,
              onChanged: controller.toggleHighPowerAlert,
              activeThumbColor: Theme.of(Get.context!).colorScheme.primary,
            ),
          ),
        ),
        _divider(),
        Obx(
          () => ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Daily summary'),
            trailing: Switch(
              value: controller.dailySummary.value,
              onChanged: controller.toggleDailySummary,
              activeThumbColor: Theme.of(Get.context!).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeterCard() {
    return _card(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.memory),
          title: const Text('Meter model'),
          trailing: Obx(
            () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    controller.meterModel.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
          onTap: controller.goToMeterConfig,
        ),
        _divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cloud_outlined),
          title: const Text('Firebase connection'),
          trailing: Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: controller.isFirebaseConnected.value
                    ? const Color(0xFFEAF3DE)
                    : const Color(0xFFFCEBEB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                controller.isFirebaseConnected.value ? 'Live' : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  color: controller.isFirebaseConnected.value
                      ? const Color(0xFF3B6D11)
                      : const Color(0xFF991F1F),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesCard() {
    return _card(
      children: [
        Obx(
          () => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              controller.isDarkMode.value ? Icons.dark_mode : Icons.light_mode,
              color: controller.isDarkMode.value
                  ? Theme.of(Get.context!).colorScheme.primary
                  : Colors.grey,
            ),
            title: const Text('Dark mode'),
            trailing: Switch(
              value: controller.isDarkMode.value,
              onChanged: controller.toggleDarkMode,
              activeThumbColor: Theme.of(Get.context!).colorScheme.primary,
            ),
          ),
        ),
        _divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Language'),
          trailing: Obx(
            () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.language.value,
                  style: const TextStyle(color: Colors.grey),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
          onTap: controller.selectLanguage,
        ),
        _divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Currency'),
          trailing: Obx(
            () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.currency.value,
                  style: const TextStyle(color: Colors.grey),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
          onTap: controller.selectCurrency,
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return OutlinedButton(
      onPressed: controller.signOut,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Color(0xFFE24B4A)),
        foregroundColor: const Color(0xFFA32D2D),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, size: 18),
          SizedBox(width: 8),
          Text('Sign out'),
        ],
      ),
    );
  }
}

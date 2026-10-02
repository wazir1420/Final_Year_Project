import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/device_status_model.dart';

class FirebaseDeviceService {
  static const String _dbUrl =
      'https://finalyearproject-2034b-default-rtdb.asia-southeast1.firebasedatabase.app';

  static const List<DeviceStatus> devices = [
    DeviceStatus(
      id: 'bulb',
      nameKey: 'device_bulb',
      icon: Icons.lightbulb_outline_rounded,
    ),
    DeviceStatus(
      id: 'fan',
      nameKey: 'device_fan',
      icon: Icons.mode_fan_off_rounded,
    ),
    DeviceStatus(
      id: 'fridge',
      nameKey: 'device_fridge',
      icon: Icons.kitchen_rounded,
    ),
    DeviceStatus(
      id: 'spare',
      nameKey: 'device_spare',
      icon: Icons.power_rounded,
    ),
  ];

  Uri get _devicesUri => Uri.parse('$_dbUrl/devices.json');

  Future<Map<String, DeviceStatus>> fetchDevices() async {
    final response = await http
        .get(_devicesUri)
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('Firebase returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map ? decoded : const <String, dynamic>{};
    final result = <String, DeviceStatus>{};
    for (final device in devices) {
      final deviceData = data[device.id];
      final appliedState = deviceData is Map
          ? deviceData['applied'] as bool? ?? false
          : false;
      result[device.id] = device.copyWith(
        desiredState: deviceData is Map
            ? deviceData['state'] as bool? ?? appliedState
            : false,
        appliedState: appliedState,
      );
    }
    return result;
  }

  Future<void> setDesiredState(String deviceId, bool state) async {
    final response = await http
        .patch(
          Uri.parse('$_dbUrl/devices/$deviceId.json'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'state': state}),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('Firebase returned ${response.statusCode}');
    }
  }
}

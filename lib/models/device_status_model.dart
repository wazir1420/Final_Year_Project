import 'package:flutter/material.dart';

class DeviceStatus {
  final String id;
  final String nameKey;
  final IconData icon;
  final bool desiredState;
  final bool appliedState;

  const DeviceStatus({
    required this.id,
    required this.nameKey,
    required this.icon,
    this.desiredState = false,
    this.appliedState = false,
  });

  DeviceStatus copyWith({bool? desiredState, bool? appliedState}) =>
      DeviceStatus(
        id: id,
        nameKey: nameKey,
        icon: icon,
        desiredState: desiredState ?? this.desiredState,
        appliedState: appliedState ?? this.appliedState,
      );
}

class MeterData {
  final double activePower; // kW  (total three-phase)
  final double voltageL1; // V
  final double voltageL2;
  final double voltageL3;
  final double currentL1; // A
  final double currentL2;
  final double currentL3;
  final double powerFactor;
  final double frequency; // Hz
  final double totalEnergy; // kWh (cumulative)
  final DateTime timestamp;

  const MeterData({
    required this.activePower,
    required this.voltageL1,
    required this.voltageL2,
    required this.voltageL3,
    required this.currentL1,
    required this.currentL2,
    required this.currentL3,
    required this.powerFactor,
    required this.frequency,
    required this.totalEnergy,
    required this.timestamp,
  });

  factory MeterData.empty() => MeterData(
    activePower: 0,
    voltageL1: 0,
    voltageL2: 0,
    voltageL3: 0,
    currentL1: 0,
    currentL2: 0,
    currentL3: 0,
    powerFactor: 0,
    frequency: 0,
    totalEnergy: 0,
    timestamp: DateTime.now(),
  );

  // ── Derived ────────────────────────────────────────────────────────────────
  double get avgVoltage => (voltageL1 + voltageL2 + voltageL3) / 3;
  double get totalCurrent => currentL1 + currentL2 + currentL3;

  // ── Firebase factory (uncomment when ready) ────────────────────────────────
  // factory MeterData.fromFirestore(Map<String, dynamic> m) => MeterData(
  //   activePower : (m['active_power']      as num).toDouble(),
  //   voltageL1   : (m['voltage_l1']        as num).toDouble(),
  //   voltageL2   : (m['voltage_l2']        as num).toDouble(),
  //   voltageL3   : (m['voltage_l3']        as num).toDouble(),
  //   currentL1   : (m['current_l1']        as num).toDouble(),
  //   currentL2   : (m['current_l2']        as num).toDouble(),
  //   currentL3   : (m['current_l3']        as num).toDouble(),
  //   powerFactor : (m['power_factor']      as num).toDouble(),
  //   frequency   : (m['frequency']         as num).toDouble(),
  //   totalEnergy : (m['total_energy_kwh']  as num).toDouble(),
  //   timestamp   : (m['timestamp'] as Timestamp).toDate(),
  // );
}

class DailyUsage {
  final int day;
  final double kwh;
  const DailyUsage({required this.day, required this.kwh});
}

class MonthlyData {
  final double totalKwh;
  final List<DailyUsage> daily;
  const MonthlyData({required this.totalKwh, required this.daily});
}

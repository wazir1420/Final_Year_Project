class MeterData {
  final String meterId; // NEW
  final String meterName; // NEW
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

  /// How many phases are actually wired to the meter right now (1, 2, or 3).
  final int connectedPhases;

  const MeterData({
    this.meterId = '',
    this.meterName = '',
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
    this.connectedPhases = 3,
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
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    connectedPhases: 3,
  );

  // ── Derived ────────────────────────────────────────────────────────────────
  double get avgVoltage {
    final vals = [
      voltageL1,
      voltageL2,
      voltageL3,
    ].take(connectedPhases).toList();
    if (vals.isEmpty) return 0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double get totalCurrent {
    final vals = [
      currentL1,
      currentL2,
      currentL3,
    ].take(connectedPhases).toList();
    if (vals.isEmpty) return 0;
    return vals.reduce((a, b) => a + b);
  }

  bool isPhaseConnected(int phase) => phase <= connectedPhases;

  /// Short label for display, e.g. "Main line connected" or "Three-phase".
  String get phaseStatusLabel =>
      connectedPhases >= 3 ? 'Three-phase' : 'Main line connected';

  // ── Firebase Realtime Database factory ──────────────────────────────────────
  factory MeterData.fromFirebase(Map<dynamic, dynamic> m) {
    final singleVoltage = (m['voltage'] as num?)?.toDouble() ?? 0;
    final singleCurrent = (m['current'] as num?)?.toDouble() ?? 0;
    final powerWatts = (m['power'] as num?)?.toDouble() ?? 0;

    DateTime ts;
    final rawTs = m['timestamp'];
    if (rawTs is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else if (rawTs is num) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawTs.toInt());
    } else {
      ts = DateTime.now();
    }

    return MeterData(
      activePower: powerWatts / 1000.0,
      voltageL1: singleVoltage,
      voltageL2: 0,
      voltageL3: 0,
      currentL1: singleCurrent,
      currentL2: 0,
      currentL3: 0,
      powerFactor: (m['powerFactor'] as num?)?.toDouble() ?? 0,
      frequency: (m['frequency'] as num?)?.toDouble() ?? 0,
      totalEnergy: (m['energy'] as num?)?.toDouble() ?? 0,
      timestamp: ts,
      connectedPhases: 1,
    );
  }
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

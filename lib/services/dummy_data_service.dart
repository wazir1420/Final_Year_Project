import 'dart:async';
import 'dart:math';
import '../models/meter_data_model.dart';

/// Simulates live meter readings with small random fluctuations.
/// ─────────────────────────────────────────────────────────────
/// When you have your DTSU666 + Firebase ready, delete this file
/// and update DashboardController to use FirebaseService instead.
/// Nothing in the View or widgets needs to change.
class DummyDataService {
  final _rng = Random();

  // Base values that mimic a real three-phase load
  static const _baseV = 238.0;
  static const _baseI = [6.4, 7.1, 6.3]; // L1, L2, L3 amps
  static const _basePf = 0.94;
  static const _baseHz = 49.98;

  /// Stream that emits new MeterData every 2 seconds.
  Stream<MeterData> get meterStream async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      yield generateReading();
    }
  }

  MeterData generateReading() {
    double jitter(double base, double range) =>
        base + (_rng.nextDouble() * range * 2 - range);

    final v1 = jitter(_baseV, 1.5);
    final v2 = jitter(_baseV, 1.5);
    final v3 = jitter(_baseV, 1.5);
    final i1 = jitter(_baseI[0], 0.3);
    final i2 = jitter(_baseI[1], 0.3);
    final i3 = jitter(_baseI[2], 0.3);
    final pf = jitter(_basePf, 0.01).clamp(0.85, 1.0);
    final hz = jitter(_baseHz, 0.02);

    // P = V * I * PF  (per phase, then sum)
    final activePower = ((v1 * i1 + v2 * i2 + v3 * i3) * pf) / 1000; // → kW

    return MeterData(
      activePower: activePower,
      voltageL1: v1,
      voltageL2: v2,
      voltageL3: v3,
      currentL1: i1,
      currentL2: i2,
      currentL3: i3,
      powerFactor: pf,
      frequency: hz,
      totalEnergy: 187.3, // cumulative kWh — static for dummy
      timestamp: DateTime.now(),
    );
  }

  /// Returns realistic dummy monthly data for the current month.
  MonthlyData getMonthlyData() {
    final today = DateTime.now().day;
    final daily = List.generate(today, (i) {
      // Simulate a slightly rising consumption trend
      final base = 6.0 + (i * 0.05);
      final kwh = base + _rng.nextDouble() * 2.0;
      return DailyUsage(day: i + 1, kwh: double.parse(kwh.toStringAsFixed(2)));
    });

    final totalKwh = daily.fold(0.0, (sum, d) => sum + d.kwh);
    return MonthlyData(totalKwh: totalKwh, daily: daily);
  }
}

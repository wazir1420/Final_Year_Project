import 'dart:math';
import '../models/analytics_model.dart';

/// Generates realistic dummy analytics data.
/// Swap each method for a Firebase/API call when your meter is ready.
class AnalyticsDummyService {
  final _rng = Random();

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _rate = 24.0; // Rs per kWh
  static const _fixed = 150.0;
  static const _tax = 0.17;

  // ── Summary ──────────────────────────────────────────────────────────────
  AnalyticsSummary getSummary(String period) {
    final stats = getDailyStats(period);
    final totalKwh = stats.fold(0.0, (s, d) => s + d.kwh);
    final totalCost = stats.fold(0.0, (s, d) => s + d.costRs);
    final days = stats.length;

    return AnalyticsSummary(
      totalKwh: totalKwh,
      avgDailyCostRs: days > 0 ? totalCost / days : 0,
      peakKw: 6.2,
      peakLabel: 'Tue 7–8 PM',
      avgPowerFactor: 0.93,
      kwhDeltaPct: 8.2,
      costDeltaPct: -3.1,
    );
  }

  // ── Daily comparison bars ─────────────────────────────────────────────────
  List<DailyStats> getDailyStats(String period) {
    // Day  → 1 entry,  Week → 7,  Month → last 4 weeks as Mon-Sun labels
    final count = period == 'Day' ? 7 : (period == 'Week' ? 7 : 4);
    final labels = period == 'Month' ? ['Wk1', 'Wk2', 'Wk3', 'Wk4'] : _days;

    return List.generate(count, (i) {
      final kwh = 4.0 + _rng.nextDouble() * 4.0;
      final prevKwh = 3.5 + _rng.nextDouble() * 4.0;
      final cost = (kwh * _rate + _fixed / count) * (1 + _tax);
      return DailyStats(
        day: labels[i],
        kwh: double.parse(kwh.toStringAsFixed(2)),
        prevKwh: double.parse(prevKwh.toStringAsFixed(2)),
        costRs: double.parse(cost.toStringAsFixed(0)),
      );
    });
  }

  // ── Hourly power trend ────────────────────────────────────────────────────
  List<HourlyPoint> getHourlyTrend(String period) {
    // 24 points; simulate typical daily load shape
    final baseLoad = [
      0.8, 0.6, 0.5, 0.5, 0.6, 1.2, // 0–5 am
      2.0, 2.8, 3.5, 4.0, 4.5, 5.8, // 6–11 am
      6.2, 5.5, 4.8, 4.2, 4.5, 5.0, // 12–5 pm
      5.8, 6.0, 5.5, 4.2, 3.0, 1.5, // 6–11 pm
    ];
    return List.generate(24, (h) {
      final kw = baseLoad[h] + (_rng.nextDouble() * 0.4 - 0.2);
      return HourlyPoint(
        hour: h,
        kw: double.parse(kw.clamp(0.1, 8.0).toStringAsFixed(2)),
      );
    });
  }

  // ── Peak-hours heatmap ────────────────────────────────────────────────────
  List<HeatmapCell> getHeatmap(String period) {
    final hours = [6, 9, 12, 15, 18, 21];
    final cells = <HeatmapCell>[];

    // Rough intensity profile per hour slot (0–1)
    final hourBase = {6: 0.35, 9: 0.55, 12: 0.80, 15: 0.65, 18: 0.90, 21: 0.55};

    for (final hour in hours) {
      for (final day in _days) {
        final weekend = day == 'Sat' || day == 'Sun';
        final base = hourBase[hour]! * (weekend ? 0.6 : 1.0);
        final intensity = (base + _rng.nextDouble() * 0.15).clamp(0.0, 1.0);
        cells.add(
          HeatmapCell(
            hour: hour,
            day: day,
            intensity: double.parse(intensity.toStringAsFixed(2)),
          ),
        );
      }
    }
    return cells;
  }
}

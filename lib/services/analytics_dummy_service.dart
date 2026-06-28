import 'dart:math';
import '../models/analytics_model.dart';

/// Generates realistic dummy analytics data.
/// Swap each method for a Firebase/API call when your meter is ready.
class AnalyticsDummyService {
  final _rng = Random();

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _dayLabels = ['12a', '4a', '8a', '12p', '4p', '8p', '11p'];
  static const _rate = 24.0; // Rs per kWh
  static const _fixed = 150.0;
  static const _tax = 0.17;

  // ── Summary ──────────────────────────────────────────────────────────────
  AnalyticsSummary getSummary(String period) {
    final stats = getDailyStats(period);
    final totalKwh = stats.fold(0.0, (s, d) => s + d.kwh);
    final totalCost = stats.fold(0.0, (s, d) => s + d.costRs);
    final days = stats.length;

    final peakKw = period == 'Day'
        ? 6.4
        : period == 'Week'
        ? 5.8
        : 6.7;
    final peakLabel = period == 'Day'
        ? 'Today 7–8 PM'
        : period == 'Week'
        ? 'Tue 7–8 PM'
        : 'Wk3 average';
    final avgPowerFactor = period == 'Month' ? 0.91 : 0.93;
    final kwhDeltaPct = period == 'Day' ? 4.8 : (period == 'Week' ? 8.2 : 1.6);
    final costDeltaPct = period == 'Day'
        ? -1.5
        : (period == 'Week' ? -3.1 : 2.4);

    return AnalyticsSummary(
      totalKwh: totalKwh,
      avgDailyCostRs: days > 0 ? totalCost / days : 0,
      peakKw: peakKw,
      peakLabel: peakLabel,
      avgPowerFactor: avgPowerFactor,
      kwhDeltaPct: kwhDeltaPct,
      costDeltaPct: costDeltaPct,
    );
  }

  // ── Daily comparison bars ─────────────────────────────────────────────────
  List<DailyStats> getDailyStats(String period) {
    final labels = period == 'Day'
        ? _dayLabels
        : period == 'Week'
        ? _days
        : ['Wk1', 'Wk2', 'Wk3', 'Wk4'];

    return List.generate(labels.length, (i) {
      final base = period == 'Day'
          ? 3.0 + i * 0.4
          : period == 'Week'
          ? 4.0 + (i.isEven ? 0.8 : 0.2)
          : 5.0 + i * 0.4;
      final kwh = base + _rng.nextDouble() * (period == 'Month' ? 1.5 : 1.0);
      final prevKwh = (kwh * (0.85 + _rng.nextDouble() * 0.25)).clamp(1.0, 8.0);
      final cost = (kwh * _rate + _fixed / labels.length) * (1 + _tax);
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
    final baseLoad = period == 'Day'
        ? [
            0.8,
            0.6,
            0.5,
            0.5,
            0.6,
            1.2,
            2.0,
            2.8,
            3.5,
            4.0,
            4.5,
            5.8,
            6.2,
            5.5,
            4.8,
            4.2,
            4.5,
            5.0,
            5.8,
            6.0,
            5.5,
            4.2,
            3.0,
            1.5,
          ]
        : period == 'Week'
        ? [
            1.0,
            0.9,
            0.8,
            0.8,
            0.9,
            1.4,
            2.2,
            3.0,
            3.8,
            4.2,
            4.8,
            5.5,
            5.9,
            5.2,
            4.6,
            4.0,
            4.3,
            4.7,
            5.4,
            5.7,
            5.2,
            3.9,
            3.1,
            1.8,
          ]
        : [
            1.1,
            1.0,
            0.9,
            0.9,
            1.0,
            1.5,
            2.5,
            3.3,
            4.0,
            4.5,
            5.0,
            5.7,
            6.5,
            6.0,
            5.3,
            4.7,
            4.8,
            5.1,
            5.6,
            5.9,
            5.4,
            4.5,
            3.3,
            2.0,
          ];

    return List.generate(24, (h) {
      final noise = _rng.nextDouble() * 0.4 - 0.2;
      final kw = (baseLoad[h] + noise).clamp(0.1, 8.0);
      return HourlyPoint(hour: h, kw: double.parse(kw.toStringAsFixed(2)));
    });
  }

  // ── Peak-hours heatmap ────────────────────────────────────────────────────
  List<HeatmapCell> getHeatmap(String period) {
    final hours = [6, 9, 12, 15, 18, 21];
    final cells = <HeatmapCell>[];
    final hourBase = period == 'Day'
        ? {6: 0.25, 9: 0.45, 12: 0.65, 15: 0.55, 18: 0.75, 21: 0.50}
        : period == 'Week'
        ? {6: 0.35, 9: 0.55, 12: 0.80, 15: 0.65, 18: 0.90, 21: 0.55}
        : {6: 0.30, 9: 0.50, 12: 0.78, 15: 0.68, 18: 0.85, 21: 0.58};

    for (final hour in hours) {
      for (final day in _days) {
        final weekendFactor =
            period == 'Month' && (day == 'Sat' || day == 'Sun') ? 0.7 : 1.0;
        final intensity =
            (hourBase[hour]! * weekendFactor + _rng.nextDouble() * 0.15).clamp(
              0.0,
              1.0,
            );
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

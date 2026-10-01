class DailyStats {
  final String day; // "Mon", "Tue" etc.
  final double kwh; // this period
  final double prevKwh; // last period (for comparison bar)
  final double costRs; // Rs. for this day

  const DailyStats({
    required this.day,
    required this.kwh,
    required this.prevKwh,
    required this.costRs,
  });
}

class HourlyPoint {
  final int hour; // 0..23
  final double kw; // active power at that hour

  const HourlyPoint({required this.hour, required this.kw});
}

/// Trend chart ka ek point — period ke hisaab se label aur value:
/// Day → har ghanta ("0h", "6h"...), Week → har din (Mon..Sun),
/// Month → har hafta (W1..W5).
/// hasData = false ka matlab slot ka waqt abhi poora nahi hua
/// (curve sirf guzar chuke slots tak banta hai).
class TrendPoint {
  final String label;
  final double value;
  final bool hasData;

  const TrendPoint({
    required this.label,
    required this.value,
    this.hasData = true,
  });
}

class HeatmapCell {
  final int hour; // start hour of the three-hour row (0,3,...,21)
  final String day; // col label (translated)
  final int dayKey; // 1=Mon..7=Sun (language-independent order)
  final double intensity; // 0.0 – 1.0  (raw kWh normalised)

  const HeatmapCell({
    required this.hour,
    required this.day,
    this.dayKey = 0,
    required this.intensity,
  });
}

class AnalyticsSummary {
  final double totalKwh;
  final double avgDailyCostRs;
  final double peakKw;
  final String peakLabel;
  final double avgPowerFactor;
  final double kwhDeltaPct; // signed %, vs previous period
  final double costDeltaPct;
  final double maxDailyKwh;
  final String maxDailyLabel;
  final int daysWithReadings;
  final bool hasPreviousData;

  const AnalyticsSummary({
    required this.totalKwh,
    required this.avgDailyCostRs,
    this.peakKw = 0,
    this.peakLabel = '',
    this.avgPowerFactor = 0,
    required this.kwhDeltaPct,
    required this.costDeltaPct,
    this.maxDailyKwh = 0,
    this.maxDailyLabel = '',
    this.daysWithReadings = 0,
    this.hasPreviousData = false,
  });
}

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

class HeatmapCell {
  final int hour; // row: 6,9,12,15,18,21
  final String day; // col: "Mon".."Sun"
  final double intensity; // 0.0 – 1.0  (raw kWh normalised)

  const HeatmapCell({
    required this.hour,
    required this.day,
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

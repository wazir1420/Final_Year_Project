import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/analytics_model.dart';
import 'dashboard_widgets.dart'
    show kSurface, kBorder, kCard, kPrimary, kMuted, kBlue;
export 'dashboard_widgets.dart'
    show kSurface, kBorder, kCard, kPrimary, kMuted, kBlue;

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: kMuted,
        letterSpacing: 0.7,
      ),
    ),
  );
}

class PeriodTabBar extends StatelessWidget {
  final String selected;
  final VoidCallback onDay;
  final VoidCallback onWeek;
  final VoidCallback onMonth;

  const PeriodTabBar({
    super.key,
    required this.selected,
    required this.onDay,
    required this.onWeek,
    required this.onMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PeriodTab('day', 'analytics_period_day'.tr, selected == 'day', onDay),
          _PeriodTab(
            'week',
            'analytics_period_week'.tr,
            selected == 'week',
            onWeek,
          ),
          _PeriodTab(
            'month',
            'analytics_period_month'.tr,
            selected == 'month',
            onMonth,
          ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String keyId;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodTab(this.keyId, this.label, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? kBlue : kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? kBlue : kBorder),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : kPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final bool deltaIsGood;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaIsGood,
  });

  @override
  Widget build(BuildContext context) {
    final deltaColor = deltaIsGood
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Urdu (Nastaliq/fallback) glyphs Latin se lambe hote hain, is liye
          // fixed-height card mein text ko flexible rakha hai — warna
          // "bottom overflowed by 2px" jaisi stripes Urdu mein aa jati hain.
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: kMuted),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              delta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: deltaColor),
            ),
          ),
        ],
      ),
    );
  }
}

class ComparisonBarChart extends StatelessWidget {
  final List<DailyStats> data;
  final double maxKwh;
  final String currentLabel;

  const ComparisonBarChart({
    super.key,
    required this.data,
    required this.maxKwh,
    required this.currentLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _emptyShell('analytics_no_consumption'.tr);
    }

    return _chartShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 176,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((entry) {
                final currentHeight = maxKwh > 0
                    ? (entry.kwh > 0
                          ? (entry.kwh / maxKwh).clamp(0.05, 1.0)
                          : 0.0)
                    : 0.0;
                final previousHeight = maxKwh > 0
                    ? (entry.prevKwh > 0
                          ? (entry.prevKwh / maxKwh).clamp(0.05, 1.0)
                          : 0.0)
                    : 0.0;
                const barMaxHeight = 64.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: previousHeight * barMaxHeight,
                          width: 10,
                          decoration: BoxDecoration(
                            color: kMuted.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: currentHeight * barMaxHeight,
                          width: 10,
                          decoration: BoxDecoration(
                            color: kBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.day,
                          style: TextStyle(fontSize: 10, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendDot(kBlue, 'analytics_legend_current'.tr),
              _legendDot(
                kMuted.withValues(alpha: 0.65),
                'analytics_legend_previous'.tr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PowerTrendChart extends StatelessWidget {
  final List<TrendPoint> data;
  final double maxValue;
  final String peakLabel;

  const PowerTrendChart({
    super.key,
    required this.data,
    required this.maxValue,
    required this.peakLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _emptyShell('analytics_no_trend'.tr);
    }

    // X-axis labels period ke hisaab se: Day → 0h/12h/24h,
    // Week → Mon/Wed/Fri/Sun, Month → W1/W2/W3...
    final isDay = data.length == 24;
    final xLabels = isDay
        ? ['0h', '12h', '24h']
        : data.length <= 7
        ? data.map((p) => p.label).toList()
        : data.map((p) => p.label).toList();

    return _chartShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'analytics_power_trend'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
              Text(peakLabel, style: TextStyle(fontSize: 11, color: kMuted)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _TrendLinePainter(data: data, maxKw: maxValue),
              child: Container(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final l in xLabels)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l, style: TextStyle(fontSize: 10, color: kMuted)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class PeakHoursHeatmap extends StatelessWidget {
  final List<HeatmapCell> cells;
  final String title;

  const PeakHoursHeatmap({
    super.key,
    required this.cells,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) {
      return _emptyShell('analytics_no_heatmap'.tr);
    }

    const hours = [6, 9, 12, 15, 18, 21];
    // Columns cells se hi derive hote hain (dayKey = column index):
    // Day → 1 (Aaj), Week → 1..7 (Mon..Sun), Month → 1..5 (W1..W5).
    // Urdu/English dono mein lookup sahi rehta hai.
    final columns = <int, String>{};
    for (final cell in cells) {
      columns.putIfAbsent(cell.dayKey, () => cell.day);
    }
    final colKeys = columns.keys.toList()..sort();
    final colWidth = colKeys.length <= 3 ? 56.0 : 32.0;

    final map = <int, Map<int, HeatmapCell>>{};
    for (final cell in cells) {
      map[cell.hour] = map[cell.hour] ?? {};
      map[cell.hour]![cell.dayKey] = cell;
    }

    return _chartShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 36),
                    ...colKeys.map(
                      (key) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: SizedBox(
                          width: colWidth,
                          child: Center(
                            child: Text(
                              columns[key]!,
                              style: TextStyle(fontSize: 10, color: kMuted),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...hours.map((hour) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(
                            _slotLabel(hour),
                            style: TextStyle(fontSize: 10, color: kMuted),
                          ),
                        ),
                        ...colKeys.map((key) {
                          final intensity =
                              map[hour]?[key]?.intensity ?? 0.0;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: colWidth,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _heatColor(intensity),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CostBarChart extends StatelessWidget {
  final List<DailyStats> data;
  final double maxCost;
  final double totalCost;

  const CostBarChart({
    super.key,
    required this.data,
    required this.maxCost,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _emptyShell('analytics_no_cost'.tr);
    }

    return _chartShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'analytics_chart_cost'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
              Text(
                'analytics_chart_total'.trParams({
                  'total': totalCost.toStringAsFixed(0),
                }),
                style: TextStyle(fontSize: 11, color: kMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((entry) {
                final barHeight = maxCost > 0 && entry.costRs > 0
                    ? (entry.costRs / maxCost).clamp(0.05, 1.0)
                    : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: barHeight * 130,
                          width: 14,
                          decoration: BoxDecoration(
                            color: kBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.day,
                          style: TextStyle(fontSize: 10, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _emptyShell(String text) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: kCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: kBorder, width: 0.5),
  ),
  child: Text(text, style: TextStyle(color: kMuted, fontSize: 13)),
);

Widget _chartShell({required Widget child}) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: kCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: kBorder, width: 0.5),
  ),
  child: child,
);

Widget _legendDot(Color color, String label) => Row(
  children: [
    Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
    ),
    const SizedBox(width: 6),
    Text(label, style: TextStyle(fontSize: 10, color: kMuted)),
  ],
);

/// Slot label 12-hour format mein: 6 → "6 AM", 12 → "12 PM",
/// 15 → "3 PM", 21 → "9 PM"
String _slotLabel(int hour) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final suffix = hour < 12 ? 'AM' : 'PM';
  return '$h12 $suffix';
}

Color _heatColor(double intensity) {
  return Color.lerp(const Color(0xFFF4F6FB), kBlue, intensity) ??
      const Color(0xFFF4F6FB);
}

class _TrendLinePainter extends CustomPainter {
  final List<TrendPoint> data;
  final double maxKw;

  _TrendLinePainter({required this.data, required this.maxKw});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kBlue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = kBlue.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final points = <Offset>[];
    final drawn = <Offset>[]; // sirf hasData points (complete slots)
    final horizontalStep = data.length > 1 ? size.width / (data.length - 1) : 0.0;
    for (var i = 0; i < data.length; i++) {
      final value = data[i].value.clamp(0.0, maxKw);
      final x = i * horizontalStep;
      final y =
          size.height -
          (size.height * (value / (maxKw > 0 ? maxKw : 1.0))).clamp(
            0.0,
            size.height,
          );
      final offset = Offset(x, y);
      points.add(offset);
      if (data[i].hasData) drawn.add(offset);
    }

    if (drawn.isEmpty) return;

    final path = Path()..moveTo(drawn.first.dx, drawn.first.dy);
    for (var i = 1; i < drawn.length; i++) {
      path.lineTo(drawn[i].dx, drawn[i].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(drawn.last.dx, size.height)
      ..lineTo(drawn.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = kBlue;
    for (final point in drawn) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

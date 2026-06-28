import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import 'dashboard_widgets.dart' show kSurface, kBorder, kPrimary, kMuted, kBlue;
export 'dashboard_widgets.dart' show kSurface, kBorder, kPrimary, kMuted, kBlue;

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
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
          _PeriodTab('Day', selected == 'Day', onDay),
          _PeriodTab('Week', selected == 'Week', onWeek),
          _PeriodTab('Month', selected == 'Month', onMonth),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodTab(this.label, this.isSelected, this.onTap);

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(delta, style: TextStyle(fontSize: 12, color: deltaColor)),
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
      return _emptyShell('No consumption data available');
    }

    return _chartShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentLabel,
            style: const TextStyle(
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
                    ? (entry.kwh / maxKwh).clamp(0.05, 1.0)
                    : 0.05;
                final previousHeight = maxKwh > 0
                    ? (entry.prevKwh / maxKwh).clamp(0.05, 1.0)
                    : 0.05;
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
                          style: const TextStyle(fontSize: 10, color: kMuted),
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
              _legendDot(kBlue, 'This period'),
              _legendDot(kMuted.withValues(alpha: 0.65), 'Previous period'),
            ],
          ),
        ],
      ),
    );
  }
}

class PowerTrendChart extends StatelessWidget {
  final List<HourlyPoint> data;
  final double maxKw;
  final String peakLabel;

  const PowerTrendChart({
    super.key,
    required this.data,
    required this.maxKw,
    required this.peakLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _emptyShell('No trend data available');
    }

    return _chartShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Power trend',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
              Text(
                peakLabel,
                style: const TextStyle(fontSize: 11, color: kMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _TrendLinePainter(data: data, maxKw: maxKw),
              child: Container(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0h', style: TextStyle(fontSize: 10, color: kMuted)),
              Text('12h', style: TextStyle(fontSize: 10, color: kMuted)),
              Text('24h', style: TextStyle(fontSize: 10, color: kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class PeakHoursHeatmap extends StatelessWidget {
  final List<HeatmapCell> cells;

  const PeakHoursHeatmap({super.key, required this.cells});

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) {
      return _emptyShell('No heatmap data available');
    }

    const hours = [6, 9, 12, 15, 18, 21];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final map = <int, Map<String, HeatmapCell>>{};
    for (final cell in cells) {
      map[cell.hour] = map[cell.hour] ?? {};
      map[cell.hour]![cell.day] = cell;
    }

    return _chartShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Peak hours',
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
                    ...days.map(
                      (day) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: SizedBox(
                          width: 32,
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontSize: 10,
                                color: kMuted,
                              ),
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
                          width: 36,
                          child: Text(
                            '$hour:00',
                            style: const TextStyle(fontSize: 10, color: kMuted),
                          ),
                        ),
                        ...days.map((day) {
                          final intensity = map[hour]?[day]?.intensity ?? 0.0;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 32,
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
      return _emptyShell('No cost data available');
    }

    return _chartShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cost',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
              Text(
                'Total: Rs. ${totalCost.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 11, color: kMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((entry) {
                final barHeight = maxCost > 0
                    ? (entry.costRs / maxCost).clamp(0.05, 1.0)
                    : 0.05;
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
                          style: const TextStyle(fontSize: 10, color: kMuted),
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
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: kBorder, width: 0.5),
  ),
  child: Text(text, style: const TextStyle(color: kMuted, fontSize: 13)),
);

Widget _chartShell({required Widget child}) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
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
    Text(label, style: const TextStyle(fontSize: 10, color: kMuted)),
  ],
);

Color _heatColor(double intensity) {
  return Color.lerp(const Color(0xFFF4F6FB), kBlue, intensity) ??
      const Color(0xFFF4F6FB);
}

class _TrendLinePainter extends CustomPainter {
  final List<HourlyPoint> data;
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
    final horizontalStep = size.width / (data.length - 1);
    for (var i = 0; i < data.length; i++) {
      final value = data[i].kw.clamp(0.0, maxKw);
      final x = i * horizontalStep;
      final y =
          size.height -
          (size.height * (value / (maxKw > 0 ? maxKw : 1.0))).clamp(
            0.0,
            size.height,
          );
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = kBlue;
    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

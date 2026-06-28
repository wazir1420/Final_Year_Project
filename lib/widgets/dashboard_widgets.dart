import 'package:flutter/material.dart';
import '../models/meter_data_model.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const kNavy = Color(0xFF1E3A5F);
const kBlue = Color(0xFF2563EB);
const kBlueTint = Color(0xFFEFF6FF);
const kBlueSoft = Color(0xFFBFDBFE);
const kAmberTint = Color(0xFFFEF3C7);
const kAmber = Color(0xFFD97706);
const kGreenTint = Color(0xFFECFDF5);
const kGreen = Color(0xFF065F46);
const kGreenDot = Color(0xFF10B981);
const kIndigoTint = Color(0xFFEEF2FF);
const kIndigo = Color(0xFF3730A3);
const kIndigoMid = Color(0xFF6366F1);
const kSurface = Color(0xFFF7F8FA);
const kCard = Colors.white;
const kBorder = Color(0xFFE8EAF0);
const kPrimary = Color(0xFF111111);
const kSecondary = Color(0xFF666666);
const kMuted = Color(0xFF999999);

// ── Section label ─────────────────────────────────────────────────────────────
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

// ── Animated live badge ───────────────────────────────────────────────────────
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key});
  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _fade = Tween(begin: 1.0, end: 0.25).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: kGreenTint,
      border: Border.all(color: const Color(0xFF6EE7B7), width: 0.5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _fade,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: kGreenDot,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'Live · updating every 2s',
          style: TextStyle(
            fontSize: 11,
            color: kGreen,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// ── Power hero card ───────────────────────────────────────────────────────────
class PowerHeroCard extends StatelessWidget {
  final double activePower;
  final double avgVoltage;
  final double totalCurrent;
  final double powerFactor;
  final double frequency;

  const PowerHeroCard({
    super.key,
    required this.activePower,
    required this.avgVoltage,
    required this.totalCurrent,
    required this.powerFactor,
    required this.frequency,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kNavy,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Power',
          style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF)),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: activePower.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const TextSpan(
                text: ' kW',
                style: TextStyle(fontSize: 16, color: Color(0xB3FFFFFF)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'CHINT DTSU666 · Three-phase',
          style: TextStyle(fontSize: 11, color: Color(0x7FFFFFFF)),
        ),
        const SizedBox(height: 14),
        const Divider(color: Color(0x1FFFFFFF), height: 1),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _MiniStat('${avgVoltage.toStringAsFixed(1)} V', 'Avg Voltage'),
            _MiniStat('${totalCurrent.toStringAsFixed(1)} A', 'Total Current'),
            _MiniStat(powerFactor.toStringAsFixed(2), 'Power Factor'),
            _MiniStat('${frequency.toStringAsFixed(2)} Hz', 'Frequency'),
          ],
        ),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  const _MiniStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(fontSize: 9, color: Color(0x80FFFFFF)),
      ),
    ],
  );
}

// ── Phase parameter card ──────────────────────────────────────────────────────
class PhaseParamCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label, value, unit;
  final double l1, l2, l3;
  final String Function(double) fmt;

  const PhaseParamCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.l1,
    required this.l2,
    required this.l3,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder, width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 11, color: kMuted)),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(fontSize: 11, color: kMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _PhaseChip('L1', fmt(l1)),
            const SizedBox(width: 4),
            _PhaseChip('L2', fmt(l2)),
            const SizedBox(width: 4),
            _PhaseChip('L3', fmt(l3)),
          ],
        ),
      ],
    ),
  );
}

class _PhaseChip extends StatelessWidget {
  final String phase, value;
  const _PhaseChip(this.phase, this.value);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(phase, style: const TextStyle(fontSize: 9, color: kMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Daily bar chart (no extra package needed) ─────────────────────────────────
class DailyBarChart extends StatelessWidget {
  final List<DailyUsage> data;
  const DailyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _shell(
        child: const Center(
          child: Text(
            'No data yet',
            style: TextStyle(color: kMuted, fontSize: 13),
          ),
        ),
      );
    }

    final today = DateTime.now().day;
    final maxKwh = data.map((d) => d.kwh).reduce((a, b) => a > b ? a : b);
    // Show last 7 entries to stay readable on mobile
    final shown = data.length > 7 ? data.sublist(data.length - 7) : data;

    return _shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily usage — ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: shown.map((d) {
                final ratio = maxKwh > 0
                    ? (d.kwh / maxKwh).clamp(0.05, 1.0)
                    : 0.05;
                final isToday = d.day == today;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: ratio,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? kBlue
                                      : Color.lerp(
                                          kBlueSoft,
                                          const Color(0xFF93C5FD),
                                          ratio,
                                        )!,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isToday ? 'now' : '${d.day}',
                          style: TextStyle(
                            fontSize: 9,
                            color: isToday ? kBlue : kMuted,
                            fontWeight: isToday
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
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

  Widget _shell({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder, width: 0.5),
    ),
    child: child,
  );

  String _monthName(int m) => const [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][m];
}

// ── Bill estimate card ────────────────────────────────────────────────────────
class BillEstimateCard extends StatelessWidget {
  final String units, rate, fixed, taxes, total;
  const BillEstimateCard({
    super.key,
    required this.units,
    required this.rate,
    required this.fixed,
    required this.taxes,
    required this.total,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder, width: 0.5),
    ),
    child: Column(
      children: [
        _Row('Units used', units),
        _Row('Rate per kWh', rate),
        _Row('Fixed charges', fixed),
        _Row('Taxes (17%)', taxes),
        _Row('Estimated total', total, isTotal: true),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool isTotal;
  const _Row(this.label, this.value, {this.isTotal = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isTotal ? kPrimary : kSecondary,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isTotal ? kBlue : kPrimary,
          ),
        ),
      ],
    ),
  );
}

// ── ML prediction badge ───────────────────────────────────────────────────────
class MlPredictionBadge extends StatelessWidget {
  final String predictedBill, changeLabel;
  final bool isIncrease;
  final VoidCallback onTap;

  const MlPredictionBadge({
    super.key,
    required this.predictedBill,
    required this.changeLabel,
    required this.isIncrease,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: kIndigoTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7D2FE), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: kIndigoMid, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ML prediction — next month',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kIndigo,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Estimated: $predictedBill  ($changeLabel)',
                  style: const TextStyle(fontSize: 11, color: kIndigoMid),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: kIndigoMid, size: 18),
        ],
      ),
    ),
  );
}

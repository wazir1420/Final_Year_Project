import 'package:finalyearproject/models/bills_model.dart';
import 'package:flutter/material.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const kNavy = Color(0xFF1E3A5F);
const kBlue = Color(0xFF2563EB);
const kBlueDark = Color(0xFF1D4ED8);
const kBlueMid = Color(0xFF3B82F6);
const kBlueSoft = Color(0xFF60A5FA);
const kBluePale = Color(0xFF93C5FD);
const kBlueTint = Color(0xFFBFDBFE);
const kBlueLite = Color(0xFFDBEAFE);
const kBlueGhost = Color(0xFFEFF6FF);
const kGreen = Color(0xFF10B981);
const kAmber = Color(0xFFD97706);
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
    padding: const EdgeInsets.only(top: 16, bottom: 8),
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

// ── Hero bill card ────────────────────────────────────────────────────────────
class BillHeroCard extends StatelessWidget {
  final String monthLabel;
  final double totalRs;
  final String progressLabel;
  final double cycleProgress;
  final int daysRemaining;
  final String dueDateLabel;
  final bool isPaid;

  const BillHeroCard({
    super.key,
    required this.monthLabel,
    required this.totalRs,
    required this.progressLabel,
    required this.cycleProgress,
    required this.daysRemaining,
    required this.dueDateLabel,
    required this.isPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: kNavy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$monthLabel estimate',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0x99FFFFFF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${totalRs.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progressLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0x66FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: dueDateLabel, isPaid: isPaid),
            ],
          ),
          const SizedBox(height: 14),
          // Cycle progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0 kWh',
                style: TextStyle(fontSize: 10, color: Color(0x66FFFFFF)),
              ),
              Text(
                progressLabel,
                style: const TextStyle(fontSize: 10, color: Color(0x66FFFFFF)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cycleProgress.clamp(0.0, 1.0),
              backgroundColor: const Color.fromRGBO(255, 255, 255, 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(kBlueMid),
              minHeight: 6,
            ),
          ),
          if (daysRemaining > 0) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$daysRemaining days remaining in billing period',
                style: const TextStyle(fontSize: 10, color: Color(0x55FFFFFF)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool isPaid;
  const _StatusPill({required this.label, required this.isPaid});

  @override
  Widget build(BuildContext context) {
    final bg = isPaid
        ? const Color.fromRGBO(16, 185, 129, 0.2)
        : const Color.fromRGBO(217, 119, 6, 0.15);
    final border = isPaid
        ? const Color.fromRGBO(16, 185, 129, 0.5)
        : const Color.fromRGBO(217, 119, 6, 0.4);
    final text = isPaid ? const Color(0xFF6EE7B7) : const Color(0xFFFDE68A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: text,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Invoice card ──────────────────────────────────────────────────────────────
class InvoiceCard extends StatelessWidget {
  final String monthLabel;
  final List<InvoiceLineItem> items;
  final double totalRs;

  const InvoiceCard({
    super.key,
    required this.monthLabel,
    required this.items,
    required this.totalRs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WAPDA / K-Electric · $monthLabel',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
                Text(
                  'Est. invoice',
                  style: const TextStyle(fontSize: 10, color: kMuted),
                ),
              ],
            ),
          ),
          // Line items
          ...items.map((item) => _InvoiceRow(item: item)),
          // Total row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
                Text(
                  'Rs. ${totalRs.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final InvoiceLineItem item;
  const _InvoiceRow({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.isDivider) {
      return Column(
        children: [
          const Divider(color: kBorder, height: 1, thickness: 0.5),
          _RowContent(item: item),
          const Divider(color: kBorder, height: 1, thickness: 0.5),
        ],
      );
    }
    return Column(
      children: [
        _RowContent(item: item),
        const Divider(
          color: Color(0xFFF0F1F5),
          height: 1,
          thickness: 0.5,
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }
}

class _RowContent extends StatelessWidget {
  final InvoiceLineItem item;
  const _RowContent({required this.item});

  @override
  Widget build(BuildContext context) {
    final isUnits = item.label == 'Units consumed';
    return Padding(
      padding: EdgeInsets.fromLTRB(item.isSubItem ? 28 : 16, 9, 16, 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: item.isSubItem ? 11 : 12,
                color: item.isSubItem ? kMuted : kSecondary,
              ),
            ),
          ),
          Text(
            isUnits
                ? '${item.amountRs.toStringAsFixed(1)} kWh'
                : 'Rs. ${item.amountRs.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: item.isDivider ? FontWeight.w600 : FontWeight.w500,
              color: item.isSubItem ? kMuted : kPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Daily cost bar chart ──────────────────────────────────────────────────────
class DailyCostChart extends StatelessWidget {
  final List<DailyCost> data;
  final double maxCost;
  final double avgCost;

  const DailyCostChart({
    super.key,
    required this.data,
    required this.maxCost,
    required this.avgCost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cost per day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Rs. per day this month',
            style: TextStyle(fontSize: 11, color: kMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final ratio = maxCost > 0
                    ? (d.costRs / maxCost).clamp(0.05, 1.0)
                    : 0.05;
                final isMax = d.costRs >= maxCost * 0.98;
                final color = isMax
                    ? kBlueDark
                    : ratio > 0.7
                    ? kBlue
                    : ratio > 0.5
                    ? kBlueMid
                    : ratio > 0.3
                    ? kBluePale
                    : kBlueTint;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: ratio,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.day}',
                        style: const TextStyle(fontSize: 8, color: kMuted),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kBorder, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Avg per day',
                  style: TextStyle(fontSize: 11, color: kMuted),
                ),
                Text(
                  'Rs. ${avgCost.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Month comparison chart ────────────────────────────────────────────────────
class MonthComparisonChart extends StatelessWidget {
  final List<MonthComparison> data;
  final double maxTotal;
  final double avgTotal;
  final BillMonth currentMonth;

  const MonthComparisonChart({
    super.key,
    required this.data,
    required this.maxTotal,
    required this.avgTotal,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill vs previous months',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...data.map((c) {
            final ratio = maxTotal > 0
                ? (c.totalRs / maxTotal).clamp(0.05, 1.0)
                : 0.05;
            final isCurrent = c.period == currentMonth;
            final isUp = c.deltaPct > 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      c.period.shortLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: isCurrent ? kPrimary : kSecondary,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Stack(
                        children: [
                          Container(height: 8, color: const Color(0xFFF0F1F5)),
                          FractionallySizedBox(
                            widthFactor: ratio,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: isCurrent ? kBlue : kBluePale,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 58,
                    child: Text(
                      'Rs. ${c.totalRs.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isCurrent ? kPrimary : kSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: c.deltaPct != 0
                        ? Text(
                            '${isUp ? '+' : ''}${c.deltaPct.toStringAsFixed(0)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isUp ? kAmber : kGreen,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kBorder, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '5-month average',
                  style: TextStyle(fontSize: 11, color: kMuted),
                ),
                Text(
                  'Rs. ${avgTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

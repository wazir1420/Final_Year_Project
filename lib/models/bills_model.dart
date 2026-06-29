class BillMonth {
  final int year;
  final int month;
  const BillMonth({required this.year, required this.month});

  BillMonth prev() {
    if (month == 1) return BillMonth(year: year - 1, month: 12);
    return BillMonth(year: year, month: month - 1);
  }

  BillMonth next() {
    if (month == 12) return BillMonth(year: year + 1, month: 1);
    return BillMonth(year: year, month: month + 1);
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  bool get isFuture {
    final now = DateTime.now();
    return DateTime(year, month).isAfter(DateTime(now.year, now.month));
  }

  String get label {
    const n = [
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
    ];
    return '${n[month]} $year';
  }

  String get shortLabel {
    const n = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return n[month];
  }

  @override
  bool operator ==(Object other) =>
      other is BillMonth && other.year == year && other.month == month;
  @override
  int get hashCode => year * 100 + month;
}

class InvoiceLineItem {
  final String label;
  final double amountRs;
  final bool isSubItem;
  final bool isDivider;
  const InvoiceLineItem({
    required this.label,
    required this.amountRs,
    this.isSubItem = false,
    this.isDivider = false,
  });
}

class MonthBill {
  final BillMonth period;
  final double unitsKwh;
  final double projectedUnitsKwh;
  final List<InvoiceLineItem> lineItems;
  final double subtotalRs;
  final double gstRs;
  final double incomeTaxRs;
  final double totalRs;
  final DateTime? dueDate;
  final bool isPaid;

  const MonthBill({
    required this.period,
    required this.unitsKwh,
    required this.projectedUnitsKwh,
    required this.lineItems,
    required this.subtotalRs,
    required this.gstRs,
    required this.incomeTaxRs,
    required this.totalRs,
    this.dueDate,
    this.isPaid = false,
  });

  double get cycleProgress {
    if (!period.isCurrentMonth) return 1.0;
    final now = DateTime.now();
    final dim = DateTime(period.year, period.month + 1, 0).day;
    return (now.day / dim).clamp(0.0, 1.0);
  }

  int get daysRemainingInCycle {
    if (!period.isCurrentMonth) return 0;
    final now = DateTime.now();
    final dim = DateTime(period.year, period.month + 1, 0).day;
    return dim - now.day;
  }
}

class DailyCost {
  final int day;
  final double costRs;
  final double kwh;
  const DailyCost({required this.day, required this.costRs, required this.kwh});
}

class MonthComparison {
  final BillMonth period;
  final double totalRs;
  final double deltaPct;
  const MonthComparison({
    required this.period,
    required this.totalRs,
    required this.deltaPct,
  });
}

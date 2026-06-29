import 'dart:math';
import 'package:finalyearproject/models/bills_model.dart';

class BillsDummyService {
  final _rng = Random();

  static const double _slab1Units = 100.0;
  static const double _slab1Rate = 20.0;
  static const double _slab2Rate = 26.0;
  static const double _meterRent = 150.0;
  static const double _fac = 1.00;
  static const double _tvFee = 35.0;
  static const double _gstRate = 0.17;
  static const double _itaxRate = 0.015;

  MonthBill getBill(BillMonth period) {
    final now = DateTime.now();
    final daysInMonth = DateTime(period.year, period.month + 1, 0).day;
    double units;
    if (period.isCurrentMonth) {
      units = (7.5 + _rng.nextDouble() * 2.0) * now.day;
    } else if (!period.isFuture) {
      units = 140.0 + _rng.nextDouble() * 120.0;
    } else {
      units = 0;
    }
    units = double.parse(units.toStringAsFixed(1));
    final projected = period.isCurrentMonth
        ? double.parse(((units / now.day) * daysInMonth).toStringAsFixed(1))
        : units;
    return _buildBill(period, units, projected);
  }

  MonthBill _buildBill(BillMonth period, double units, double projected) {
    final slab1 = units < _slab1Units ? units : _slab1Units;
    final slab2 = units > _slab1Units ? units - _slab1Units : 0.0;
    final energy = slab1 * _slab1Rate + slab2 * _slab2Rate;
    final facCharge = units * _fac;
    final subtotal = energy + _meterRent + facCharge + _tvFee;
    final gst = subtotal * _gstRate;
    final itax = subtotal * _itaxRate;
    final total = subtotal + gst + itax;

    final items = <InvoiceLineItem>[
      InvoiceLineItem(label: 'Units consumed', amountRs: units),
      InvoiceLineItem(label: 'Energy charges', amountRs: energy),
      InvoiceLineItem(
        label: '· Slab 1 (0–100 kWh @ Rs. 20)',
        amountRs: slab1 * _slab1Rate,
        isSubItem: true,
      ),
      if (slab2 > 0)
        InvoiceLineItem(
          label: '· Slab 2 (101–300 kWh @ Rs. 26)',
          amountRs: slab2 * _slab2Rate,
          isSubItem: true,
        ),
      InvoiceLineItem(label: 'Fixed / meter rent', amountRs: _meterRent),
      InvoiceLineItem(label: 'Fuel adjustment charge', amountRs: facCharge),
      InvoiceLineItem(label: 'TV fee', amountRs: _tvFee),
      InvoiceLineItem(label: 'Subtotal', amountRs: subtotal, isDivider: true),
      InvoiceLineItem(label: 'GST (17%)', amountRs: gst),
      InvoiceLineItem(label: 'Income tax (1.5%)', amountRs: itax),
    ];

    final dueDate = DateTime(period.year, period.month + 1, 10);
    return MonthBill(
      period: period,
      unitsKwh: units,
      projectedUnitsKwh: projected,
      lineItems: items,
      subtotalRs: subtotal,
      gstRs: gst,
      incomeTaxRs: itax,
      totalRs: total,
      dueDate: dueDate,
      isPaid: dueDate.isBefore(DateTime.now()),
    );
  }

  List<DailyCost> getDailyCosts(BillMonth period) {
    final now = DateTime.now();
    final daysInMonth = DateTime(period.year, period.month + 1, 0).day;
    final days = period.isCurrentMonth ? now.day : daysInMonth;
    return List.generate(days, (i) {
      final kwh = 5.0 + _rng.nextDouble() * 5.0;
      final cost =
          (kwh * _slab2Rate + _meterRent / daysInMonth + kwh * _fac) *
          (1 + _gstRate + _itaxRate);
      return DailyCost(
        day: i + 1,
        costRs: double.parse(cost.toStringAsFixed(0)),
        kwh: double.parse(kwh.toStringAsFixed(2)),
      );
    });
  }

  List<MonthComparison> getComparisons({int count = 5}) {
    final now = DateTime.now();
    var cursor = BillMonth(year: now.year, month: now.month);
    final result = <MonthComparison>[];
    double? prev;
    for (int i = 0; i < count; i++) {
      final bill = getBill(cursor);
      final delta = prev != null && prev > 0
          ? ((bill.totalRs - prev) / prev) * 100
          : 0.0;
      result.add(
        MonthComparison(
          period: cursor,
          totalRs: bill.totalRs,
          deltaPct: double.parse(delta.toStringAsFixed(1)),
        ),
      );
      prev = bill.totalRs;
      cursor = cursor.prev();
    }
    return result;
  }
}

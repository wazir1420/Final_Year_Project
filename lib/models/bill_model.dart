class BillEstimate {
  final double unitsUsed;
  final double ratePerKwh;
  final double fixedCharge;
  final double taxes;
  final double total;

  const BillEstimate({
    required this.unitsUsed,
    required this.ratePerKwh,
    required this.fixedCharge,
    required this.taxes,
    required this.total,
  });

  factory BillEstimate.empty() => const BillEstimate(
    unitsUsed: 0,
    ratePerKwh: 24.0,
    fixedCharge: 150.0,
    taxes: 0,
    total: 0,
  );

  String get formattedTotal => 'Rs. ${total.toStringAsFixed(0)}';
  String get formattedTaxes => 'Rs. ${taxes.toStringAsFixed(0)}';
  String get formattedFixed => 'Rs. ${fixedCharge.toStringAsFixed(0)}';
  String get formattedRate => 'Rs. ${ratePerKwh.toStringAsFixed(2)}';
  String get formattedUnits => '${unitsUsed.toStringAsFixed(1)} kWh';
}

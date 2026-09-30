import 'package:finalyearproject/models/bills_model.dart';
import 'package:finalyearproject/models/meter_data_model.dart';

enum KEPhase { single, threePhaseNonToU }

class KEMonthlyAdjustment {
  final double? fcaPerUnit;

  /// FCA un units par lagta hai jo bill mein "FCA :Apr-26  216 units" ki
  /// tarah likhe hote hain (yani 2 mahine pehle ke bill ke units). Khaali ho
  /// to app khud history se nikalti hai, warna is mahine ke units.
  final double? fcaUnits;

  final double? quarterlyAdjustmentPerUnit;

  /// Bill mein kabhi Uniform Quarterly Adjustment ki 2 lines hoti hain (purani
  /// aur nayi rate). Doosri rate aur uska hissa (0.0 - 1.0) yahan aata hai.
  final double? secondQuarterlyAdjustmentPerUnit;
  final double? secondQuarterlyShare;

  final double? fixedRatePerKw;
  final double? variableRatePerUnit;
  final double? electricityDutyPerUnit;

  /// true = ye asal bill se nahi, pichhle mahine ki rates aage barha kar
  /// andaza lagaya gaya hai.
  final bool isEstimate;

  const KEMonthlyAdjustment({
    this.fcaPerUnit,
    this.fcaUnits,
    this.quarterlyAdjustmentPerUnit,
    this.secondQuarterlyAdjustmentPerUnit,
    this.secondQuarterlyShare,
    this.fixedRatePerKw,
    this.variableRatePerUnit,
    this.electricityDutyPerUnit,
    this.isEstimate = false,
  });

  bool get isConfigured =>
      !isEstimate && fcaPerUnit != null && quarterlyAdjustmentPerUnit != null;

  factory KEMonthlyAdjustment.fromJson(Map<String, dynamic>? json) =>
      KEMonthlyAdjustment(
        fcaPerUnit: (json?['fcaPerUnit'] as num?)?.toDouble(),
        fcaUnits: (json?['fcaUnits'] as num?)?.toDouble(),
        quarterlyAdjustmentPerUnit:
            (json?['quarterlyAdjustmentPerUnit'] as num?)?.toDouble(),
        secondQuarterlyAdjustmentPerUnit:
            (json?['secondQuarterlyAdjustmentPerUnit'] as num?)?.toDouble(),
        secondQuarterlyShare: (json?['secondQuarterlyShare'] as num?)
            ?.toDouble(),
        fixedRatePerKw: (json?['fixedRatePerKw'] as num?)?.toDouble(),
        variableRatePerUnit: (json?['variableRatePerUnit'] as num?)?.toDouble(),
        electricityDutyPerUnit: (json?['electricityDutyPerUnit'] as num?)
            ?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
    if (fcaPerUnit != null) 'fcaPerUnit': fcaPerUnit,
    if (fcaUnits != null) 'fcaUnits': fcaUnits,
    if (quarterlyAdjustmentPerUnit != null)
      'quarterlyAdjustmentPerUnit': quarterlyAdjustmentPerUnit,
    if (secondQuarterlyAdjustmentPerUnit != null)
      'secondQuarterlyAdjustmentPerUnit': secondQuarterlyAdjustmentPerUnit,
    if (secondQuarterlyShare != null)
      'secondQuarterlyShare': secondQuarterlyShare,
    if (fixedRatePerKw != null) 'fixedRatePerKw': fixedRatePerKw,
    if (variableRatePerUnit != null) 'variableRatePerUnit': variableRatePerUnit,
    if (electricityDutyPerUnit != null)
      'electricityDutyPerUnit': electricityDutyPerUnit,
  };

  /// User ki di hui values ko `base` (published/andaza) ke upar rakhta hai.
  KEMonthlyAdjustment overlay(KEMonthlyAdjustment base) {
    final own = isConfigured; // user ne FCA + quarterly dono di hain
    return KEMonthlyAdjustment(
      fcaPerUnit: fcaPerUnit ?? base.fcaPerUnit,
      fcaUnits: fcaUnits ?? (own ? null : base.fcaUnits),
      quarterlyAdjustmentPerUnit:
          quarterlyAdjustmentPerUnit ?? base.quarterlyAdjustmentPerUnit,
      secondQuarterlyAdjustmentPerUnit: own
          ? secondQuarterlyAdjustmentPerUnit
          : (secondQuarterlyAdjustmentPerUnit ??
                base.secondQuarterlyAdjustmentPerUnit),
      secondQuarterlyShare: own
          ? secondQuarterlyShare
          : (secondQuarterlyShare ?? base.secondQuarterlyShare),
      fixedRatePerKw: fixedRatePerKw ?? base.fixedRatePerKw,
      variableRatePerUnit: variableRatePerUnit ?? base.variableRatePerUnit,
      electricityDutyPerUnit:
          electricityDutyPerUnit ?? base.electricityDutyPerUnit,
      isEstimate: own ? false : base.isEstimate,
    );
  }
}

class KETariffProfile {
  final KEPhase phase;
  final bool incomeTaxExempted;
  final int tvCount;
  final double? sanctionedLoadKw;
  final double? muctMonthly;
  final Map<String, KEMonthlyAdjustment> monthlyAdjustments;

  const KETariffProfile({
    this.phase = KEPhase.single,
    this.incomeTaxExempted = false,
    this.tvCount = 0,
    this.sanctionedLoadKw,
    this.muctMonthly,
    this.monthlyAdjustments = const {},
  });

  bool get hasSupportedSanctionedLoad =>
      sanctionedLoadKw != null &&
      sanctionedLoadKw! > 0 &&
      sanctionedLoadKw! < 5;

  factory KETariffProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const KETariffProfile();
    final rawAdjustments = json['monthlyAdjustments'];
    final adjustments = <String, KEMonthlyAdjustment>{};
    if (rawAdjustments is Map) {
      for (final entry in rawAdjustments.entries) {
        if (entry.value is Map) {
          adjustments[entry.key.toString()] = KEMonthlyAdjustment.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    return KETariffProfile(
      phase: json['phase'] == KEPhase.threePhaseNonToU.name
          ? KEPhase.threePhaseNonToU
          : KEPhase.single,
      incomeTaxExempted: json['incomeTaxExempted'] == true,
      tvCount: ((json['tvCount'] as num?)?.toInt() ?? 0).clamp(0, 20),
      sanctionedLoadKw: (json['sanctionedLoadKw'] as num?)?.toDouble(),
      muctMonthly: (json['muctMonthly'] as num?)?.toDouble(),
      monthlyAdjustments: adjustments,
    );
  }

  Map<String, dynamic> toJson() => {
    'phase': phase.name,
    'incomeTaxExempted': incomeTaxExempted,
    'tvCount': tvCount,
    if (sanctionedLoadKw != null) 'sanctionedLoadKw': sanctionedLoadKw,
    if (muctMonthly != null) 'muctMonthly': muctMonthly,
    'monthlyAdjustments': {
      for (final entry in monthlyAdjustments.entries)
        entry.key: entry.value.toJson(),
    },
  };

  /// Is mahine ki adjustments: pehle user ki save ki hui, phir KE ke asal
  /// bills se pata rates (KETariffCalculator.publishedAdjustments), aur agar
  /// mahina un se aage ka hai to aakhri rates aage barha kar andaza
  /// (isEstimate = true).
  KEMonthlyAdjustment adjustmentsFor(DateTime month) {
    final key = monthKey(month);
    final base =
        KETariffCalculator.publishedAdjustments[key] ??
        KETariffCalculator.estimatedAdjustmentFor(month);
    final own = monthlyAdjustments[key];
    return own == null ? base : own.overlay(base);
  }

  KETariffProfile copyWith({
    KEPhase? phase,
    bool? incomeTaxExempted,
    int? tvCount,
    double? sanctionedLoadKw,
    double? muctMonthly,
    Map<String, KEMonthlyAdjustment>? monthlyAdjustments,
  }) => KETariffProfile(
    phase: phase ?? this.phase,
    incomeTaxExempted: incomeTaxExempted ?? this.incomeTaxExempted,
    tvCount: tvCount ?? this.tvCount,
    sanctionedLoadKw: sanctionedLoadKw ?? this.sanctionedLoadKw,
    muctMonthly: muctMonthly ?? this.muctMonthly,
    monthlyAdjustments: monthlyAdjustments ?? this.monthlyAdjustments,
  );

  KETariffProfile withMonthlyAdjustment(
    DateTime month,
    KEMonthlyAdjustment adjustment,
  ) => copyWith(
    monthlyAdjustments: {...monthlyAdjustments, monthKey(month): adjustment},
  );

  static String monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';
}

class KETariffCalculation {
  final double units;
  final double baseRatePerUnit;
  final double variableCharges;
  final double fca;
  final double quarterlyAdjustment;
  final double phlSurcharge;
  final double fixedLoadKw;
  final double fixedRatePerKw;
  final double fixedCharges;
  final double minimumCharges;

  /// KE bill ki "Electricity Charges" line (duty/tax se pehle ka subtotal).
  final double electricityCharges;
  final double electricityDuty;
  final double muct;
  final double salesTax;
  final double tvLicense;
  final double incomeTax;
  final double total;
  final bool hasMonthlyAdjustments;

  const KETariffCalculation({
    required this.units,
    required this.baseRatePerUnit,
    required this.variableCharges,
    required this.fca,
    required this.quarterlyAdjustment,
    required this.phlSurcharge,
    required this.fixedLoadKw,
    required this.fixedRatePerKw,
    required this.fixedCharges,
    required this.minimumCharges,
    required this.electricityCharges,
    required this.electricityDuty,
    required this.muct,
    required this.salesTax,
    required this.tvLicense,
    required this.incomeTax,
    required this.total,
    required this.hasMonthlyAdjustments,
  });

  /// KE bill ka "Taxes and Duties" (+ income tax agar lagta ho).
  double get taxes => electricityDuty + salesTax + incomeTax + muct;

  /// Bill ki tarteeb ke mutabiq line items. Label translation keys hain —
  /// render ke waqt `.tr` se resolve hote hain.
  List<InvoiceLineItem> toInvoiceItems() => [
    InvoiceLineItem(
      label: 'bills_units_consumed',
      amountRs: units,
      isUnits: true,
    ),
    if (fixedCharges > 0)
      InvoiceLineItem(
        label: 'bills_fixed_charges',
        amountRs: fixedCharges,
        params: {
          'detail':
              '${_trim(fixedLoadKw)} kW × Rs. ${_trim(fixedRatePerKw)}',
        },
      ),
    InvoiceLineItem(
      label: 'bills_energy_charges',
      amountRs: variableCharges,
      params: {
        'detail': 'Rs. ${baseRatePerUnit.toStringAsFixed(2)}/kWh',
      },
    ),
    if (quarterlyAdjustment != 0)
      InvoiceLineItem(
        label: 'bills_quarterly_adjustment',
        amountRs: quarterlyAdjustment,
      ),
    if (fca != 0)
      InvoiceLineItem(label: 'bills_fca', amountRs: fca),
    InvoiceLineItem(
      label: 'bills_phr_surcharge',
      amountRs: phlSurcharge,
    ),
    if (minimumCharges > 0)
      InvoiceLineItem(
        label: 'bills_minimum_charges',
        amountRs: minimumCharges,
      ),
    InvoiceLineItem(
      label: 'bills_electricity_charges',
      amountRs: electricityCharges,
      isDivider: true,
    ),
    if (electricityDuty > 0)
      InvoiceLineItem(
        label: 'bills_electricity_duty',
        amountRs: electricityDuty,
      ),
    InvoiceLineItem(label: 'bills_sales_tax', amountRs: salesTax),
    if (muct > 0) InvoiceLineItem(label: 'bills_muct', amountRs: muct),
    if (tvLicense > 0)
      InvoiceLineItem(label: 'bills_tv_licence', amountRs: tvLicense),
    if (incomeTax > 0)
      InvoiceLineItem(label: 'bills_income_tax', amountRs: incomeTax),
  ];

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}

/// K-Electric A1-R (domestic) bill calculator.
///
/// Formula Jun/Jul/Aug/Sep-2026 ke asal bills se nikala gaya hai aur un
/// chaaron bills ka total paisa-paisa match karta hai:
///  * Units <= 200  -> Rs. 28.91/kWh (Unprotected), fixed Rs. 300/kW
///  * Units >= 201  -> Rs. 33.10/kWh (saare units par), fixed Rs. 350/kW
///  * Fixed = sanctioned load (kW) x fixed rate
///  * PHL surcharge = Rs. 3.23 x units
///  * FCA = FCA rate x FCA units (2 mahine pehle ke units)
///  * Uniform Quarterly Adjustment = units x rate (kabhi 2 rates mein split)
///  * Electricity Charges = fixed + energy + UQA + FCA + PHL
///  * Electricity duty = 1.5% x (Electricity Charges - fixed)
///  * Sales tax = 18% x (Electricity Charges + duty)
///  * MUCT = Rs. 20 (<=200 units) ya Rs. 40 (201+ units)
///  * Total = Electricity Charges + duty + sales tax + MUCT
class KETariffCalculator {
  static const double lowSlabMaxUnits = 200;
  static const double lowSlabRate = 28.91;
  static const double highSlabRate = 33.10; // 201-300 bill par verify hua
  static const double lowFixedRatePerKw = 300;
  static const double highFixedRatePerKw = 350;
  static const double defaultSanctionedLoadKw = 4;
  static const double phlPerUnit = 3.23;
  static const double electricityDutyRate = 0.015;
  static const double salesTaxRate = 0.18;
  static const double incomeTaxRate = 0.075;
  static const double lowMuct = 20;
  static const double highMuct = 40;
  static const double tvLicensePerSet = 35;
  static const String schedule = 'K-Electric A1-R (bills Jun–Sep 2026)';

  /// KE ke asal bills se FCA / UQA rates (sab A1-R customers ke liye ek jaisi).
  static const Map<String, KEMonthlyAdjustment> publishedAdjustments = {
    '2026-06': KEMonthlyAdjustment(
      fcaPerUnit: 1.1907, // FCA Apr-26
      quarterlyAdjustmentPerUnit: -1.9857,
      secondQuarterlyAdjustmentPerUnit: 0.3504,
      secondQuarterlyShare: 8 / 31,
    ),
    '2026-07': KEMonthlyAdjustment(
      fcaPerUnit: 0.3364, // FCA May-26
      quarterlyAdjustmentPerUnit: -1.9857,
    ),
    '2026-08': KEMonthlyAdjustment(
      fcaPerUnit: 0.7503, // FCA Jun-26
      quarterlyAdjustmentPerUnit: -1.9857,
    ),
    '2026-09': KEMonthlyAdjustment(
      fcaPerUnit: 2.0581, // FCA Jul-26
      quarterlyAdjustmentPerUnit: -1.9857,
      secondQuarterlyAdjustmentPerUnit: 0.5194,
      secondQuarterlyShare: 22 / 31,
    ),
  };

  /// Jis mahine ka asal bill abhi maloom nahi, uske liye aakhri published
  /// rates aage barha kar andaza (isEstimate = true).
  static KEMonthlyAdjustment estimatedAdjustmentFor(DateTime month) {
    final key = KETariffProfile.monthKey(month);
    final latestKey = publishedAdjustments.keys.reduce(
      (a, b) => a.compareTo(b) >= 0 ? a : b,
    );
    if (key.compareTo(latestKey) <= 0) return const KEMonthlyAdjustment();
    final last = publishedAdjustments[latestKey]!;
    return KEMonthlyAdjustment(
      fcaPerUnit: last.fcaPerUnit,
      quarterlyAdjustmentPerUnit:
          last.secondQuarterlyAdjustmentPerUnit ??
          last.quarterlyAdjustmentPerUnit,
      isEstimate: true,
    );
  }

  /// FCA bill mein 2 mahine pehle ke units par lagta hai (Aug bill -> Jun
  /// units). History mein wo mahina ho to uske units, warna null.
  static double? fcaUnitsFromUsage(
    Iterable<DatedDailyUsage> usage,
    DateTime billingMonth,
  ) {
    final target = DateTime(billingMonth.year, billingMonth.month - 2);
    var total = 0.0;
    for (final entry in usage) {
      if (entry.date.year == target.year && entry.date.month == target.month) {
        total += entry.kwh;
      }
    }
    return total > 0 ? total : null;
  }

  static KETariffCalculation calculate({
    required double units,
    required KETariffProfile profile,
    required DateTime billingMonth,
    double? fcaUnits,
  }) {
    final billedUnits = units.isFinite && units > 0 ? units : 0.0;
    final adjustment = profile.adjustmentsFor(billingMonth);
    final isLowSlab = billedUnits <= lowSlabMaxUnits;

    // Energy: 200 units tak Rs. 28.91, 201 se upar saare units par Rs. 33.10.
    final baseRate =
        adjustment.variableRatePerUnit ??
        (isLowSlab ? lowSlabRate : highSlabRate);
    final variable = _round(billedUnits * baseRate);

    // Fixed: sanctioned load x rate (units <= 200 par 300, warna 350 per kW).
    final loadKw = profile.sanctionedLoadKw ?? defaultSanctionedLoadKw;
    final fixedRate =
        adjustment.fixedRatePerKw ??
        (isLowSlab ? lowFixedRatePerKw : highFixedRatePerKw);
    final fixed = billedUnits > 0 ? _round(loadKw * fixedRate) : 0.0;

    final phl = _round(billedUnits * phlPerUnit);

    final effectiveFcaUnits = adjustment.fcaUnits ?? fcaUnits ?? billedUnits;
    final fca = adjustment.fcaPerUnit == null
        ? 0.0
        : _round(effectiveFcaUnits * adjustment.fcaPerUnit!);

    // Uniform quarterly adjustment: bill mein kabhi 2 lines (2 rates).
    var quarterly = 0.0;
    if (adjustment.quarterlyAdjustmentPerUnit != null) {
      final secondRate = adjustment.secondQuarterlyAdjustmentPerUnit;
      final share = secondRate == null
          ? 0.0
          : (adjustment.secondQuarterlyShare ?? 0.0).clamp(0.0, 1.0).toDouble();
      quarterly = _round(
        _round(
              billedUnits *
                  (1 - share) *
                  adjustment.quarterlyAdjustmentPerUnit!,
            ) +
            (secondRate == null
                ? 0.0
                : _round(billedUnits * share * secondRate)),
      );
    }

    final minimumThreshold = profile.phase == KEPhase.single ? 75.0 : 150.0;
    final minimum = billedUnits > 0 && variable <= minimumThreshold
        ? _round(
            (minimumThreshold - variable - phl - fixed).clamp(
              0.0,
              double.infinity,
            ),
          )
        : 0.0;

    // Bill ki "Electricity Charges" line.
    final electricityCharges = _round(
      fixed + variable + quarterly + fca + phl + minimum,
    );

    // Duty: 1.5% of (Electricity Charges - fixed charges).
    final electricityDuty = adjustment.electricityDutyPerUnit != null
        ? _round(billedUnits * adjustment.electricityDutyPerUnit!)
        : (billedUnits > 20
              ? _round((electricityCharges - fixed) * electricityDutyRate)
              : 0.0);

    // Sales tax: 18% of (Electricity Charges + duty).
    final salesTax = _round(
      (electricityCharges + electricityDuty) * salesTaxRate,
    );

    // MUCT (KMC): 200 units tak Rs. 20, us se upar Rs. 40 (user override kar
    // sakta hai).
    final muct = billedUnits > 0
        ? (profile.muctMonthly ?? (isLowSlab ? lowMuct : highMuct))
        : 0.0;

    final tvLicense = profile.tvCount * tvLicensePerSet;
    final taxableAmount = electricityCharges + electricityDuty + salesTax;
    final incomeTax =
        !profile.incomeTaxExempted && taxableAmount + tvLicense >= 25000
        ? _round(taxableAmount * incomeTaxRate)
        : 0.0;

    final total = _round(
      electricityCharges +
          electricityDuty +
          salesTax +
          muct +
          tvLicense +
          incomeTax,
    );

    return KETariffCalculation(
      units: billedUnits,
      baseRatePerUnit: baseRate,
      variableCharges: variable,
      fca: fca,
      quarterlyAdjustment: quarterly,
      phlSurcharge: phl,
      fixedLoadKw: loadKw,
      fixedRatePerKw: fixedRate,
      fixedCharges: fixed,
      minimumCharges: minimum,
      electricityCharges: electricityCharges,
      electricityDuty: electricityDuty,
      muct: muct,
      salesTax: salesTax,
      tvLicense: tvLicense,
      incomeTax: incomeTax,
      total: total,
      hasMonthlyAdjustments: adjustment.isConfigured,
    );
  }

  static double _round(double value) => (value * 100).roundToDouble() / 100;
}

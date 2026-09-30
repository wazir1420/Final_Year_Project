import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/bills_controller.dart';
import '../models/ke_tariff_model.dart';

class KETariffSettingsSheet extends StatefulWidget {
  final BillsController controller;

  const KETariffSettingsSheet({super.key, required this.controller});

  @override
  State<KETariffSettingsSheet> createState() => _KETariffSettingsSheetState();
}

class _KETariffSettingsSheetState extends State<KETariffSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late KEPhase _phase;
  late bool _incomeTaxExempted;
  late final TextEditingController _tvCountController;

  // Profile-level (ek dafa set karein, jab tak load/rate na badle)
  late final TextEditingController _sanctionedLoadController;
  late final TextEditingController _muctController;

  // Monthly (har mahine bill dekh kar update karein)
  late final TextEditingController _fcaController;
  late final TextEditingController _quarterlyController;
  late final TextEditingController _fixedRateController;
  late final TextEditingController _variableRateController;
  late final TextEditingController _dutyController;
  late final TextEditingController _fcaUnitsController;
  late final TextEditingController _secondQuarterlyController;
  late final TextEditingController _secondShareController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.tariffProfile.value;
    final resolved = profile.adjustmentsFor(
      DateTime(
        widget.controller.selectedMonth.value.year,
        widget.controller.selectedMonth.value.month,
      ),
    );
    // Aage barhayi hui (andaza wali) rates form mein prefill na hon, warna
    // save karte hi wo asal bill ki rates ban jati hain.
    final adjustment = resolved.isEstimate
        ? const KEMonthlyAdjustment()
        : resolved;
    _phase = profile.phase;
    _incomeTaxExempted = profile.incomeTaxExempted;
    _tvCountController = TextEditingController(text: '${profile.tvCount}');

    _sanctionedLoadController = TextEditingController(
      text: profile.sanctionedLoadKw?.toString() ?? '',
    );
    _muctController = TextEditingController(
      text: profile.muctMonthly?.toString() ?? '',
    );

    _fcaController = TextEditingController(
      text: adjustment.fcaPerUnit?.toString() ?? '',
    );
    _quarterlyController = TextEditingController(
      text: adjustment.quarterlyAdjustmentPerUnit?.toString() ?? '',
    );
    _fixedRateController = TextEditingController(
      text: adjustment.fixedRatePerKw?.toString() ?? '',
    );
    _variableRateController = TextEditingController(
      text: adjustment.variableRatePerUnit?.toString() ?? '',
    );
    _dutyController = TextEditingController(
      text: adjustment.electricityDutyPerUnit?.toString() ?? '',
    );
    _fcaUnitsController = TextEditingController(
      text: adjustment.fcaUnits?.toString() ?? '',
    );
    _secondQuarterlyController = TextEditingController(
      text: adjustment.secondQuarterlyAdjustmentPerUnit?.toString() ?? '',
    );
    _secondShareController = TextEditingController(
      text: adjustment.secondQuarterlyShare == null
          ? ''
          : (adjustment.secondQuarterlyShare! * 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _tvCountController.dispose();
    _sanctionedLoadController.dispose();
    _muctController.dispose();
    _fcaController.dispose();
    _quarterlyController.dispose();
    _fixedRateController.dispose();
    _variableRateController.dispose();
    _dutyController.dispose();
    _fcaUnitsController.dispose();
    _secondQuarterlyController.dispose();
    _secondShareController.dispose();
    super.dispose();
  }

  String? _validateAdjustment(String? value) {
    final fcaValue = _fcaController.text.trim();
    final quarterlyValue = _quarterlyController.text.trim();
    if (fcaValue.isEmpty && quarterlyValue.isEmpty) return null;
    if (fcaValue.isEmpty || quarterlyValue.isEmpty) {
      return 'tariff_error_both_adjustments'.tr;
    }
    if (double.tryParse(value?.trim() ?? '') == null) {
      return 'tariff_error_invalid_amount'.tr;
    }
    return null;
  }

  String? _validateOptionalNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (double.tryParse(text) == null) {
      return 'tariff_error_invalid_number'.tr;
    }
    return null;
  }

  String? _validateSecondPair(String? value) {
    final rate = _secondQuarterlyController.text.trim();
    final share = _secondShareController.text.trim();
    if (rate.isEmpty && share.isEmpty) return null;
    if (rate.isEmpty || share.isEmpty) {
      return 'tariff_error_second_pair'.tr;
    }
    if (double.tryParse(value?.trim() ?? '') == null) {
      return 'tariff_error_invalid_number'.tr;
    }
    return null;
  }

  String? _validateSecondShare(String? value) {
    final error = _validateSecondPair(value);
    if (error != null) return error;
    final number = double.tryParse(value?.trim() ?? '');
    if (number != null && (number < 0 || number > 100)) {
      return 'tariff_error_share_range'.tr;
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final oldProfile = widget.controller.tariffProfile.value;
      final month = DateTime(
        widget.controller.selectedMonth.value.year,
        widget.controller.selectedMonth.value.month,
      );
      final fcaText = _fcaController.text.trim();
      final quarterlyText = _quarterlyController.text.trim();
      final fixedRateText = _fixedRateController.text.trim();
      final variableRateText = _variableRateController.text.trim();
      final dutyText = _dutyController.text.trim();
      final fcaUnitsText = _fcaUnitsController.text.trim();
      final secondQText = _secondQuarterlyController.text.trim();
      final secondShareText = _secondShareController.text.trim();

      final adjustments = Map<String, KEMonthlyAdjustment>.from(
        oldProfile.monthlyAdjustments,
      );
      final key = KETariffProfile.monthKey(month);

      final noAdjustmentGiven =
          fcaText.isEmpty &&
          quarterlyText.isEmpty &&
          fixedRateText.isEmpty &&
          variableRateText.isEmpty &&
          dutyText.isEmpty &&
          fcaUnitsText.isEmpty &&
          secondQText.isEmpty &&
          secondShareText.isEmpty;

      if (noAdjustmentGiven) {
        adjustments.remove(key);
      } else {
        adjustments[key] = KEMonthlyAdjustment(
          fcaPerUnit: fcaText.isEmpty ? null : double.parse(fcaText),
          quarterlyAdjustmentPerUnit: quarterlyText.isEmpty
              ? null
              : double.parse(quarterlyText),
          fcaUnits: fcaUnitsText.isEmpty ? null : double.parse(fcaUnitsText),
          secondQuarterlyAdjustmentPerUnit: secondQText.isEmpty
              ? null
              : double.parse(secondQText),
          secondQuarterlyShare: secondShareText.isEmpty
              ? null
              : double.parse(secondShareText) / 100,
          fixedRatePerKw: fixedRateText.isEmpty
              ? null
              : double.parse(fixedRateText),
          variableRatePerUnit: variableRateText.isEmpty
              ? null
              : double.parse(variableRateText),
          electricityDutyPerUnit: dutyText.isEmpty
              ? null
              : double.parse(dutyText),
        );
      }

      final sanctionedLoadText = _sanctionedLoadController.text.trim();
      final muctText = _muctController.text.trim();

      final profile = oldProfile.copyWith(
        phase: _phase,
        incomeTaxExempted: _incomeTaxExempted,
        tvCount: int.parse(_tvCountController.text.trim()),
        sanctionedLoadKw: sanctionedLoadText.isEmpty
            ? null
            : double.parse(sanctionedLoadText),
        muctMonthly: muctText.isEmpty ? null : double.parse(muctText),
        monthlyAdjustments: adjustments,
      );
      await widget.controller.saveTariffProfile(profile);
      Get.back();
      Get.snackbar('tariff_saved_title'.tr, 'tariff_saved_msg'.tr);
    } catch (error) {
      Get.snackbar(
        'tariff_save_error_title'.tr,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final month = widget.controller.selectedMonth.value;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle — isay kisi bhi waqt neeche kheenchne se
              // sheet band ho jati hai, chahe form kitna bhi scroll ho ──
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 6) {
                    Get.back();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'tariff_title'.tr,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'tariff_non_tou'.trParams({'month': month.label}),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<KEPhase>(
                          initialValue: _phase,
                          decoration: InputDecoration(
                            labelText: 'tariff_phase'.tr,
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: KEPhase.single,
                              child: Text('tariff_single_phase'.tr),
                            ),
                            DropdownMenuItem(
                              value: KEPhase.threePhaseNonToU,
                              child: Text('tariff_three_phase'.tr),
                            ),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _phase = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text('tariff_income_tax_exempt'.tr),
                          subtitle: Text('tariff_fbr_note'.tr),
                          value: _incomeTaxExempted,
                          onChanged: _saving
                              ? null
                              : (value) =>
                                    setState(() => _incomeTaxExempted = value),
                        ),
                        TextFormField(
                          controller: _tvCountController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'tariff_tv_sets'.tr,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final count = int.tryParse(value?.trim() ?? '');
                            if (count == null || count < 0 || count > 20) {
                              return 'tariff_tv_sets_error'.tr;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),
                        Text(
                          'tariff_connection_details'.tr,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'tariff_connection_hint'.tr,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _sanctionedLoadController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'tariff_sanctioned_load'.tr,
                            suffixText: 'kW',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateOptionalNumber,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _muctController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'tariff_muct_label'.tr,
                            prefixText: 'Rs. ',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateOptionalNumber,
                        ),

                        const SizedBox(height: 20),
                        Text(
                          'tariff_monthly_rates'.tr,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'tariff_rates_hint'.tr,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _fixedRateController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'tariff_fixed_rate'.tr,
                            prefixText: 'Rs. ',
                            suffixText: '/ kW',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateOptionalNumber,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _variableRateController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'tariff_variable_rate'.tr,
                            prefixText: 'Rs. ',
                            suffixText: '/ kWh',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateOptionalNumber,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _dutyController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'tariff_duty_rate'.tr,
                            prefixText: 'Rs. ',
                            suffixText: '/ kWh',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateOptionalNumber,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _fcaController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'tariff_fca_label'.tr,
                            prefixText: 'Rs. ',
                            suffixText: '/ kWh',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateAdjustment,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _quarterlyController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'tariff_quarterly_label'.tr,
                            prefixText: 'Rs. ',
                            suffixText: '/ kWh',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateAdjustment,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _secondQuarterlyController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'tariff_second_quarterly'.tr,
                            helperText: 'tariff_second_quarterly_helper'.tr,
                            prefixText: 'Rs. ',
                            suffixText: '/ kWh',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateSecondPair,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _secondShareController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'tariff_units_second_rate'.tr,
                            helperText: 'tariff_units_second_helper'.tr,
                            suffixText: '%',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateSecondShare,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _fcaUnitsController,
                          enabled: !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'tariff_fca_units'.tr,
                            helperText: 'tariff_fca_units_helper'.tr,
                            suffixText: 'kWh',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateOptionalNumber,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('tariff_save'.tr),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

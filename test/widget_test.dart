// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finalyearproject/main.dart';
import 'package:finalyearproject/controllers/analytics_controller.dart';
import 'package:finalyearproject/models/meter_summary_model.dart';
import 'package:finalyearproject/models/ke_tariff_model.dart';
import 'package:finalyearproject/services/auth_service.dart';
import 'package:finalyearproject/services/firebase_history_service.dart';
import 'package:finalyearproject/widgets/app_bottom_nav_item.dart';
import 'package:finalyearproject/widgets/dashboard_widgets.dart';

void main() {
  test('MyApp instantiates', () {
    expect(const MyApp(), isNotNull);
  });

  testWidgets('bottom navigation item responds across its full hit area', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AppBottomNavItem(Icons.home, 'Home', false, () => taps++),
              AppBottomNavItem(Icons.settings, 'Settings', false, () {}),
            ],
          ),
        ),
      ),
    );

    final firstItem = tester.getRect(find.byType(AppBottomNavItem).first);
    await tester.tapAt(Offset(firstItem.left + 4, firstItem.top + 4));

    expect(taps, 1);
  });

  test('analytics filters store and reset time, weekday, and date ranges', () {
    final controller = AnalyticsController();

    controller.selectDay();
    controller.applyDayFilter(startHour: 9, endHour: 13);
    expect(controller.dayStartHour.value, 9);
    expect(controller.dayEndHour.value, 13);
    expect(controller.hasActiveFilter, isTrue);

    controller.selectWeek();
    controller.applyWeekFilter(startDay: 1, endDay: 4);
    expect(controller.weekStartDay.value, 1);
    expect(controller.weekEndDay.value, 4);

    controller.selectMonth();
    controller.applyMonthFilter(
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 15),
    );
    expect(controller.monthFilterStart.value, DateTime(2026, 9, 1));
    expect(controller.monthFilterEnd.value, DateTime(2026, 9, 15));

    controller.resetCurrentFilter();
    expect(controller.monthFilterStart.value, isNull);
    expect(controller.monthFilterEnd.value, isNull);
    expect(controller.hasActiveFilter, isFalse);
  });

  test('email validator rejects malformed addresses', () {
    expect(AuthService.isValidEmail('person@example.com'), isTrue);
    expect(AuthService.isValidEmail(' person@example.com '), isTrue);
    expect(AuthService.isValidEmail('person@localhost'), isFalse);
    expect(AuthService.isValidEmail('not-an-email'), isFalse);
    expect(AuthService.isValidEmail('person..name@example.com'), isFalse);
    expect(AuthService.isValidEmail('person@example..com'), isFalse);
    expect(AuthService.isValidEmail('person@example.c'), isFalse);
    expect(AuthService.isValidGmail('person@gmail.com'), isTrue);
    expect(AuthService.isValidGmail('person@example.com'), isFalse);
  });

  test('user profile reads an optional saved profile photo', () {
    final profile = UserProfile.fromJson('user-1', {
      'name': 'Ayesha Khan',
      'email': 'ayesha@example.com',
      'role': 'customer',
      'meters': {'meter-1': true},
      'profilePhoto': 'compressed-base64-photo',
    });
    final olderProfile = UserProfile.fromJson('user-2', {'name': 'Ali'});

    expect(profile.profilePhoto, 'compressed-base64-photo');
    expect(profile.meterIds, ['meter-1']);
    expect(olderProfile.profilePhoto, isEmpty);
  });

  test('Firebase history becomes sorted daily usage deltas', () {
    final usage = FirebaseHistoryService.parseDailyUsage({
      '2026-09-30': 35.0,
      '2026-09-28': 27.0,
      '2026-10-01': 2.0,
      '2026-09-29': 30.0,
    });

    expect(usage.map((entry) => entry.date.day), [29, 30, 1]);
    expect(usage.map((entry) => entry.kwh), [3.0, 5.0, 0.0]);
  });

  test('Firebase hourly history becomes per-hour kWh deltas', () {
    final hourly = FirebaseHistoryService.parseHourlyUsage({
      '2026-09-30': {'20': 0.10, '21': 0.21, '22': 0.35},
      '2026-09-29': {'23': 0.05},
    });

    // 29/23h (0.05) → 30/20h (0.10): 24h gap wali reading bhi ek delta hai.
    expect(hourly.length, 3);
    expect(hourly.first.hourStart, DateTime(2026, 9, 30, 20));
    expect(hourly.first.kwh, closeTo(0.05, 0.0001));
    expect(hourly[1].kwh, closeTo(0.11, 0.0001));
    expect(hourly[2].kwh, closeTo(0.14, 0.0001));
    expect(hourly.last.hour, 22);
  });

  test('Hourly parser handles h-prefixed map AND array formats', () {
    // ESP32 "h" prefix ke sath map bhejta hai; numeric keys wala purana
    // data Firebase array bana deta hai — dono parse hone chahiye.
    final hourly = FirebaseHistoryService.parseHourlyUsage({
      '2026-10-01': [0.22, 0.23], // Firebase array format
      '2026-10-02': {'h0': 0.30, 'h1': 0.35}, // h-prefix map
    });

    // Oct 1: 00:00 (0.22) aur 01:00 (0.23); Oct 2: 00:00 (0.30), 01:00 (0.35)
    expect(hourly.length, 3);
    expect(hourly[0].hourStart, DateTime(2026, 10, 1, 1));
    expect(hourly[0].kwh, closeTo(0.01, 0.0001));
    expect(hourly[1].hourStart, DateTime(2026, 10, 2, 0));
    expect(hourly[1].kwh, closeTo(0.07, 0.0001));
    expect(hourly[2].kwh, closeTo(0.05, 0.0001));
  });

  test('Hourly parser ignores a one-reading cumulative drop glitch', () {
    final hourly = FirebaseHistoryService.parseHourlyUsage({
      '2026-10-01': {'h1': 0.23},
      '2026-10-02': {'h0': 0.82, 'h1': 0.85},
      '2026-10-03': {'h0': 1.29, 'h1': 0.0, 'h2': 1.33},
    });

    expect(hourly.length, 4);
    expect(hourly[0].hourStart, DateTime(2026, 10, 2, 0));
    expect(hourly[0].kwh, closeTo(0.59, 0.0001));
    expect(hourly[1].hourStart, DateTime(2026, 10, 2, 1));
    expect(hourly[1].kwh, closeTo(0.03, 0.0001));
    expect(hourly[2].hourStart, DateTime(2026, 10, 3, 0));
    expect(hourly[2].kwh, closeTo(0.44, 0.0001));
    expect(hourly[3].hourStart, DateTime(2026, 10, 3, 2));
    expect(hourly[3].kwh, closeTo(0.04, 0.0001));
  });

  // ── K-Electric: asal bills (Sanc Load 4 kW, tariff A1-R) ────────────────
  // fcaUnits = bill par FCA line ke saamne likhe units (2 mahine pehle ke).
  group('KE calculator matches real K-Electric bills', () {
    KETariffCalculation bill(double units, double fcaUnits, int month) =>
        KETariffCalculator.calculate(
          units: units,
          profile: const KETariffProfile(),
          billingMonth: DateTime(2026, month),
          fcaUnits: fcaUnits,
        );

    test('Jun-2026: 289 units', () {
      final b = bill(289, 216, 6);
      expect(b.fixedCharges, 1400);
      expect(b.variableCharges, 9565.9);
      expect(b.phlSurcharge, 933.47);
      expect(b.electricityCharges, 11756.92);
      expect(b.electricityDuty, 155.35);
      expect(b.salesTax, 2144.21);
      expect(b.muct, 40);
      expect(b.total, closeTo(14096.48, 0.005));
    });

    test('Jul-2026: 254 units', () {
      final b = bill(254, 302, 7);
      expect(b.electricityCharges, 10225.04);
      expect(b.electricityDuty, 132.38);
      expect(b.salesTax, 1864.34);
      expect(b.total, closeTo(12261.76, 0.005));
    });

    test('Aug-2026: 249 units', () {
      final b = bill(249, 289, 8);
      expect(b.electricityCharges, 10168.57);
      expect(b.electricityDuty, 131.53);
      expect(b.salesTax, 1854.02);
      expect(b.total, closeTo(12194.12, 0.005));
    });

    test('Sep-2026: 200 units (Rs. 28.91 slab, fixed Rs. 300/kW, MUCT 20)', () {
      final b = bill(200, 254, 9);
      expect(b.baseRatePerUnit, 28.91);
      expect(b.variableCharges, 5782);
      expect(b.fixedCharges, 1200);
      expect(b.muct, 20);
      expect(b.electricityCharges, 8109.18);
      expect(b.electricityDuty, 103.64);
      expect(b.salesTax, 1478.31);
      expect(b.total, closeTo(9711.13, 0.005));
    });
  });

  test('KE rate changes at 201 units', () {
    final at200 = KETariffCalculator.calculate(
      units: 200,
      profile: const KETariffProfile(),
      billingMonth: DateTime(2026, 9),
    );
    final at201 = KETariffCalculator.calculate(
      units: 201,
      profile: const KETariffProfile(),
      billingMonth: DateTime(2026, 9),
    );

    expect(at200.baseRatePerUnit, 28.91);
    expect(at200.fixedCharges, 1200);
    expect(at201.baseRatePerUnit, 33.10);
    expect(at201.fixedCharges, 1400);
  });

  test('KE domestic tariff above 300 units uses the 201+ rate and fixed', () {
    final estimate = KETariffCalculator.calculate(
      units: 350,
      profile: const KETariffProfile(),
      billingMonth: DateTime(2026, 9),
    );

    expect(estimate.baseRatePerUnit, 33.10);
    expect(estimate.fixedCharges, 1400);
  });

  test(
    'KE tariff profiles preserve phase, tax, TV and monthly adjustments',
    () {
      const profile = KETariffProfile(
        phase: KEPhase.threePhaseNonToU,
        incomeTaxExempted: true,
        tvCount: 2,
        monthlyAdjustments: {
          '2026-09': KEMonthlyAdjustment(
            fcaPerUnit: 1.25,
            quarterlyAdjustmentPerUnit: -0.5,
          ),
        },
      );

      final restored = KETariffProfile.fromJson(profile.toJson());

      expect(restored.phase, KEPhase.threePhaseNonToU);
      expect(restored.incomeTaxExempted, isTrue);
      expect(restored.tvCount, 2);
      expect(restored.adjustmentsFor(DateTime(2026, 9)).fcaPerUnit, 1.25);
      expect(
        restored.adjustmentsFor(DateTime(2026, 9)).quarterlyAdjustmentPerUnit,
        -0.5,
      );
    },
  );

  test('meter without a reading is offline', () {
    final meter = MeterSummary.fromJson('new-meter', {'name': 'New meter'});

    expect(meter.isOnline, isFalse);
    expect(meter.activePower, 0);
  });

  test('meter with a fresh reading is online', () {
    final meter = MeterSummary.fromJson('live-meter', {
      'latest': {'timestamp': DateTime.now().millisecondsSinceEpoch},
    });

    expect(meter.isOnline, isTrue);
  });

  testWidgets('PowerHeroCard shows the connected meter name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PowerHeroCard(
            activePower: 12.5,
            avgVoltage: 230,
            totalCurrent: 18.4,
            powerFactor: 0.97,
            frequency: 50,
            meterName: 'CHINT DTSU666',
            phaseStatusLabel: '',
          ),
        ),
      ),
    );

    expect(find.textContaining('CHINT DTSU666'), findsOneWidget);
  });
}

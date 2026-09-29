// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finalyearproject/main.dart';
import 'package:finalyearproject/models/meter_summary_model.dart';
import 'package:finalyearproject/services/auth_service.dart';
import 'package:finalyearproject/widgets/dashboard_widgets.dart';

void main() {
  test('MyApp instantiates', () {
    expect(const MyApp(), isNotNull);
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

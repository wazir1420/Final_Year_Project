// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finalyearproject/main.dart';
import 'package:finalyearproject/widgets/dashboard_widgets.dart';

void main() {
  test('MyApp instantiates', () {
    expect(const MyApp(), isNotNull);
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

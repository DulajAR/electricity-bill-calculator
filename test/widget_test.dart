import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_bill_calculator/main.dart';

void main() {
  testWidgets('Electricity calculator home screen loads', (
    WidgetTester tester,
  ) async {
    // Launch the application.
    await tester.pumpWidget(const ElectricityBillApp());

    // Verify that the home screen is displayed.
    expect(find.text('Electricity Bill Calculator'), findsOneWidget);

    // Verify that the electricity providers are available.
    expect(find.text('CEB'), findsOneWidget);
    expect(find.text('LECO'), findsOneWidget);

    // Verify that the Calculate Bill button exists.
    expect(find.text('Calculate Bill'), findsOneWidget);

    // Verify the bottom navigation bar.
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

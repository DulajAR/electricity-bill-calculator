import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electricity_bill_calculator/services/bill_calculator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> tariff;

  setUpAll(() async {
    final content = await rootBundle.loadString(
      'assets/tariffs/domestic_2026_05_11.json',
    );

    tariff = jsonDecode(content) as Map<String, dynamic>;
  });

  BillResult calculate(int units, {int days = 30, String provider = 'CEB'}) {
    return BillCalculatorService.calculateWithTariff(
      units: units,
      provider: provider,
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 1 + days),
      tariff: tariff,
    );
  }

  group('JSON Bill Calculator Tests', () {
    test('30 units over 30 days', () {
      final result = calculate(30);

      expect(result.energyCharge, closeTo(150, 0.001));
      expect(result.fixedCharge, closeTo(80, 0.001));
      expect(result.total, closeTo(230, 0.001));
    });

    test('60 units over 30 days', () {
      final result = calculate(60);

      expect(result.energyCharge, closeTo(420, 0.001));
      expect(result.fixedCharge, closeTo(210, 0.001));
      expect(result.total, closeTo(630, 0.001));
    });

    test('90 units over 30 days', () {
      final result = calculate(90);

      expect(result.energyCharge, closeTo(1440, 0.001));
      expect(result.fixedCharge, closeTo(400, 0.001));
      expect(result.total, closeTo(1840, 0.001));
    });

    test('180 units over 30 days', () {
      final result = calculate(180);

      expect(result.energyCharge, closeTo(4920, 0.001));
      expect(result.fixedCharge, closeTo(1500, 0.001));
      expect(result.total, closeTo(6420, 0.001));
    });

    test('210 units over 30 days', () {
      final result = calculate(210);

      expect(result.energyCharge, closeTo(8850, 0.001));
      expect(result.fixedCharge, closeTo(2500, 0.001));
      expect(result.total, closeTo(11350, 0.001));
    });

    test('35-day billing period', () {
      final result = calculate(70, days: 35);

      expect(result.billingDays, 35);
      expect(result.energyCharge, closeTo(490, 0.001));
      expect(result.fixedCharge, closeTo(210, 0.001));
      expect(result.total, closeTo(700, 0.001));
    });

    test('CEB and LECO use same provisional rates', () {
      final ceb = calculate(90, provider: 'CEB');
      final leco = calculate(90, provider: 'LECO');

      expect(ceb.total, closeTo(leco.total, 0.001));
    });

    test('Rejects negative units', () {
      expect(() => calculate(-1), throwsArgumentError);
    });

    test('Rejects unsupported provider', () {
      expect(() => calculate(30, provider: 'UNKNOWN'), throwsArgumentError);
    });

    test('Returns tariff effective date', () {
      final result = calculate(30);

      expect(result.tariffEffectiveDate, '2026-05-11');
    });
  });
}

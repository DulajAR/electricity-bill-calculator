import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_bill_calculator/services/bill_calculator_service.dart';

void main() {
  final start = DateTime(2026, 6, 1);
  final end = DateTime(2026, 7, 1);

  group('Domestic electricity calculations', () {
    test('30 units', () {
      final result = BillCalculatorService.calculate(
        units: 30,
        provider: 'CEB',
        startDate: start,
        endDate: end,
      );

      expect(result.energyCharge, 150.00);
      expect(result.fixedCharge, 80.00);
      expect(result.total, 230.00);
    });

    test('60 units', () {
      final result = BillCalculatorService.calculate(
        units: 60,
        provider: 'LECO',
        startDate: start,
        endDate: end,
      );

      expect(result.total, 630.00);
    });

    test('90 units', () {
      final result = BillCalculatorService.calculate(
        units: 90,
        provider: 'CEB',
        startDate: start,
        endDate: end,
      );

      expect(result.total, 1840.00);
    });

    test('180 units', () {
      final result = BillCalculatorService.calculate(
        units: 180,
        provider: 'CEB',
        startDate: start,
        endDate: end,
      );

      expect(result.total, 6420.00);
    });

    test('210 units', () {
      final result = BillCalculatorService.calculate(
        units: 210,
        provider: 'LECO',
        startDate: start,
        endDate: end,
      );

      expect(result.total, 11350.00);
    });

    test('Rejects unsupported billing period', () {
      expect(
        () => BillCalculatorService.calculate(
          units: 100,
          provider: 'CEB',
          startDate: start,
          endDate: DateTime(2026, 6, 20),
        ),
        throwsArgumentError,
      );
    });
  });
}

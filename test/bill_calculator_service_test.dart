import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_bill_calculator/services/bill_calculator_service.dart';

void main() {
  final start = DateTime(2026, 6, 1);
  final end = DateTime(2026, 7, 1);

  group('Domestic electricity calculations', () {
    // ==========================================
    // 1. Standard 30-day billing tests
    // ==========================================

    test('30 units - 30 days', () {
      final result = BillCalculatorService.calculate(
        units: 30,
        provider: 'CEB',
        startDate: start,
        endDate: end,
      );

      expect(result.billingDays, 30);
      expect(result.energyCharge, 150.00);
      expect(result.fixedCharge, 80.00);
      expect(result.total, 230.00);
    });

    test('60 units - 30 days', () {
      final result = BillCalculatorService.calculate(
        units: 60,
        provider: 'LECO',
        startDate: start,
        endDate: end,
      );

      expect(result.total, 630.00);
    });

    test('90 units - 30 days', () {
      final result = BillCalculatorService.calculate(
        units: 90,
        provider: 'CEB',
        startDate: start,
        endDate: end,
      );

      expect(result.total, 1840.00);
    });

    test('180 units - 30 days', () {
      final result = BillCalculatorService.calculate(
        units: 180,
        provider: 'CEB',
        startDate: start,
        endDate: end,
      );

      expect(result.total, 6420.00);
    });

    test('210 units - 30 days', () {
      final result = BillCalculatorService.calculate(
        units: 210,
        provider: 'LECO',
        startDate: start,
        endDate: end,
      );

      expect(result.total, 11350.00);
    });

    // ==========================================
    // 2. Variable billing-period tests
    // ==========================================

    test('28-day period - 28 units', () {
      final result = BillCalculatorService.calculate(
        units: 28,
        provider: 'CEB',
        startDate: DateTime(2027, 2, 1),
        endDate: DateTime(2027, 3, 1),
      );

      expect(result.billingDays, 28);
      expect(result.energyCharge, 140.00);
      expect(result.fixedCharge, 80.00);
      expect(result.total, 220.00);
    });

    test('31-day period - 31 units', () {
      final result = BillCalculatorService.calculate(
        units: 31,
        provider: 'LECO',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 8, 1),
      );

      expect(result.billingDays, 31);
      expect(result.energyCharge, 155.00);
      expect(result.fixedCharge, 80.00);
      expect(result.total, 235.00);
    });

    test('35-day period - 70 units', () {
      final result = BillCalculatorService.calculate(
        units: 70,
        provider: 'CEB',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 7, 6),
      );

      expect(result.billingDays, 35);
      expect(result.energyCharge, 490.00);
      expect(result.fixedCharge, 210.00);
      expect(result.total, 700.00);
    });

    test('35-day period - 105 units', () {
      final result = BillCalculatorService.calculate(
        units: 105,
        provider: 'CEB',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 7, 6),
      );

      expect(result.billingDays, 35);
      expect(result.energyCharge, 1680.00);
      expect(result.fixedCharge, 400.00);
      expect(result.total, 2080.00);
    });

    // ==========================================
    // 3. Input validation tests
    // ==========================================

    test('Rejects negative electricity units', () {
      expect(
        () => BillCalculatorService.calculate(
          units: -10,
          provider: 'CEB',
          startDate: start,
          endDate: end,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects unsupported electricity provider', () {
      expect(
        () => BillCalculatorService.calculate(
          units: 100,
          provider: 'INVALID',
          startDate: start,
          endDate: end,
        ),
        throwsArgumentError,
      );
    });

    test('Rejects reversed billing dates', () {
      expect(
        () => BillCalculatorService.calculate(
          units: 100,
          provider: 'CEB',
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 6, 1),
        ),
        throwsArgumentError,
      );
    });

    test('Rejects billing periods before tariff effective date', () {
      expect(
        () => BillCalculatorService.calculate(
          units: 100,
          provider: 'CEB',
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2026, 5, 1),
        ),
        throwsArgumentError,
      );
    });

    // ==========================================
    // 4. Calculation consistency tests
    // ==========================================

    test('Total equals energy charge plus fixed charge', () {
      final result = BillCalculatorService.calculate(
        units: 150,
        provider: 'CEB',
        startDate: start,
        endDate: end,
      );

      expect(
        result.total,
        closeTo(result.energyCharge + result.fixedCharge, 0.001),
      );
    });

    test('Breakdown energy amounts add up correctly', () {
      final result = BillCalculatorService.calculate(
        units: 150,
        provider: 'LECO',
        startDate: start,
        endDate: end,
      );

      final breakdownTotal = result.breakdown.fold<double>(
        0.0,
        (sum, line) => sum + line.amount,
      );

      expect(breakdownTotal, closeTo(result.energyCharge, 0.001));
    });

    test('Prorated block units add up to consumed units', () {
      final result = BillCalculatorService.calculate(
        units: 105,
        provider: 'CEB',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 7, 6),
      );

      final blockUnits = result.breakdown.fold<double>(
        0.0,
        (sum, line) => sum + line.units,
      );

      expect(blockUnits, closeTo(105.0, 0.001));
    });
  });
}

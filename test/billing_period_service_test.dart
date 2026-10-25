import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_bill_calculator/services/billing_period_service.dart';

void main() {
  group('Billing period calculations', () {
    test('Calculates 28 billing days', () {
      final days = BillingPeriodService.billingDays(
        DateTime(2027, 2, 1),
        DateTime(2027, 3, 1),
      );

      expect(days, 28);
    });

    test('Calculates 30 billing days', () {
      final days = BillingPeriodService.billingDays(
        DateTime(2026, 6, 1),
        DateTime(2026, 7, 1),
      );

      expect(days, 30);
    });

    test('Calculates 31 billing days', () {
      final days = BillingPeriodService.billingDays(
        DateTime(2026, 7, 1),
        DateTime(2026, 8, 1),
      );

      expect(days, 31);
    });

    test('Calculates 35 billing days', () {
      final days = BillingPeriodService.billingDays(
        DateTime(2026, 6, 1),
        DateTime(2026, 7, 6),
      );

      expect(days, 35);
    });

    test('Prorates 30-unit block for 35 days', () {
      expect(BillingPeriodService.proratedThreshold(30, 35), 35.0);
    });

    test('Prorates 60-unit threshold for 28 days', () {
      expect(BillingPeriodService.proratedThreshold(60, 28), 56.0);
    });

    test('Calculates monthly-equivalent consumption', () {
      expect(BillingPeriodService.monthlyEquivalentUnits(70, 35), 60.0);
    });

    test('Rejects invalid date range', () {
      expect(
        () => BillingPeriodService.billingDays(
          DateTime(2026, 7, 1),
          DateTime(2026, 6, 1),
        ),
        throwsArgumentError,
      );
    });
  });
}


import 'billing_period_service.dart';

class BillChargeLine {
  final String description;
  final double units;
  final double rate;
  final double amount;

  const BillChargeLine({
    required this.description,
    required this.units,
    required this.rate,
    required this.amount,
  });
}

class BillResult {
  final int units;
  final int billingDays;
  final String provider;
  final double energyCharge;
  final double fixedCharge;
  final double total;
  final String tariffEffectiveDate;
  final List<BillChargeLine> breakdown;

  const BillResult({
    required this.units,
    required this.billingDays,
    required this.provider,
    required this.energyCharge,
    required this.fixedCharge,
    required this.total,
    required this.tariffEffectiveDate,
    required this.breakdown,
  });
}

class BillCalculatorService {
  static const String tariffEffectiveDate = '2026-05-11';

  // This is a provisional tariff implementation.
  // Rates are preserved from the existing calculation service.
  // Production use requires effective-date tariff selection
  // and verification of the billing/rounding rules.

  static BillResult calculate({
    required int units,
    required String provider,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (units < 0) {
      throw ArgumentError('Units cannot be negative.');
    }

    if (provider != 'CEB' && provider != 'LECO') {
      throw ArgumentError('Unsupported provider.');
    }

    final days = BillingPeriodService.billingDays(
      startDate,
      endDate,
    );

    final start = DateTime.utc(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final effective = DateTime.utc(2026, 5, 11);

    if (start.isBefore(effective)) {
      throw ArgumentError(
        'This tariff version supports periods starting '
        'on or after 11 May 2026.',
      );
    }

    // A later tariff revision must be handled by a
    // versioned tariff selector before production release.

    final monthlyEquivalent =
        BillingPeriodService.monthlyEquivalentUnits(
          units,
          days,
        );

    double threshold(int monthlyLimit) {
      return BillingPeriodService.proratedThreshold(
        monthlyLimit,
        days,
      );
    }

    final breakdown = <BillChargeLine>[];

    void addBlock(
      String description,
      double lower,
      double? upper,
      double rate,
    ) {
      final blockUnits = upper == null
          ? (units - lower).clamp(0.0, double.infinity).toDouble()
          : (units.toDouble() - lower)
                .clamp(0.0, upper - lower)
                .toDouble();

      if (blockUnits <= 0) return;

      breakdown.add(
        BillChargeLine(
          description: description,
          units: blockUnits,
          rate: rate,
          amount: blockUnits * rate,
        ),
      );
    }

    double fixedCharge;

    if (monthlyEquivalent <= 60) {
      addBlock(
        '0-30 kWh (prorated)',
        0,
        threshold(30),
        5.00,
      );

      addBlock(
        '31-60 kWh (prorated)',
        threshold(30),
        threshold(60),
        9.00,
      );

      fixedCharge =
          monthlyEquivalent <= 30 ? 80.00 : 210.00;
    } else if (monthlyEquivalent <= 180) {
      addBlock(
        '0-60 kWh (prorated)',
        0,
        threshold(60),
        14.00,
      );

      addBlock(
        '61-90 kWh (prorated)',
        threshold(60),
        threshold(90),
        20.00,
      );

      addBlock(
        '91-120 kWh (prorated)',
        threshold(90),
        threshold(120),
        28.00,
      );

      addBlock(
        '121-180 kWh (prorated)',
        threshold(120),
        threshold(180),
        44.00,
      );

      if (monthlyEquivalent <= 90) {
        fixedCharge = 400.00;
      } else if (monthlyEquivalent <= 120) {
        fixedCharge = 1000.00;
      } else {
        fixedCharge = 1500.00;
      }
    } else {
      addBlock(
        '0-180 kWh (prorated)',
        0,
        threshold(180),
        32.50,
      );

      addBlock(
        'Above 180 kWh (prorated)',
        threshold(180),
        null,
        100.00,
      );

      fixedCharge = 2500.00;
    }

    final energyCharge = breakdown.fold<double>(
      0.0,
      (sum, line) => sum + line.amount,
    );

    return BillResult(
      units: units,
      billingDays: days,
      provider: provider,
      energyCharge: energyCharge,
      fixedCharge: fixedCharge,
      total: energyCharge + fixedCharge,
      tariffEffectiveDate: tariffEffectiveDate,
      breakdown: breakdown,
    );
  }
}

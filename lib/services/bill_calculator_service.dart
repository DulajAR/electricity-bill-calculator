import 'billing_period_service.dart';
import 'tariff_validator.dart';

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

  // Legacy calculation method retained for compatibility.
  // Uses the same provisional rates as the original service.
  static BillResult calculate({
    required int units,
    required String provider,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final tariff = <String, dynamic>{
      'id': 'domestic_2026_05_11',
      'effectiveDate': tariffEffectiveDate,
      'category': 'domestic',
      'currency': 'LKR',
      'referenceDays': 30,
      'provider': ['CEB', 'LECO'],
      'lowConsumption': {
        'maximumMonthlyUnits': 60,
        'blocks': [
          {'upTo': 30, 'rate': 5.0},
          {'upTo': 60, 'rate': 9.0},
        ],
        'fixedCharges': [
          {'upTo': 30, 'amount': 80.0},
          {'upTo': 60, 'amount': 210.0},
        ],
      },
      'mediumConsumption': {
        'maximumMonthlyUnits': 180,
        'blocks': [
          {'upTo': 60, 'rate': 14.0},
          {'upTo': 90, 'rate': 20.0},
          {'upTo': 120, 'rate': 28.0},
          {'upTo': 180, 'rate': 44.0},
        ],
        'fixedCharges': [
          {'upTo': 90, 'amount': 400.0},
          {'upTo': 120, 'amount': 1000.0},
          {'upTo': 180, 'amount': 1500.0},
        ],
      },
      'highConsumption': {
        'minimumMonthlyUnitsExclusive': 180,
        'blocks': [
          {'upTo': 180, 'rate': 32.5},
          {'upTo': null, 'rate': 100.0},
        ],
        'fixedCharge': 2500.0,
      },
    };

    return calculateWithTariff(
      units: units,
      provider: provider,
      startDate: startDate,
      endDate: endDate,
      tariff: tariff,
    );
  }

  // JSON-driven calculation method.
  //
  // IMPORTANT:
  // Accepting tariff data here does not mean the
  // tariff is officially verified. Production callers
  // must obtain approved data from TariffRepository.
  static BillResult calculateWithTariff({
    required int units,
    required String provider,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> tariff,
  }) {
    if (units < 0) {
      throw ArgumentError('Units cannot be negative.');
    }

    TariffValidator.validate(tariff);

    final providers = tariff['provider'] as List;

    if (!providers.contains(provider)) {
      throw ArgumentError('Unsupported provider.');
    }

    final days = BillingPeriodService.billingDays(startDate, endDate);

    final effectiveText = tariff['effectiveDate'];

    if (effectiveText is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(effectiveText)) {
      throw const FormatException('Invalid tariff effective date.');
    }

    final effective = DateTime.tryParse(effectiveText);

    if (effective == null ||
        effective.toIso8601String().substring(0, 10) != effectiveText) {
      throw const FormatException('Invalid tariff effective date.');
    }

    final start = DateTime.utc(startDate.year, startDate.month, startDate.day);

    if (start.isBefore(effective)) {
      throw ArgumentError(
        'Billing period starts before the tariff '
        'effective date.',
      );
    }

    // A future tariff revision during this period
    // requires separate period-aware handling.

    final monthlyEquivalent = BillingPeriodService.monthlyEquivalentUnits(
      units,
      days,
    );

    final low = tariff['lowConsumption'] as Map<String, dynamic>;

    final medium = tariff['mediumConsumption'] as Map<String, dynamic>;

    final high = tariff['highConsumption'] as Map<String, dynamic>;

    final lowMaximum = (low['maximumMonthlyUnits'] as num).toDouble();

    final mediumMaximum = (medium['maximumMonthlyUnits'] as num).toDouble();

    final Map<String, dynamic> section;

    if (monthlyEquivalent <= lowMaximum) {
      section = low;
    } else if (monthlyEquivalent <= mediumMaximum) {
      section = medium;
    } else {
      section = high;
    }

    final breakdown = <BillChargeLine>[];

    final blocks = section['blocks'] as List;

    double previousLimit = 0;

    for (final item in blocks) {
      final block = item as Map<String, dynamic>;

      final limit = block['upTo'];
      final rate = (block['rate'] as num).toDouble();

      final lower = BillingPeriodService.proratedThreshold(
        previousLimit.toInt(),
        days,
      );

      final double? upper = limit == null
          ? null
          : BillingPeriodService.proratedThreshold(
              (limit as num).toInt(),
              days,
            );

      final blockUnits = upper == null
          ? (units.toDouble() - lower).clamp(0.0, double.infinity).toDouble()
          : (units.toDouble() - lower).clamp(0.0, upper - lower).toDouble();

      if (blockUnits > 0) {
        breakdown.add(
          BillChargeLine(
            description: upper == null
                ? 'Above ${previousLimit.toInt()} kWh (prorated)'
                : '${previousLimit.toInt()}-${limit.toInt()} kWh (prorated)',
            units: blockUnits,
            rate: rate,
            amount: blockUnits * rate,
          ),
        );
      }

      if (limit != null) {
        previousLimit = (limit as num).toDouble();
      }
    }

    double fixedCharge;

    if (section == high) {
      fixedCharge = (high['fixedCharge'] as num).toDouble();
    } else {
      final charges = section['fixedCharges'] as List;

      final selectedCharge = charges.cast<Map<String, dynamic>>().firstWhere(
        (charge) => monthlyEquivalent <= (charge['upTo'] as num).toDouble(),
      );

      fixedCharge = (selectedCharge['amount'] as num).toDouble();
    }

    final energyCharge = breakdown.fold<double>(
      0,
      (sum, line) => sum + line.amount,
    );

    return BillResult(
      units: units,
      billingDays: days,
      provider: provider,
      energyCharge: energyCharge,
      fixedCharge: fixedCharge,
      total: energyCharge + fixedCharge,
      tariffEffectiveDate: effectiveText,
      breakdown: breakdown,
    );
  }
}

class BillChargeLine {
  final String description;
  final int units;
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
  final String provider;
  final double energyCharge;
  final double fixedCharge;
  final double total;
  final String tariffEffectiveDate;
  final List<BillChargeLine> breakdown;

  const BillResult({
    required this.units,
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

  // Initial scope: standard domestic block tariff,
  // exactly 30 billing days, effective from 11 May 2026.
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

    final days = DateTime.utc(endDate.year, endDate.month, endDate.day)
        .difference(
          DateTime.utc(startDate.year, startDate.month, startDate.day),
        )
        .inDays;

    if (days != 30) {
      throw ArgumentError('This version supports exactly 30 billing days.');
    }

    final effectiveDate = DateTime(2026, 5, 11);

    if (startDate.isBefore(effectiveDate)) {
      throw ArgumentError(
        'This tariff version supports periods starting '
        'on or after 11 May 2026.',
      );
    }

    final breakdown = <BillChargeLine>[];

    void addBlock(String description, int blockUnits, double rate) {
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

    if (units <= 60) {
      // Domestic consumption: 0-60 units
      addBlock('0-30 kWh', units.clamp(0, 30), 5.00);

      addBlock('31-60 kWh', (units - 30).clamp(0, 30), 9.00);

      fixedCharge = units <= 30 ? 80.00 : 210.00;
    } else if (units <= 180) {
      // Domestic consumption: 61-180 units
      addBlock('0-60 kWh', 60, 14.00);

      addBlock('61-90 kWh', (units - 60).clamp(0, 30), 20.00);

      addBlock('91-120 kWh', (units - 90).clamp(0, 30), 28.00);

      addBlock('121-180 kWh', (units - 120).clamp(0, 60), 44.00);

      if (units <= 90) {
        fixedCharge = 400.00;
      } else if (units <= 120) {
        fixedCharge = 1000.00;
      } else {
        fixedCharge = 1500.00;
      }
    } else {
      // Domestic consumption: above 180 units
      addBlock('0-180 kWh', 180, 32.50);

      addBlock('Above 180 kWh', units - 180, 100.00);

      fixedCharge = 2500.00;
    }

    final energyCharge = breakdown.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return BillResult(
      units: units,
      provider: provider,
      energyCharge: energyCharge,
      fixedCharge: fixedCharge,
      total: energyCharge + fixedCharge,
      tariffEffectiveDate: tariffEffectiveDate,
      breakdown: breakdown,
    );
  }
}

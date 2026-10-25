import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electricity_bill_calculator/services/tariff_validator.dart';

void main() {
  // Initialize Flutter test environment
  TestWidgetsFlutterBinding.ensureInitialized();

  // ==========================================
  // Helper: Generate valid test tariff data
  // ==========================================

  Map<String, dynamic> validTariff() {
    return {
      'category': 'domestic',
      'currency': 'LKR',
      'referenceDays': 30,
      'provider': ['CEB', 'LECO'],

      'lowConsumption': {
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
  }

  // ==========================================
  // Tariff Validator Tests
  // ==========================================

  group('Tariff Validator Tests', () {
    test('Accepts valid tariff structure', () {
      expect(() => TariffValidator.validate(validTariff()), returnsNormally);
    });

    test('Rejects unsupported currency', () {
      final tariff = validTariff();
      tariff['currency'] = 'USD';

      expect(() => TariffValidator.validate(tariff), throwsFormatException);
    });

    test('Rejects unsupported reference days', () {
      final tariff = validTariff();
      tariff['referenceDays'] = 31;

      expect(() => TariffValidator.validate(tariff), throwsFormatException);
    });

    test('Rejects missing consumption section', () {
      final tariff = validTariff();
      tariff.remove('mediumConsumption');

      expect(() => TariffValidator.validate(tariff), throwsFormatException);
    });

    test('Rejects negative tariff rates', () {
      final tariff = validTariff();

      final low = tariff['lowConsumption'] as Map<String, dynamic>;

      final blocks = low['blocks'] as List;

      final firstBlock = blocks.first as Map<String, dynamic>;

      firstBlock['rate'] = -5.0;

      expect(() => TariffValidator.validate(tariff), throwsFormatException);
    });

    test('Rejects decreasing block limits', () {
      final tariff = validTariff();

      final low = tariff['lowConsumption'] as Map<String, dynamic>;

      final blocks = low['blocks'] as List;

      final secondBlock = blocks[1] as Map<String, dynamic>;

      secondBlock['upTo'] = 20;

      expect(() => TariffValidator.validate(tariff), throwsFormatException);
    });

    test('Rejects negative fixed charges', () {
      final tariff = validTariff();

      final high = tariff['highConsumption'] as Map<String, dynamic>;

      high['fixedCharge'] = -100;

      expect(() => TariffValidator.validate(tariff), throwsFormatException);
    });

    test('Rejects invalid electricity providers', () {
      final tariff = validTariff();

      tariff['provider'] = ['UNKNOWN'];

      expect(() => TariffValidator.validate(tariff), throwsFormatException);
    });

    // ==========================================
    // Real JSON Asset Validation
    // ==========================================

    test('Bundled domestic tariff JSON has a valid structure', () async {
      final jsonString = await rootBundle.loadString(
        'assets/tariffs/domestic_2026_05_11.json',
      );

      final decoded = jsonDecode(jsonString);

      expect(decoded, isA<Map<String, dynamic>>());

      final tariff = decoded as Map<String, dynamic>;

      // Validate the tariff structure
      expect(() => TariffValidator.validate(tariff), returnsNormally);

      // Confirm tariff metadata
      expect(tariff['id'], 'domestic_2026_05_11');

      expect(tariff['category'], 'domestic');

      expect(tariff['currency'], 'LKR');

      expect(tariff['referenceDays'], 30);

      expect(tariff['status'], 'provisional');
    });
  });
}

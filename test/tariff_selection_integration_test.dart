import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_bill_calculator/services/tariff_cache_service.dart';
import 'package:electricity_bill_calculator/services/tariff_selection_service.dart';

void main() {
  late Directory tempDirectory;
  late TariffCacheService cache;
  late TariffSelectionService selector;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'tariff_selection_test_',
    );
    cache = TariffCacheService(cacheDirectory: tempDirectory);
    selector = TariffSelectionService(cacheService: cache);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Map<String, dynamic> verifiedTariff() => {
    'id': 'domestic_2026_05_11',
    'provider': ['CEB', 'LECO'],
    'category': 'domestic',
    'effectiveDate': '2026-05-11',
    'status': 'verified',
    'currency': 'LKR',
    'referenceDays': 30,
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

  Map<String, dynamic> entry({
    String id = 'domestic_2026_05_11',
    String status = 'verified',
    String effectiveDate = '2026-05-11',
    String? endDateExclusive,
  }) => {
    'id': id,
    'status': status,
    'effectiveDate': effectiveDate,
    'endDateExclusive': ?endDateExclusive,
  };

  Future<Map<String, dynamic>?> select(
    List<Map<String, dynamic>> entries, {
    DateTime? start,
    DateTime? end,
  }) => selector.selectTariff(
    startDate: start ?? DateTime(2026, 6, 1),
    endDate: end ?? DateTime(2026, 7, 1),
    tariffEntries: entries,
  );

  test(
    'selects a cached verified tariff covering the entire billing period',
    () async {
      await cache.saveTariff(verifiedTariff());
      final result = await select([entry()]);
      expect(result, isNotNull);
      expect(result!['id'], 'domestic_2026_05_11');
      expect(result['status'], 'verified');
    },
  );

  test(
    'returns null when a verified manifest entry has no cached file',
    () async {
      expect(await select([entry()]), isNull);
    },
  );

  test('does not select a provisional manifest entry', () async {
    await cache.saveTariff(verifiedTariff());
    expect(await select([entry(status: 'provisional')]), isNull);
  });

  test('does not select a tariff effective after the billing start', () async {
    await cache.saveTariff(verifiedTariff());
    expect(
      await select(
        [entry()],
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 6, 1),
      ),
      isNull,
    );
  });

  test('does not select a tariff that ends before the billing end', () async {
    await cache.saveTariff(verifiedTariff());
    expect(await select([entry(endDateExclusive: '2026-06-15')]), isNull);
  });

  test(
    'accepts a billing period ending exactly at the exclusive end date',
    () async {
      await cache.saveTariff(verifiedTariff());
      final result = await select([entry(endDateExclusive: '2026-07-01')]);
      expect(result, isNotNull);
    },
  );

  test(
    'rejects a cached tariff whose effective date differs from manifest',
    () async {
      await cache.saveTariff(verifiedTariff());
      await expectLater(
        select([entry(effectiveDate: '2026-05-12')]),
        throwsA(isA<FormatException>()),
      );
    },
  );
}


import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electricity_bill_calculator/services/tariff_cache_service.dart';
import 'package:electricity_bill_calculator/services/tariff_selection_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tariffId = 'domestic_2026_05_11';

  late Directory tempDirectory;
  late TariffCacheService cacheService;
  late TariffSelectionService selectionService;
  late List<Map<String, dynamic>> entries;

  setUp(() async {
    tempDirectory =
        await Directory.systemTemp.createTemp('selection_test_');

    cacheService = TariffCacheService(
      cacheDirectory: tempDirectory,
    );

    selectionService = TariffSelectionService(
      cacheService: cacheService,
    );

    final content = await rootBundle.loadString(
      'assets/tariffs/domestic_2026_05_11.json',
    );

    final tariff = jsonDecode(content) as Map<String, dynamic>;

    // Simulated verified status for testing only.
    // This does not verify the actual electricity rates.
    tariff['status'] = 'verified';

    await cacheService.saveTariff(tariff);

    entries = [
      {
        'id': tariffId,
        'effectiveDate': '2026-05-11',
        'endDateExclusive': null,
        'status': 'verified',
      },
    ];
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  // TEST 1
  test('Selects tariff for a valid billing period', () async {
    final result = await selectionService.selectTariff(
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30),
      tariffEntries: entries,
    );

    expect(result, isNotNull);
    expect(result!['id'], tariffId);
  });

  // TEST 2
  test('Rejects invalid billing dates', () async {
    await expectLater(
      selectionService.selectTariff(
        startDate: DateTime(2026, 6, 30),
        endDate: DateTime(2026, 6, 1),
        tariffEntries: entries,
      ),
      throwsArgumentError,
    );
  });

  // TEST 3
  test('Does not select a tariff before its effective date', () async {
    final result = await selectionService.selectTariff(
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 10),
      tariffEntries: entries,
    );

    expect(result, isNull);
  });

  // TEST 4
  test('Skips provisional manifest entries', () async {
    entries.first['status'] = 'provisional';

    final result = await selectionService.selectTariff(
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30),
      tariffEntries: entries,
    );

    expect(result, isNull);
  });

  // TEST 5
  test('Rejects billing periods spanning a tariff change', () async {
    entries.first['endDateExclusive'] = '2026-11-01';

    final result = await selectionService.selectTariff(
      startDate: DateTime(2026, 10, 20),
      endDate: DateTime(2026, 11, 10),
      tariffEntries: entries,
    );

    expect(result, isNull);
  });

  // TEST 6
  test('Allows a period ending at the tariff boundary', () async {
    entries.first['endDateExclusive'] = '2026-11-01';

    final result = await selectionService.selectTariff(
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 11, 1),
      tariffEntries: entries,
    );

    expect(result, isNotNull);
    expect(result!['id'], tariffId);
  });

  // TEST 7
  test('Returns null when the tariff is not cached', () async {
    entries.first['id'] = 'domestic_2026_06_01';

    final result = await selectionService.selectTariff(
      startDate: DateTime(2026, 6, 10),
      endDate: DateTime(2026, 6, 30),
      tariffEntries: entries,
    );

    expect(result, isNull);
  });

  // TEST 8
  test('Selects historical tariff instead of newer version', () async {
    entries.first['endDateExclusive'] = '2026-11-01';

    entries.add({
      'id': 'domestic_2026_11_01',
      'effectiveDate': '2026-11-01',
      'endDateExclusive': null,
      'status': 'verified',
    });

    final result = await selectionService.selectTariff(
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31),
      tariffEntries: entries,
    );

    expect(result, isNotNull);
    expect(result!['id'], tariffId);
  });

  // TEST 9
  test('Rejects overlapping tariff periods', () async {
    entries.add({
      'id': 'domestic_2026_06_01',
      'effectiveDate': '2026-06-01',
      'endDateExclusive': null,
      'status': 'verified',
    });

    await expectLater(
      selectionService.selectTariff(
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 30),
        tariffEntries: entries,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  // TEST 10
  test(
    'Does not substitute a tariff when correct version is missing',
    () async {
      entries.first['endDateExclusive'] = '2026-11-01';

      entries.add({
        'id': 'domestic_2026_11_01',
        'effectiveDate': '2026-11-01',
        'endDateExclusive': null,
        'status': 'verified',
      });

      // The November tariff is deliberately not cached.
      final result = await selectionService.selectTariff(
        startDate: DateTime(2026, 11, 5),
        endDate: DateTime(2026, 11, 30),
        tariffEntries: entries,
      );

      expect(result, isNull);
    },
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_bill_calculator/services/tariff_manifest_cache_service.dart';

void main() {
  late Directory temporaryDirectory;
  late TariffManifestCacheService cacheService;

  Map<String, dynamic> createValidManifest() {
    return {
      'schemaVersion': 1,
      'category': 'domestic',
      'tariffs': [
        {
          'id': 'domestic_2026_05_11',
          'effectiveDate': '2026-05-11',
          'endDateExclusive': null,
          'status': 'provisional',
        },
      ],
    };
  }

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'tariff_manifest_test_',
    );

    cacheService = TariffManifestCacheService(
      cacheDirectory: temporaryDirectory,
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('Saves and loads a valid manifest', () async {
    final manifest = createValidManifest();

    await cacheService.saveManifest(manifest);

    final loaded = await cacheService.loadManifest();

    expect(loaded, isNotNull);
    expect(loaded!['schemaVersion'], 1);
    expect(loaded['category'], 'domestic');
    expect((loaded['tariffs'] as List).length, 1);
  });

  test('Returns null when no cached manifest exists', () async {
    final loaded = await cacheService.loadManifest();

    expect(loaded, isNull);
  });

  test('Rejects unsupported manifest schema', () async {
    final manifest = createValidManifest();

    manifest['schemaVersion'] = 999;

    await expectLater(
      cacheService.saveManifest(manifest),
      throwsFormatException,
    );
  });

  test('Rejects invalid manifest entries', () async {
    final manifest = createValidManifest();

    manifest['tariffs'] = ['invalid entry'];

    await expectLater(
      cacheService.saveManifest(manifest),
      throwsFormatException,
    );
  });

  test('Returns null for corrupted cached JSON', () async {
    final file = File('${temporaryDirectory.path}/tariff_manifest.json');

    await file.writeAsString('{ this is not valid JSON');

    final loaded = await cacheService.loadManifest();

    expect(loaded, isNull);
  });

  test('Recovers an interrupted update from backup', () async {
    final manifest = createValidManifest();

    final backup = File('${temporaryDirectory.path}/tariff_manifest.json.bak');

    await backup.writeAsString(jsonEncode(manifest));

    final loaded = await cacheService.loadManifest();

    expect(loaded, isNotNull);
    expect(loaded!['schemaVersion'], 1);

    final restored = File('${temporaryDirectory.path}/tariff_manifest.json');

    expect(await restored.exists(), isTrue);
  });

  test('Invalid replacement does not overwrite existing manifest', () async {
    final original = createValidManifest();

    await cacheService.saveManifest(original);

    final invalid = createValidManifest();
    invalid['category'] = 'commercial';

    await expectLater(
      cacheService.saveManifest(invalid),
      throwsFormatException,
    );

    final loaded = await cacheService.loadManifest();

    expect(loaded, isNotNull);
    expect(loaded!['category'], 'domestic');
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_bill_calculator/services/tariff_cache_service.dart';
import 'package:electricity_bill_calculator/services/tariff_manifest_cache_service.dart';

void main() {
  late Directory temporaryDirectory;
  late TariffCacheService tariffCache;
  late TariffManifestCacheService manifestCache;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'electricity_tariff_cache_test_',
    );
    tariffCache = TariffCacheService(cacheDirectory: temporaryDirectory);
    manifestCache = TariffManifestCacheService(
      cacheDirectory: temporaryDirectory,
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('missing verified tariff returns null while offline', () async {
    final tariff = await tariffCache.loadTariff('domestic_2026_05_11');
    expect(tariff, isNull);
  });

  test('missing cached manifest returns null while offline', () async {
    final manifest = await manifestCache.loadManifest();
    expect(manifest, isNull);
  });

  test('provisional tariff cannot be saved as verified cache', () async {
    await expectLater(
      tariffCache.saveTariff({
        'id': 'domestic_2026_05_11',
        'status': 'provisional',
      }),
      throwsA(isA<FormatException>()),
    );
    expect(await tariffCache.loadTariff('domestic_2026_05_11'), isNull);
  });

  test('invalid tariff identifiers are rejected', () async {
    await expectLater(
      tariffCache.loadTariff('../outside_cache'),
      throwsA(isA<FormatException>()),
    );
  });

  test('corrupt cached tariff is never loaded', () async {
    final file = File('${temporaryDirectory.path}/domestic_2026_05_11.json');
    await file.writeAsString('not valid JSON');
    expect(await tariffCache.loadTariff('domestic_2026_05_11'), isNull);
  });

  test('unverified cached tariff is never loaded', () async {
    final file = File('${temporaryDirectory.path}/domestic_2026_05_11.json');
    await file.writeAsString(
      jsonEncode({'id': 'domestic_2026_05_11', 'status': 'provisional'}),
    );
    expect(await tariffCache.loadTariff('domestic_2026_05_11'), isNull);
  });

  test('corrupt cached manifest is never loaded', () async {
    final file = File('${temporaryDirectory.path}/tariff_manifest.json');
    await file.writeAsString('{bad json');
    expect(await manifestCache.loadManifest(), isNull);
  });

  test('unsupported manifest is never loaded', () async {
    final file = File('${temporaryDirectory.path}/tariff_manifest.json');
    await file.writeAsString(
      jsonEncode({'schemaVersion': 999, 'category': 'domestic', 'tariffs': []}),
    );
    expect(await manifestCache.loadManifest(), isNull);
  });
}

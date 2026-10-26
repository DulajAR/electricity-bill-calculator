import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:electricity_bill_calculator/services/remote_tariff_service.dart';
import 'package:electricity_bill_calculator/services/tariff_cache_service.dart';
import 'package:electricity_bill_calculator/services/tariff_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tariffId = 'domestic_2026_05_11';

  late Directory temporaryDirectory;
  late TariffCacheService cacheService;

  late Map<String, dynamic> verifiedTariff;
  late Map<String, dynamic> verifiedManifest;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'update_mock_test_',
    );

    cacheService = TariffCacheService(cacheDirectory: temporaryDirectory);

    final content = await rootBundle.loadString(
      'assets/tariffs/domestic_2026_05_11.json',
    );

    verifiedTariff = jsonDecode(content) as Map<String, dynamic>;

    // Simulated verified status for testing only.
    verifiedTariff['status'] = 'verified';

    verifiedManifest = {
      'schemaVersion': 1,
      'category': 'domestic',
      'tariffs': [
        {
          'id': tariffId,
          'effectiveDate': '2026-05-11',
          'endDateExclusive': null,
          'status': 'verified',
        },
      ],
    };
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('Downloads and caches a verified tariff', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('tariff_manifest.json')) {
        return http.Response(jsonEncode(verifiedManifest), 200);
      }

      if (request.url.path.endsWith('$tariffId.json')) {
        return http.Response(jsonEncode(verifiedTariff), 200);
      }

      return http.Response('Not found', 404);
    });

    final remote = RemoteTariffService(client: client);

    final updateService = TariffUpdateService(
      remoteService: remote,
      cacheService: cacheService,
    );

    final savedCount = await updateService.checkForUpdates();

    expect(savedCount, 1);

    final cached = await cacheService.loadTariff(tariffId);

    expect(cached, isNotNull);
    expect(cached!['status'], 'verified');
    expect(cached['id'], tariffId);
  });

  test('Skips provisional tariffs', () async {
    verifiedManifest['tariffs'][0]['status'] = 'provisional';

    final client = MockClient((request) async {
      if (request.url.path.endsWith('tariff_manifest.json')) {
        return http.Response(jsonEncode(verifiedManifest), 200);
      }

      return http.Response('Not found', 404);
    });

    final remote = RemoteTariffService(client: client);

    final updateService = TariffUpdateService(
      remoteService: remote,
      cacheService: cacheService,
    );

    final savedCount = await updateService.checkForUpdates();

    expect(savedCount, 0);
    expect(await cacheService.loadTariff(tariffId), isNull);
  });

  test('Rejects tariff metadata mismatch', () async {
    verifiedTariff['effectiveDate'] = '2026-06-01';

    final client = MockClient((request) async {
      if (request.url.path.endsWith('tariff_manifest.json')) {
        return http.Response(jsonEncode(verifiedManifest), 200);
      }

      if (request.url.path.endsWith('$tariffId.json')) {
        return http.Response(jsonEncode(verifiedTariff), 200);
      }

      return http.Response('Not found', 404);
    });

    final remote = RemoteTariffService(client: client);

    final updateService = TariffUpdateService(
      remoteService: remote,
      cacheService: cacheService,
    );

    await expectLater(
      updateService.checkForUpdates(),
      throwsA(isA<FormatException>()),
    );

    expect(await cacheService.loadTariff(tariffId), isNull);
  });

  test('Rejects invalid manifest JSON', () async {
    final client = MockClient((request) async {
      return http.Response('invalid json', 200);
    });

    final remote = RemoteTariffService(client: client);

    final updateService = TariffUpdateService(
      remoteService: remote,
      cacheService: cacheService,
    );

    await expectLater(
      updateService.checkForUpdates(),
      throwsA(isA<FormatException>()),
    );
  });
}

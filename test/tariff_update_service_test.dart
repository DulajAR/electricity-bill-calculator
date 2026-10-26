import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:electricity_bill_calculator/services/remote_tariff_service.dart';
import 'package:electricity_bill_calculator/services/tariff_cache_service.dart';
import 'package:electricity_bill_calculator/services/tariff_manifest_cache_service.dart';
import 'package:electricity_bill_calculator/services/tariff_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tariffId = 'domestic_2026_05_11';

  // TEST 1: Provisional tariffs must not be downloaded or cached.
  test('Skips provisional tariffs from GitHub manifest', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'tariff_update_test_',
    );

    var tariffDownloadRequests = 0;

    // Simulate a valid GitHub manifest without internet access.
    final client = MockClient((request) async {
      if (request.url.path.endsWith('tariff_manifest.json')) {
        return http.Response(
          jsonEncode({
            'schemaVersion': 1,
            'category': 'domestic',
            'tariffs': [
              {
                'id': tariffId,
                'effectiveDate': '2026-05-11',
                'endDateExclusive': null,
                'status': 'provisional',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      tariffDownloadRequests++;

      return http.Response('Unexpected tariff download', 500);
    });

    final remote = RemoteTariffService(client: client);

    try {
      final cache = TariffCacheService(cacheDirectory: temporaryDirectory);

      final updateService = TariffUpdateService(
        remoteService: remote,
        cacheService: cache,
      );

      final savedCount = await updateService.checkForUpdates();

      expect(savedCount, 0);
      expect(tariffDownloadRequests, 0);

      final cached = await cache.loadTariff(tariffId);

      expect(cached, isNull);
    } finally {
      remote.dispose();

      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  });

  group('GitHub tariff manifest validation', () {
    late Directory temporaryDirectory;
    late TariffCacheService cache;

    setUp(() async {
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'manifest_update_test_',
      );

      cache = TariffCacheService(cacheDirectory: temporaryDirectory);
    });

    tearDown(() async {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });

    // Helper: Verify invalid manifests are rejected.
    Future<void> expectInvalidManifest(List<dynamic> entries) async {
      var tariffDownloadRequests = 0;

      final client = MockClient((request) async {
        if (request.url.path.endsWith('tariff_manifest.json')) {
          return http.Response(
            jsonEncode({
              'schemaVersion': 1,
              'category': 'domestic',
              'tariffs': entries,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        tariffDownloadRequests++;

        return http.Response('Unexpected tariff download', 500);
      });

      final remote = RemoteTariffService(client: client);

      try {
        final updateService = TariffUpdateService(
          remoteService: remote,
          cacheService: cache,
        );

        await expectLater(
          updateService.checkForUpdates(),
          throwsA(isA<FormatException>()),
        );

        expect(tariffDownloadRequests, 0);

        final cached = await cache.loadTariff(tariffId);

        expect(cached, isNull);
      } finally {
        remote.dispose();
      }
    }

    // TEST 2: Duplicate tariff IDs.
    test('Rejects duplicate tariff IDs', () async {
      await expectInvalidManifest([
        {
          'id': tariffId,
          'effectiveDate': '2026-05-11',
          'endDateExclusive': '2026-11-01',
          'status': 'verified',
        },
        {
          'id': tariffId,
          'effectiveDate': '2026-11-01',
          'endDateExclusive': null,
          'status': 'verified',
        },
      ]);
    });

    // TEST 3: Overlapping verified periods.
    test('Rejects overlapping verified tariff periods', () async {
      await expectInvalidManifest([
        {
          'id': tariffId,
          'effectiveDate': '2026-05-11',
          'endDateExclusive': '2026-11-01',
          'status': 'verified',
        },
        {
          'id': 'domestic_2026_10_01',
          'effectiveDate': '2026-10-01',
          'endDateExclusive': null,
          'status': 'verified',
        },
      ]);
    });

    // TEST 4: Invalid calendar dates.
    test('Rejects invalid tariff calendar dates', () async {
      await expectInvalidManifest([
        {
          'id': tariffId,
          'effectiveDate': '2026-02-30',
          'endDateExclusive': null,
          'status': 'verified',
        },
      ]);
    });

    // TEST 5: Unsupported tariff status.
    test('Rejects unsupported tariff status', () async {
      await expectInvalidManifest([
        {
          'id': tariffId,
          'effectiveDate': '2026-05-11',
          'endDateExclusive': null,
          'status': 'unknown',
        },
      ]);
    });

    // TEST 6: Malformed manifest entries.
    test('Rejects malformed manifest entries', () async {
      await expectInvalidManifest([
        {
          'id': tariffId,
          'effectiveDate': '2026-05-11',
          'endDateExclusive': null,
          'status': 'verified',
        },
        'invalid_entry',
      ]);
    });

    // TEST 7: Partial download failure.
    test('Does not cache partial updates when a download fails', () async {
      const firstTariffId = 'domestic_2026_05_11';
      const secondTariffId = 'domestic_2026_11_01';

      // Load the bundled tariff as a test fixture.
      final content = await rootBundle.loadString(
        'assets/tariffs/domestic_2026_05_11.json',
      );

      final firstTariff = jsonDecode(content) as Map<String, dynamic>;

      // Simulate verified status for testing only.
      firstTariff['status'] = 'verified';

      var firstDownloadCount = 0;
      var secondDownloadCount = 0;

      final client = MockClient((request) async {
        if (request.url.path.endsWith('tariff_manifest.json')) {
          return http.Response(
            jsonEncode({
              'schemaVersion': 1,
              'category': 'domestic',
              'tariffs': [
                {
                  'id': firstTariffId,
                  'effectiveDate': '2026-05-11',
                  'endDateExclusive': '2026-11-01',
                  'status': 'verified',
                },
                {
                  'id': secondTariffId,
                  'effectiveDate': '2026-11-01',
                  'endDateExclusive': null,
                  'status': 'verified',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('$firstTariffId.json')) {
          firstDownloadCount++;

          return http.Response(
            jsonEncode(firstTariff),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('$secondTariffId.json')) {
          secondDownloadCount++;

          return http.Response('Simulated GitHub server failure', 500);
        }

        return http.Response('Not found', 404);
      });

      final remote = RemoteTariffService(client: client);

      try {
        final updateService = TariffUpdateService(
          remoteService: remote,
          cacheService: cache,
        );

        await expectLater(updateService.checkForUpdates(), throwsException);

        expect(firstDownloadCount, 1);
        expect(secondDownloadCount, 1);

        final firstCached = await cache.loadTariff(firstTariffId);

        final secondCached = await cache.loadTariff(secondTariffId);

        expect(firstCached, isNull);
        expect(secondCached, isNull);
      } finally {
        remote.dispose();
      }
    });

    // TEST 8: Successful downloads and cache reuse.
    test('Downloads verified tariffs and reuses cached versions', () async {
      const firstTariffId = 'domestic_2026_05_11';
      const secondTariffId = 'domestic_2026_11_01';

      // Load the bundled tariff as a valid test fixture.
      final content = await rootBundle.loadString(
        'assets/tariffs/domestic_2026_05_11.json',
      );

      final firstTariff = jsonDecode(content) as Map<String, dynamic>;

      // Simulate verified status only in memory.
      firstTariff['status'] = 'verified';

      // Create a second simulated tariff.
      final secondTariff =
          jsonDecode(jsonEncode(firstTariff)) as Map<String, dynamic>;

      secondTariff['id'] = secondTariffId;
      secondTariff['effectiveDate'] = '2026-11-01';

      var manifestDownloadCount = 0;
      var firstDownloadCount = 0;
      var secondDownloadCount = 0;

      final client = MockClient((request) async {
        if (request.url.path.endsWith('tariff_manifest.json')) {
          manifestDownloadCount++;

          return http.Response(
            jsonEncode({
              'schemaVersion': 1,
              'category': 'domestic',
              'tariffs': [
                {
                  'id': firstTariffId,
                  'effectiveDate': '2026-05-11',
                  'endDateExclusive': '2026-11-01',
                  'status': 'verified',
                },
                {
                  'id': secondTariffId,
                  'effectiveDate': '2026-11-01',
                  'endDateExclusive': null,
                  'status': 'verified',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('$firstTariffId.json')) {
          firstDownloadCount++;

          return http.Response(
            jsonEncode(firstTariff),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path.endsWith('$secondTariffId.json')) {
          secondDownloadCount++;

          return http.Response(
            jsonEncode(secondTariff),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not found', 404);
      });

      final remote = RemoteTariffService(client: client);

      try {
        final updateService = TariffUpdateService(
          remoteService: remote,
          cacheService: cache,
        );

        // First run: download and cache both tariffs.
        final firstSavedCount = await updateService.checkForUpdates();

        expect(firstSavedCount, 2);
        expect(firstDownloadCount, 1);
        expect(secondDownloadCount, 1);

        final firstCached = await cache.loadTariff(firstTariffId);

        final secondCached = await cache.loadTariff(secondTariffId);

        expect(firstCached, isNotNull);
        expect(secondCached, isNotNull);

        expect(firstCached!['id'], firstTariffId);
        expect(secondCached!['id'], secondTariffId);

        expect(firstCached['status'], 'verified');
        expect(secondCached['status'], 'verified');

        expect(firstCached['effectiveDate'], '2026-05-11');

        expect(secondCached['effectiveDate'], '2026-11-01');

        // Second run: reuse existing cached tariffs.
        final secondSavedCount = await updateService.checkForUpdates();

        expect(secondSavedCount, 0);

        // Manifest is checked again, but tariffs
        // must not be downloaded again.
        expect(manifestDownloadCount, 2);
        expect(firstDownloadCount, 1);
        expect(secondDownloadCount, 1);
      } finally {
        remote.dispose();
      }
    });

    // TEST 9: A failed download must not activate the remote manifest.
    test(
      'Keeps previous manifest active when a tariff download fails',
      () async {
        const secondTariffId = 'domestic_2026_11_01';
        final manifestCache = TariffManifestCacheService(
          cacheDirectory: temporaryDirectory,
        );
        final originalManifest = <String, dynamic>{
          'schemaVersion': 1,
          'category': 'domestic',
          'tariffs': [
            {
              'id': tariffId,
              'effectiveDate': '2026-05-11',
              'endDateExclusive': null,
              'status': 'provisional',
            },
          ],
        };
        await manifestCache.saveManifest(originalManifest);

        final content = await rootBundle.loadString(
          'assets/tariffs/domestic_2026_05_11.json',
        );
        final firstTariff = jsonDecode(content) as Map<String, dynamic>;
        firstTariff['status'] = 'verified'; // Test fixture only.

        final client = MockClient((request) async {
          if (request.url.path.endsWith('tariff_manifest.json')) {
            return http.Response(
              jsonEncode({
                'schemaVersion': 1,
                'category': 'domestic',
                'tariffs': [
                  {
                    'id': tariffId,
                    'effectiveDate': '2026-05-11',
                    'endDateExclusive': '2026-11-01',
                    'status': 'verified',
                  },
                  {
                    'id': secondTariffId,
                    'effectiveDate': '2026-11-01',
                    'endDateExclusive': null,
                    'status': 'verified',
                  },
                ],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('$tariffId.json')) {
            return http.Response(jsonEncode(firstTariff), 200);
          }
          if (request.url.path.endsWith('$secondTariffId.json')) {
            return http.Response('Simulated download failure', 500);
          }
          return http.Response('Not found', 404);
        });
        final remote = RemoteTariffService(client: client);
        try {
          final updater = TariffUpdateService(
            remoteService: remote,
            cacheService: cache,
            manifestCacheService: manifestCache,
          );
          await expectLater(updater.checkForUpdates(), throwsException);
          final activeManifest = await manifestCache.loadManifest();
          expect(activeManifest, equals(originalManifest));
          expect(await cache.loadTariff(tariffId), isNull);
          expect(await cache.loadTariff(secondTariffId), isNull);
        } finally {
          remote.dispose();
          client.close();
        }
      },
    );

    // TEST 10: A successful update activates the manifest after caching.
    test('Activates manifest only after verified tariff is cached', () async {
      final manifestCache = TariffManifestCacheService(
        cacheDirectory: temporaryDirectory,
      );
      final originalManifest = <String, dynamic>{
        'schemaVersion': 1,
        'category': 'domestic',
        'tariffs': [
          {
            'id': tariffId,
            'effectiveDate': '2026-05-11',
            'endDateExclusive': null,
            'status': 'provisional',
          },
        ],
      };
      await manifestCache.saveManifest(originalManifest);

      final content = await rootBundle.loadString(
        'assets/tariffs/domestic_2026_05_11.json',
      );
      final verifiedTariff = jsonDecode(content) as Map<String, dynamic>;
      verifiedTariff['status'] = 'verified'; // Test fixture only.
      final newManifest = <String, dynamic>{
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

      var tariffDownloads = 0;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('tariff_manifest.json')) {
          return http.Response(jsonEncode(newManifest), 200);
        }
        if (request.url.path.endsWith('$tariffId.json')) {
          tariffDownloads++;
          // The old manifest must still be active during downloads.
          expect(await manifestCache.loadManifest(), equals(originalManifest));
          return http.Response(jsonEncode(verifiedTariff), 200);
        }
        return http.Response('Not found', 404);
      });
      final remote = RemoteTariffService(client: client);
      try {
        final updater = TariffUpdateService(
          remoteService: remote,
          cacheService: cache,
          manifestCacheService: manifestCache,
        );
        expect(await updater.checkForUpdates(), 1);
        expect(tariffDownloads, 1);
        expect(await cache.loadTariff(tariffId), isNotNull);
        expect(await manifestCache.loadManifest(), equals(newManifest));
        // A second update reuses the cached tariff.
        expect(await updater.checkForUpdates(), 0);
        expect(tariffDownloads, 1);
      } finally {
        remote.dispose();
        client.close();
      }
    });
  });
}

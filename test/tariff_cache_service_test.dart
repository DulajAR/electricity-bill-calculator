import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:electricity_bill_calculator/services/tariff_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TariffCacheService', () {
    // Test 1: Reject provisional tariff data.
    test('Rejects provisional tariff data', () async {
      final service = TariffCacheService();

      final provisionalTariff = <String, dynamic>{
        'id': 'domestic_2026_05_11',
        'status': 'provisional',
      };

      await expectLater(
        service.saveTariff(provisionalTariff),
        throwsA(isA<FormatException>()),
      );
    });

    // Test 2: Reject invalid tariff IDs.
    test('Rejects invalid tariff IDs', () async {
      final service = TariffCacheService();

      final invalidTariff = <String, dynamic>{
        'id': '../invalid',
        'status': 'verified',
      };

      await expectLater(
        service.saveTariff(invalidTariff),
        throwsA(isA<FormatException>()),
      );
    });

    // Test 3: Save and reload a verified tariff offline.
    test('Saves and reloads a verified tariff offline', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'tariff_test_',
      );

      try {
        final service = TariffCacheService(cacheDirectory: tempDirectory);

        // Load the existing local tariff JSON.
        final content = await rootBundle.loadString(
          'assets/tariffs/domestic_2026_05_11.json',
        );

        final tariff = jsonDecode(content) as Map<String, dynamic>;

        // Test fixture only:
        // This does not mean the actual tariff is officially verified.
        tariff['status'] = 'verified';

        // Save the tariff to the temporary directory.
        await service.saveTariff(tariff);

        // Check that the file was created.
        final savedFile = File(
          '${tempDirectory.path}/domestic_2026_05_11.json',
        );

        expect(await savedFile.exists(), isTrue);

        // Create another service instance to simulate
        // loading previously stored tariff data.
        final offlineService = TariffCacheService(
          cacheDirectory: tempDirectory,
        );

        final cached = await offlineService.loadTariff('domestic_2026_05_11');

        expect(cached, isNotNull);
        expect(cached!['id'], 'domestic_2026_05_11');
        expect(cached['status'], 'verified');
        expect(cached['category'], 'domestic');
        expect(cached['lowConsumption'], isNotNull);
        expect(cached['mediumConsumption'], isNotNull);
        expect(cached['highConsumption'], isNotNull);
      } finally {
        // Remove temporary test files.
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      }
    });
  });
}

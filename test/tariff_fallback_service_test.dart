import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:http/testing.dart';

import 'package:electricity_bill_calculator/services/remote_tariff_service.dart';
import 'package:electricity_bill_calculator/services/tariff_cache_service.dart';
import 'package:electricity_bill_calculator/services/tariff_update_service.dart';
import 'package:electricity_bill_calculator/services/tariff_fallback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TariffFallbackService', () {
    late Directory temporaryDirectory;
    late TariffCacheService cacheService;
    late RemoteTariffService remoteService;
    late TariffFallbackService fallbackService;

    setUp(() async {
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'fallback_test_',
      );

      cacheService = TariffCacheService(cacheDirectory: temporaryDirectory);

      // Simulate an unavailable internet connection.
      final client = MockClient((request) async {
        throw const SocketException('No internet connection');
      });

      remoteService = RemoteTariffService(client: client);

      final updateService = TariffUpdateService(
        remoteService: remoteService,
        cacheService: cacheService,
      );

      fallbackService = TariffFallbackService(
        updateService: updateService,
        cacheService: cacheService,
      );
    });

    tearDown(() async {
      remoteService.dispose();

      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });

    test('Returns cached tariff when internet is unavailable', () async {
      final content = await rootBundle.loadString(
        'assets/tariffs/domestic_2026_05_11.json',
      );

      final tariff = jsonDecode(content) as Map<String, dynamic>;

      // Test fixture only, not an official tariff verification.
      tariff['status'] = 'verified';

      await cacheService.saveTariff(tariff);

      final result = await fallbackService.loadTariff(
        tariffId: 'domestic_2026_05_11',
      );

      expect(result, isNotNull);
      expect(result!['id'], 'domestic_2026_05_11');
      expect(result['status'], 'verified');
    });

    test('Returns null when offline and no cached tariff exists', () async {
      final result = await fallbackService.loadTariff(
        tariffId: 'domestic_2026_05_11',
      );

      expect(result, isNull);
    });
  });
}

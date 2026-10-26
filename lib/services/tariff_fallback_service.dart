import 'dart:async';
import 'dart:io';

import 'tariff_cache_service.dart';
import 'tariff_update_service.dart';

class TariffFallbackService {
  TariffFallbackService({
    required this.updateService,
    required this.cacheService,
  });

  final TariffUpdateService updateService;
  final TariffCacheService cacheService;

  Future<Map<String, dynamic>?> loadTariff({required String tariffId}) async {
    try {
      // Attempt to download newly published tariffs.
      await updateService.checkForUpdates();
    } on SocketException {
      // Internet unavailable: try local cache.
    } on TimeoutException {
      // Network timeout: try local cache.
    } on HttpException {
      // HTTP failure: try local cache.
    }

    // Use a previously cached verified tariff.
    return cacheService.loadTariff(tariffId);
  }
}

// ignore_for_file: prefer_initializing_formals

import 'remote_tariff_service.dart';
import 'tariff_cache_service.dart';
import 'tariff_manifest_cache_service.dart';
import 'tariff_manifest_validator.dart';
import 'tariff_validator.dart';

class TariffUpdateService {
  TariffUpdateService({
    required RemoteTariffService remoteService,
    required TariffCacheService cacheService,
    TariffManifestCacheService? manifestCacheService,
  }) : _remoteService = remoteService,
       _cacheService = cacheService,
       _manifestCacheService = manifestCacheService;

  final RemoteTariffService _remoteService;
  final TariffCacheService _cacheService;
  final TariffManifestCacheService? _manifestCacheService;

  Future<int> checkForUpdates() async {
    // PHASE 1:
    // Download and validate the remote manifest.
    final manifest = await _remoteService.fetchManifest();

    final rawEntries = manifest['tariffs'];

    if (rawEntries is! List) {
      throw const FormatException('Invalid tariff manifest.');
    }

    final entries = <Map<String, dynamic>>[];

    for (final entry in rawEntries) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid tariff manifest entry.');
      }

      entries.add(entry);
    }

    // Validate the entire manifest before downloading tariffs.
    TariffManifestValidator.validate(entries);

    // PHASE 2:
    // Download and validate missing verified tariffs.
    //
    // Keep downloaded tariffs in memory until all
    // downloads and validations have succeeded.
    final pendingTariffs = <Map<String, dynamic>>[];

    for (final entry in entries) {
      // Never download provisional tariffs.
      if (entry['status'] != 'verified') {
        continue;
      }

      final id = entry['id'] as String;
      final effectiveDate = entry['effectiveDate'] as String;

      // Check whether the tariff is already cached.
      final cached = await _cacheService.loadTariff(id);

      if (cached != null) {
        // Ensure cached metadata matches the manifest.
        if (cached['id'] != id ||
            cached['effectiveDate'] != effectiveDate ||
            cached['status'] != 'verified') {
          throw const FormatException(
            'Cached tariff does not match the manifest.',
          );
        }

        // The verified tariff is already cached.
        continue;
      }

      // Download the missing verified tariff.
      final tariff = await _remoteService.fetchTariff(id);

      // Ensure downloaded metadata matches the manifest.
      if (tariff['id'] != id ||
          tariff['effectiveDate'] != effectiveDate ||
          tariff['status'] != 'verified') {
        throw const FormatException(
          'Downloaded tariff does not match the manifest.',
        );
      }

      // Validate the complete tariff structure.
      TariffValidator.validate(tariff);

      // Stage the tariff in memory.
      pendingTariffs.add(tariff);
    }

    // PHASE 3:
    // Save verified tariffs only after all downloads
    // and validations have succeeded.
    for (final tariff in pendingTariffs) {
      await _cacheService.saveTariff(tariff);
    }

    // PHASE 4:
    // Activate the new manifest only after all required
    // verified tariff files have been saved.
    //
    // The optional dependency maintains compatibility
    // with existing service tests and callers.
    if (_manifestCacheService != null) {
      await _manifestCacheService.saveManifest(manifest);
    }

    // Return the number of newly cached tariffs.
    return pendingTariffs.length;
  }
}

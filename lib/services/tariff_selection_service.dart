import 'tariff_cache_service.dart';

class TariffSelectionService {
  TariffSelectionService({required this.cacheService});

  final TariffCacheService cacheService;

  // Convert a YYYY-MM-DD string into a UTC calendar date.
  DateTime _parseTariffDate(String value) {
    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

    if (!datePattern.hasMatch(value)) {
      throw const FormatException('Invalid tariff date format.');
    }

    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      throw const FormatException('Invalid tariff date.');
    }

    final date = DateTime.utc(parsed.year, parsed.month, parsed.day);

    // Reject invalid calendar dates.
    if (date.year != int.parse(value.substring(0, 4)) ||
        date.month != int.parse(value.substring(5, 7)) ||
        date.day != int.parse(value.substring(8, 10))) {
      throw const FormatException('Invalid tariff calendar date.');
    }

    return date;
  }

  Future<Map<String, dynamic>?> selectTariff({
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> tariffEntries,
  }) async {
    // Normalize billing dates to UTC calendar dates.
    final start = DateTime.utc(startDate.year, startDate.month, startDate.day);

    final end = DateTime.utc(endDate.year, endDate.month, endDate.day);

    // Validate the billing period.
    if (!end.isAfter(start)) {
      throw ArgumentError('Billing end date must be after the start date.');
    }

    final eligibleEntries = <Map<String, dynamic>>[];

    // Examine each tariff version.
    for (final entry in tariffEntries) {
      // Never select provisional tariff entries.
      if (entry['status'] != 'verified') {
        continue;
      }

      final id = entry['id'];
      final effectiveDateText = entry['effectiveDate'];
      final endDateText = entry['endDateExclusive'];

      // Validate required metadata.
      if (id is! String || effectiveDateText is! String) {
        throw const FormatException('Invalid tariff manifest entry.');
      }

      // Parse the tariff effective date.
      final effectiveDate = _parseTariffDate(effectiveDateText);

      DateTime? tariffEndDate;

      // Parse the optional tariff expiry date.
      if (endDateText != null) {
        if (endDateText is! String) {
          throw const FormatException('Invalid tariff end date.');
        }

        tariffEndDate = _parseTariffDate(endDateText);

        if (!tariffEndDate.isAfter(effectiveDate)) {
          throw const FormatException(
            'Tariff end date must be after its effective date.',
          );
        }
      }

      // Billing period: [start, end)
      // Tariff period: [effectiveDate, tariffEndDate)
      //
      // The tariff must cover the entire billing period.
      final coversStart = !start.isBefore(effectiveDate);

      final coversEnd = tariffEndDate == null || !end.isAfter(tariffEndDate);

      if (coversStart && coversEnd) {
        eligibleEntries.add(entry);
      }
    }

    // No matching verified tariff was found.
    if (eligibleEntries.isEmpty) {
      return null;
    }

    // Reject conflicting tariff versions.
    if (eligibleEntries.length > 1) {
      throw const FormatException('Overlapping tariff periods detected.');
    }

    // Exactly one eligible tariff remains.
    final selected = eligibleEntries.single;
    final tariffId = selected['id'] as String;

    // Load the selected tariff from offline storage.
    final cachedTariff = await cacheService.loadTariff(tariffId);

    // Never substitute another tariff if the correct
    // version is missing from the cache.
    if (cachedTariff == null) {
      return null;
    }

    // Verify cached metadata against the manifest entry.
    if (cachedTariff['id'] != tariffId ||
        cachedTariff['effectiveDate'] != selected['effectiveDate'] ||
        cachedTariff['status'] != 'verified') {
      throw const FormatException(
        'Cached tariff metadata does not match the manifest.',
      );
    }

    return cachedTariff;
  }
}

import 'dart:convert';

import 'package:flutter/services.dart';

class TariffRepository {
  final AssetBundle assetBundle;

  TariffRepository({AssetBundle? assetBundle})
    : assetBundle = assetBundle ?? rootBundle;

  Future<Map<String, dynamic>> loadManifest() async {
    final content = await assetBundle.loadString(
      'assets/tariffs/tariff_manifest.json',
    );

    final decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid tariff manifest format.');
    }

    if (decoded['schemaVersion'] != 1 || decoded['tariffs'] is! List) {
      throw const FormatException('Unsupported tariff manifest schema.');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> loadTariff({
    required DateTime billingDate,
  }) async {
    final manifest = await loadManifest();

    final tariffs = manifest['tariffs'] as List;

    final date = DateTime.utc(
      billingDate.year,
      billingDate.month,
      billingDate.day,
    );

    Map<String, dynamic>? selected;
    DateTime? selectedEffectiveDate;

    for (final entry in tariffs) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid tariff manifest entry.');
      }

      final effectiveText = entry['effectiveDate'];
      final endText = entry['endDateExclusive'];

      if (effectiveText is! String || (endText != null && endText is! String)) {
        throw const FormatException('Invalid tariff date configuration.');
      }

      DateTime parseDate(String value) {
        final parsed = DateTime.tryParse(value);

        if (parsed == null ||
            !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
            parsed.toIso8601String().substring(0, 10) != value) {
          throw const FormatException('Invalid tariff date.');
        }

        return DateTime.utc(parsed.year, parsed.month, parsed.day);
      }

      final effective = parseDate(effectiveText);

      final end = endText == null ? null : parseDate(endText);

      if (end != null && !end.isAfter(effective)) {
        throw const FormatException(
          'Tariff end date must follow effective date.',
        );
      }

      final isActive =
          !date.isBefore(effective) && (end == null || date.isBefore(end));

      if (isActive &&
          (selectedEffectiveDate == null ||
              effective.isAfter(selectedEffectiveDate))) {
        selected = entry;
        selectedEffectiveDate = effective;
      }
    }

    if (selected == null) {
      throw StateError(
        'No tariff schedule is available for the selected date.',
      );
    }

    // Never treat an unverified schedule as officially approved.
    if (selected['status'] != 'verified') {
      throw StateError(
        'The selected tariff schedule is provisional '
        'and cannot be used for official bill estimates.',
      );
    }

    final assetPath = selected['assetPath'];

    if (assetPath is! String ||
        !RegExp(r'^assets/tariffs/[a-zA-Z0-9_-]+\.json$').hasMatch(assetPath)) {
      throw const FormatException('Invalid tariff asset path.');
    }

    final content = await assetBundle.loadString(assetPath);
    final decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid tariff data format.');
    }

    if (decoded['id'] != selected['id'] ||
        decoded['effectiveDate'] != selected['effectiveDate'] ||
        decoded['status'] != 'verified' ||
        decoded['referenceDays'] != 30 ||
        decoded['category'] != 'domestic') {
      throw const FormatException(
        'Tariff metadata does not match the manifest.',
      );
    }

    return decoded;
  }
}

class TariffManifestValidator {
  static void validate(List<Map<String, dynamic>> entries) {
    final ids = <String>{};
    final verifiedPeriods = <_TariffPeriod>[];

    for (final entry in entries) {
      final id = entry['id'];
      final status = entry['status'];
      final effectiveDateText = entry['effectiveDate'];
      final endDateText = entry['endDateExclusive'];

      if (id is! String || id.trim().isEmpty) {
        throw const FormatException('Invalid tariff ID.');
      }

      if (!ids.add(id)) {
        throw FormatException('Duplicate tariff ID: $id');
      }

      if (status != 'verified' && status != 'provisional') {
        throw FormatException('Invalid tariff status for $id.');
      }

      if (effectiveDateText is! String) {
        throw FormatException('Missing effective date for $id.');
      }

      final start = _parseDate(effectiveDateText);

      DateTime? end;

      if (endDateText != null) {
        if (endDateText is! String) {
          throw FormatException('Invalid end date for $id.');
        }

        end = _parseDate(endDateText);

        if (!end.isAfter(start)) {
          throw FormatException(
            'Tariff end date must be after effective date: $id',
          );
        }
      }

      // Only verified tariffs are eligible for calculations.
      if (status == 'verified') {
        verifiedPeriods.add(_TariffPeriod(id: id, start: start, end: end));
      }
    }

    // Check for overlapping verified tariff periods.
    verifiedPeriods.sort((a, b) => a.start.compareTo(b.start));

    for (var i = 1; i < verifiedPeriods.length; i++) {
      final previous = verifiedPeriods[i - 1];
      final current = verifiedPeriods[i];

      if (previous.end == null || current.start.isBefore(previous.end!)) {
        throw FormatException(
          'Overlapping verified tariff periods: '
          '${previous.id} and ${current.id}',
        );
      }
    }
  }

  static DateTime _parseDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw FormatException('Invalid date format: $value');
    }

    final year = int.parse(value.substring(0, 4));
    final month = int.parse(value.substring(5, 7));
    final day = int.parse(value.substring(8, 10));

    final date = DateTime.utc(year, month, day);

    if (date.year != year || date.month != month || date.day != day) {
      throw FormatException('Invalid calendar date: $value');
    }

    return date;
  }
}

class _TariffPeriod {
  const _TariffPeriod({
    required this.id,
    required this.start,
    required this.end,
  });

  final String id;
  final DateTime start;
  final DateTime? end;
}

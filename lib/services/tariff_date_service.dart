class TariffDateService {
  static final DateTime may2026EffectiveDate = DateTime(2026, 5, 11);

  static bool isSupportedPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime.utc(startDate.year, startDate.month, startDate.day);

    final end = DateTime.utc(endDate.year, endDate.month, endDate.day);

    final effective = DateTime.utc(2026, 5, 11);

    return !start.isBefore(effective) && end.isAfter(start);
  }

  static void validatePeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (!isSupportedPeriod(startDate: startDate, endDate: endDate)) {
      throw ArgumentError(
        'The selected billing period is not supported '
        'by the configured tariff schedule.',
      );
    }
  }
}

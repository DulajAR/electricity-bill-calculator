class BillingPeriodService {
  static int billingDays(DateTime start, DateTime end) {
    final startUtc = DateTime.utc(start.year, start.month, start.day);

    final endUtc = DateTime.utc(end.year, end.month, end.day);

    final days = endUtc.difference(startUtc).inDays;

    if (days <= 0) {
      throw ArgumentError('Billing end date must be after start date.');
    }

    return days;
  }

  static double proratedThreshold(int monthlyThreshold, int days) {
    if (monthlyThreshold < 0 || days <= 0) {
      throw ArgumentError('Invalid threshold or billing days.');
    }

    return monthlyThreshold * days / 30.0;
  }

  static double monthlyEquivalentUnits(int consumedUnits, int days) {
    if (consumedUnits < 0 || days <= 0) {
      throw ArgumentError('Invalid units or billing days.');
    }

    return consumedUnits * 30.0 / days;
  }
}

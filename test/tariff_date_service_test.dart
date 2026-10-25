import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_bill_calculator/services/tariff_date_service.dart';

void main() {
  group('Tariff date validation', () {
    test('Accepts a period after May 11, 2026', () {
      expect(
        TariffDateService.isSupportedPeriod(
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 7, 1),
        ),
        isTrue,
      );
    });

    test('Accepts a period starting on May 11', () {
      expect(
        TariffDateService.isSupportedPeriod(
          startDate: DateTime(2026, 5, 11),
          endDate: DateTime(2026, 6, 10),
        ),
        isTrue,
      );
    });

    test('Rejects a period before May 11', () {
      expect(
        TariffDateService.isSupportedPeriod(
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 31),
        ),
        isFalse,
      );
    });

    test('Rejects reversed dates', () {
      expect(
        () => TariffDateService.validatePeriod(
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 6, 1),
        ),
        throwsArgumentError,
      );
    });
  });
}

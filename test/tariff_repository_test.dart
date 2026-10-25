import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_bill_calculator/services/tariff_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TariffRepository repository;

  setUp(() {
    repository = TariffRepository();
  });

  group('Tariff Repository Tests', () {
    test('Loads the tariff manifest successfully', () async {
      final manifest = await repository.loadManifest();

      expect(manifest['schemaVersion'], 1);
      expect(manifest['category'], 'domestic');
      expect(manifest['tariffs'], isA<List>());
      expect((manifest['tariffs'] as List), isNotEmpty);
    });

    test('Manifest contains the provisional tariff', () async {
      final manifest = await repository.loadManifest();

      final tariffs = manifest['tariffs'] as List;
      final tariff = tariffs.first as Map<String, dynamic>;

      expect(tariff['id'], 'domestic_2026_05_11');
      expect(tariff['effectiveDate'], '2026-05-11');
      expect(tariff['status'], 'provisional');
      expect(tariff['assetPath'], 'assets/tariffs/domestic_2026_05_11.json');
    });

    test('Rejects provisional tariff for bill estimates', () async {
      await expectLater(
        repository.loadTariff(billingDate: DateTime(2026, 6, 1)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('provisional'),
          ),
        ),
      );
    });

    test('Rejects dates before the configured tariff', () async {
      await expectLater(
        repository.loadTariff(billingDate: DateTime(2026, 4, 1)),
        throwsStateError,
      );
    });

    test('Rejects unsupported historical dates', () async {
      await expectLater(
        repository.loadTariff(billingDate: DateTime(2025, 1, 1)),
        throwsStateError,
      );
    });
  });
}

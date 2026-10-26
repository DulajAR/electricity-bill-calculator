import 'package:flutter_test/flutter_test.dart';
import 'package:electricity_bill_calculator/services/remote_tariff_service.dart';

void main() {
  test('Download tariff manifest from GitHub', () async {
    final service = RemoteTariffService();

    try {
      final manifest = await service.fetchManifest();

      expect(manifest['schemaVersion'], 1);
      expect(manifest['category'], 'domestic');
      expect(manifest['tariffs'], isNotEmpty);
    } finally {
      service.dispose();
    }
  });

  test('Download tariff JSON from GitHub', () async {
    final service = RemoteTariffService();

    try {
      final tariff = await service.fetchTariff('domestic_2026_05_11');

      expect(tariff['id'], 'domestic_2026_05_11');
      expect(tariff['category'], 'domestic');
      expect(tariff['status'], 'provisional');
    } finally {
      service.dispose();
    }
  });
}

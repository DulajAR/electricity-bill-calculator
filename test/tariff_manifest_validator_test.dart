import 'package:flutter_test/flutter_test.dart';

import 'package:electricity_bill_calculator/services/tariff_manifest_validator.dart';

void main() {
  late List<Map<String, dynamic>> entries;

  setUp(() {
    entries = [
      {
        'id': 'domestic_2026_05_11',
        'effectiveDate': '2026-05-11',
        'endDateExclusive': '2026-11-01',
        'status': 'verified',
      },
      {
        'id': 'domestic_2026_11_01',
        'effectiveDate': '2026-11-01',
        'endDateExclusive': null,
        'status': 'verified',
      },
    ];
  });

  test('Accepts valid historical tariff periods', () {
    expect(() => TariffManifestValidator.validate(entries), returnsNormally);
  });

  test('Rejects duplicate tariff IDs', () {
    entries[1]['id'] = entries[0]['id'];

    expect(
      () => TariffManifestValidator.validate(entries),
      throwsFormatException,
    );
  });

  test('Rejects overlapping verified tariff periods', () {
    entries[1]['effectiveDate'] = '2026-10-01';

    expect(
      () => TariffManifestValidator.validate(entries),
      throwsFormatException,
    );
  });

  test('Rejects invalid calendar dates', () {
    entries[0]['effectiveDate'] = '2026-02-30';

    expect(
      () => TariffManifestValidator.validate(entries),
      throwsFormatException,
    );
  });

  test('Rejects end dates before effective dates', () {
    entries[0]['endDateExclusive'] = '2026-05-01';

    expect(
      () => TariffManifestValidator.validate(entries),
      throwsFormatException,
    );
  });

  test('Rejects unsupported tariff status', () {
    entries[0]['status'] = 'unknown';

    expect(
      () => TariffManifestValidator.validate(entries),
      throwsFormatException,
    );
  });

  test('Allows provisional tariff entries', () {
    entries[0]['status'] = 'provisional';

    expect(() => TariffManifestValidator.validate(entries), returnsNormally);
  });

  test('Rejects overlapping open-ended verified tariffs', () {
    entries[0]['endDateExclusive'] = null;

    expect(
      () => TariffManifestValidator.validate(entries),
      throwsFormatException,
    );
  });

  test('Allows adjacent tariff periods', () {
    entries[0]['endDateExclusive'] = '2026-11-01';
    entries[1]['effectiveDate'] = '2026-11-01';

    expect(() => TariffManifestValidator.validate(entries), returnsNormally);
  });

  test('Rejects missing effective dates', () {
    entries[0].remove('effectiveDate');

    expect(
      () => TariffManifestValidator.validate(entries),
      throwsFormatException,
    );
  });
}

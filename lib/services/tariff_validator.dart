class TariffValidator {
  static void validate(Map<String, dynamic> tariff) {
    if (tariff['category'] != 'domestic') {
      throw const FormatException('Unsupported tariff category.');
    }

    if (tariff['referenceDays'] != 30) {
      throw const FormatException('Reference billing period must be 30 days.');
    }

    if (tariff['currency'] != 'LKR') {
      throw const FormatException('Unsupported tariff currency.');
    }

    final providers = tariff['provider'];

    if (providers is! List ||
        !providers.contains('CEB') ||
        !providers.contains('LECO')) {
      throw const FormatException('Invalid electricity providers.');
    }

    _validateSection(tariff['lowConsumption'], 'lowConsumption');

    _validateSection(tariff['mediumConsumption'], 'mediumConsumption');

    final high = tariff['highConsumption'];

    if (high is! Map<String, dynamic>) {
      throw const FormatException('Invalid high consumption tariff.');
    }

    if (high['minimumMonthlyUnitsExclusive'] != 180) {
      throw const FormatException('Invalid high consumption threshold.');
    }

    _validateBlocks(high['blocks']);

    final fixedCharge = high['fixedCharge'];

    if (fixedCharge is! num || fixedCharge < 0) {
      throw const FormatException('Invalid high consumption fixed charge.');
    }
  }

  static void _validateSection(dynamic section, String name) {
    if (section is! Map<String, dynamic>) {
      throw FormatException('Invalid $name tariff section.');
    }

    _validateBlocks(section['blocks']);
    _validateFixedCharges(section['fixedCharges']);
  }

  static void _validateBlocks(dynamic blocks) {
    if (blocks is! List || blocks.isEmpty) {
      throw const FormatException('Tariff blocks cannot be empty.');
    }

    num? previousLimit;

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];

      if (block is! Map<String, dynamic>) {
        throw const FormatException('Invalid tariff block.');
      }

      final limit = block['upTo'];
      final rate = block['rate'];

      if (rate is! num || !rate.isFinite || rate < 0) {
        throw const FormatException('Invalid tariff block rate.');
      }

      if (limit == null) {
        if (i != blocks.length - 1) {
          throw const FormatException('Unlimited block must be last.');
        }
      } else {
        if (limit is! num ||
            !limit.isFinite ||
            limit <= 0 ||
            (previousLimit != null && limit <= previousLimit)) {
          throw const FormatException('Tariff block limits must increase.');
        }

        previousLimit = limit;
      }
    }
  }

  static void _validateFixedCharges(dynamic charges) {
    if (charges is! List || charges.isEmpty) {
      throw const FormatException('Fixed charges cannot be empty.');
    }

    num? previousLimit;

    for (final item in charges) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid fixed charge entry.');
      }

      final limit = item['upTo'];
      final amount = item['amount'];

      if (limit is! num ||
          !limit.isFinite ||
          limit <= 0 ||
          (previousLimit != null && limit <= previousLimit)) {
        throw const FormatException('Invalid fixed charge threshold.');
      }

      if (amount is! num || !amount.isFinite || amount < 0) {
        throw const FormatException('Invalid fixed charge amount.');
      }

      previousLimit = limit;
    }
  }
}

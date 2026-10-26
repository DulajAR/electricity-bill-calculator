import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/tariff_cache_service.dart';
import '../services/tariff_manifest_cache_service.dart';
import '../services/tariff_manifest_validator.dart';
import '../services/tariff_selection_service.dart';

class TariffRatesScreen extends StatefulWidget {
  const TariffRatesScreen({super.key});

  @override
  State<TariffRatesScreen> createState() => _TariffRatesScreenState();
}

class _TariffRatesScreenState extends State<TariffRatesScreen> {
  static const Color primaryBlue = Color(0xFF0866D8);
  static const Color background = Color(0xFFF7F9FC);
  static const Color textDark = Color(0xFF14213D);

  String selectedProvider = 'CEB';
  late Future<Map<String, dynamic>> _tariffFuture;

  @override
  void initState() {
    super.initState();
    _tariffFuture = _loadDisplayedTariff();
  }

  Future<Map<String, dynamic>> _loadDisplayedTariff() async {
    // The update service downloads and activates verified tariffs separately.
    // This screen only reads the locally activated manifest and tariff cache.
    try {
      final manifestCache = TariffManifestCacheService();
      final manifest = await manifestCache.loadManifest();
      if (manifest != null && manifest['tariffs'] is List) {
        final entries = <Map<String, dynamic>>[];
        for (final raw in manifest['tariffs'] as List) {
          if (raw is! Map) {
            throw const FormatException('Invalid manifest entry.');
          }
          entries.add(Map<String, dynamic>.from(raw));
        }
        TariffManifestValidator.validate(entries);

        final today = DateTime.now();
        final start = DateTime(today.year, today.month, today.day);
        final end = start.add(const Duration(days: 1));
        final verified = await TariffSelectionService(
          cacheService: TariffCacheService(),
        ).selectTariff(startDate: start, endDate: end, tariffEntries: entries);

        if (verified != null &&
            verified['category'] == 'domestic' &&
            verified['status'] == 'verified' &&
            verified['lowConsumption'] is Map &&
            verified['mediumConsumption'] is Map &&
            verified['highConsumption'] is Map) {
          return verified;
        }
      }
    } catch (_) {
      // A missing or invalid cache must never be shown as verified.
    }
    return _loadBundledTariff();
  }

  Future<Map<String, dynamic>> _loadBundledTariff() async {
    final content = await rootBundle.loadString(
      'assets/tariffs/domestic_2026_05_11.json',
    );
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic> ||
        decoded['category'] != 'domestic' ||
        decoded['status'] != 'provisional' ||
        decoded['lowConsumption'] is! Map ||
        decoded['mediumConsumption'] is! Map ||
        decoded['highConsumption'] is! Map) {
      throw const FormatException('Invalid bundled provisional tariff.');
    }
    return decoded;
  }

  String _money(dynamic amount) {
    if (amount is! num) return 'Unavailable';
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  String _date(dynamic raw) {
    if (raw is! String) return 'Unknown';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rateSection(String title, dynamic rawCategory, {bool high = false}) {
    if (rawCategory is! Map) {
      return const Text('Tariff category data unavailable.');
    }
    final category = Map<String, dynamic>.from(rawCategory);
    final blocks = category['blocks'];
    final fixedCharges = category['fixedCharges'];
    final maximum = category['maximumMonthlyUnits'];
    final minimum = category['minimumMonthlyUnitsExclusive'];

    final rows = <Widget>[];
    if (blocks is List) {
      num previousLimit = 0;
      for (final item in blocks) {
        if (item is! Map) continue;
        final upTo = item['upTo'];
        final rate = item['rate'];
        final range = upTo is num
            ? '${previousLimit.toInt() + 1}–${upTo.toInt()} kWh'
            : 'Above ${previousLimit.toInt()} kWh';
        rows.add(_detail(range, '${_money(rate)} / kWh'));
        if (upTo is num) previousLimit = upTo;
      }
    }

    final fixedRows = <Widget>[];
    if (high) {
      fixedRows.add(_detail('Fixed charge', _money(category['fixedCharge'])));
    } else if (fixedCharges is List) {
      num previousLimit = 0;
      for (final item in fixedCharges) {
        if (item is! Map) continue;
        final upTo = item['upTo'];
        if (upTo is! num) continue;
        fixedRows.add(
          _detail(
            '${previousLimit.toInt() + 1}–${upTo.toInt()} kWh',
            _money(item['amount']),
          ),
        );
        previousLimit = upTo;
      }
    }

    final applicability = high
        ? 'Applies above ${minimum ?? 180} monthly kWh'
        : 'Applies up to ${maximum ?? 'unknown'} monthly kWh';

    return _card(
      title: title,
      icon: Icons.bolt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(applicability, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          const Text(
            'Energy charges',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...rows,
          const Divider(height: 24),
          const Text(
            'Fixed charges',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...fixedRows,
        ],
      ),
    );
  }

  Widget _tariffContent(Map<String, dynamic> tariff) {
    final providers = tariff['provider'];
    final supported = providers is List && providers.contains(selectedProvider);
    if (!supported) {
      return Text('No tariff data available for $selectedProvider.');
    }

    final isVerified = tariff['status'] == 'verified';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isVerified
                ? const Color(0xFFE8F5EE)
                : const Color(0xFFFFF4D8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isVerified
                  ? const Color(0xFF8CCDA9)
                  : const Color(0xFFFFD56B),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isVerified
                    ? Icons.verified_outlined
                    : Icons.warning_amber_outlined,
                color: isVerified
                    ? const Color(0xFF237A4B)
                    : const Color(0xFFB77900),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isVerified
                      ? 'Verified tariff from local cache. Check the source document for official details.'
                      : 'Provisional — Unverified. These rates are for development preview only and are not confirmed official CEB/LECO charges.',
                  style: const TextStyle(fontSize: 13, color: textDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          title: 'Tariff Information',
          icon: Icons.info_outline,
          child: Column(
            children: [
              _detail('Provider', selectedProvider),
              _detail('Category', 'Domestic'),
              _detail('Effective date', _date(tariff['effectiveDate'])),
              _detail(
                'Status',
                isVerified ? 'Verified (cached)' : 'Provisional — Unverified',
              ),
              _detail('Currency', '${tariff['currency'] ?? 'LKR'}'),
              _detail(
                'Reference period',
                '${tariff['referenceDays'] ?? '—'} days',
              ),
              _detail(
                'Source document',
                '${tariff['sourceDocument'] ?? 'Not specified'}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _rateSection('Low Consumption', tariff['lowConsumption']),
        const SizedBox(height: 16),
        _rateSection('Medium Consumption', tariff['mediumConsumption']),
        const SizedBox(height: 16),
        _rateSection('High Consumption', tariff['highConsumption'], high: true),
        const SizedBox(height: 20),
        Text(
          'The ranges shown are based on the tariff JSON reference period. '
          'Actual bill calculations may adjust for the number of billing days. '
          '${isVerified ? 'Source status: verified in the local tariff cache.' : 'These are not verified official rates.'}',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Electricity Tariff Rates'),
        backgroundColor: Colors.white,
        foregroundColor: textDark,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Select Electricity Provider',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'CEB',
                  label: Text('CEB'),
                  icon: Icon(Icons.bolt),
                ),
                ButtonSegment(
                  value: 'LECO',
                  label: Text('LECO'),
                  icon: Icon(Icons.bolt),
                ),
              ],
              selected: {selectedProvider},
              onSelectionChanged: (selection) {
                setState(() => selectedProvider = selection.first);
              },
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<Map<String, dynamic>>(
            future: _tariffFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return _card(
                  title: 'Tariff data unavailable',
                  icon: Icons.error_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Could not load tariff data from the local cache or bundled preview.',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => setState(
                          () => _tariffFuture = _loadDisplayedTariff(),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return _tariffContent(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }
}

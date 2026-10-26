
import 'package:flutter/material.dart';

import '../services/bill_calculator_service.dart';

class BillDetailsScreen extends StatelessWidget {
  final BillResult result;
  final DateTime startDate;
  final DateTime endDate;

  // Indicates whether the calculation used a verified tariff.
  // Defaults to false for compatibility with existing screens and tests.
  final bool isVerifiedTariff;

  const BillDetailsScreen({
    super.key,
    required this.result,
    required this.startDate,
    required this.endDate,
    this.isVerifiedTariff = false,
  });

  static const Color blue = Color(0xFF0866D8);
  static const Color dark = Color(0xFF14213D);

  String money(double amount) {
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  String date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Widget line(
    String title,
    String value, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: emphasize
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: dark,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize
                  ? FontWeight.bold
                  : FontWeight.w600,
              color: emphasize ? blue : dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget panel({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: dark,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget tariffStatusBadge() {
    final Color statusColor = isVerifiedTariff
        ? const Color(0xFF166534)
        : const Color(0xFF92400E);

    final Color statusBackground = isVerifiedTariff
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEF3C7);

    final IconData statusIcon = isVerifiedTariff
        ? Icons.verified_outlined
        : Icons.warning_amber_rounded;

    final String statusText = isVerifiedTariff
        ? 'Verified Tariff'
        : 'Provisional Preview';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: statusBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget informationNotice() {
    final Color backgroundColor = isVerifiedTariff
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFFFF4D8);

    final Color borderColor = isVerifiedTariff
        ? const Color(0xFFBFDBFE)
        : const Color(0xFFFFD56B);

    final Color iconColor = isVerifiedTariff
        ? blue
        : const Color(0xFFB77900);

    final String message = isVerifiedTariff
        ? 'This estimate uses a locally cached tariff marked as verified. '
              'It remains an unofficial electricity bill estimate. '
              'Actual charges may differ due to billing adjustments, '
              'rounding, and other applicable charges. '
              'Always refer to your official electricity bill for payment.'
        : 'Development preview only. The tariff is provisional and '
              'has not been officially verified. Fixed-charge proration, '
              'rounding, tariff changes during billing periods, and '
              'official charges are not yet verified. '
              'Do not use this estimate for payment decisions.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isVerifiedTariff
                ? Icons.info_outline
                : Icons.warning_amber_rounded,
            color: iconColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Bill Details'),
        foregroundColor: Colors.white,
        backgroundColor: blue,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Estimated total card.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF064AAB),
                    Color(0xFF00A2FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 34,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),

                  tariffStatusBadge(),

                  const SizedBox(height: 12),

                  Text(
                    isVerifiedTariff
                        ? 'Estimated electricity bill'
                        : 'Provisional bill estimate',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    money(result.total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Billing information.
            panel(
              title: 'Billing information',
              child: Column(
                children: [
                  line('Provider', result.provider),
                  line(
                    'Consumed units',
                    '${result.units} kWh',
                  ),
                  line(
                    'Billing days',
                    '${result.billingDays}',
                  ),
                  line('Start date', date(startDate)),
                  line('End date', date(endDate)),
                  line(
                    'Tariff effective',
                    result.tariffEffectiveDate,
                  ),
                  line(
                    'Tariff status',
                    isVerifiedTariff
                        ? 'Verified'
                        : 'Provisional',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Charge summary.
            panel(
              title: 'Charge summary',
              child: Column(
                children: [
                  line(
                    'Energy charge',
                    money(result.energyCharge),
                  ),
                  line(
                    'Fixed charge',
                    money(result.fixedCharge),
                  ),
                  const Divider(),
                  line(
                    'Estimated total',
                    money(result.total),
                    emphasize: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Energy charge breakdown.
            panel(
              title: 'Energy charge breakdown',
              child: result.breakdown.isEmpty
                  ? const Text('No energy units charged.')
                  : Column(
                      children: result.breakdown.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 9,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.units.toStringAsFixed(2)} kWh × ${money(item.rate)}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    money(item.amount),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 16),

            // Tariff status and calculation disclaimer.
            informationNotice(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

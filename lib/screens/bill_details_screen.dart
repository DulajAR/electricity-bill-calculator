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

  String money(double amount) {
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  String date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Widget line(
    BuildContext context,
    String title,
    String value, {
    bool emphasize = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
                color: colors.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
              color: emphasize ? colors.primary : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget panel(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget tariffStatusBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color statusColor = isDark
        ? (isVerifiedTariff ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A))
        : (isVerifiedTariff
              ? const Color(0xFF166534)
              : const Color(0xFF92400E));

    final Color statusBackground = isDark
        ? (isVerifiedTariff ? const Color(0xFF14532D) : const Color(0xFF78350F))
        : (isVerifiedTariff
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFFEF3C7));

    final IconData statusIcon = isVerifiedTariff
        ? Icons.verified_outlined
        : Icons.warning_amber_rounded;

    final String statusText = isVerifiedTariff
        ? 'Verified Tariff'
        : 'Provisional Preview';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: statusBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
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

  Widget informationNotice(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final Color backgroundColor = isDark
        ? (isVerifiedTariff ? const Color(0xFF142D4E) : const Color(0xFF3D2D13))
        : (isVerifiedTariff
              ? const Color(0xFFEFF6FF)
              : const Color(0xFFFFF4D8));

    final Color borderColor = isDark
        ? (isVerifiedTariff ? const Color(0xFF426A9C) : const Color(0xFF8A671F))
        : (isVerifiedTariff
              ? const Color(0xFFBFDBFE)
              : const Color(0xFFFFD56B));

    final Color iconColor = isVerifiedTariff
        ? (isDark ? const Color(0xFF93C5FD) : blue)
        : (isDark ? const Color(0xFFFDE68A) : const Color(0xFFB77900));

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
            isVerifiedTariff ? Icons.info_outline : Icons.warning_amber_rounded,
            color: iconColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
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
                  colors: [Color(0xFF064AAB), Color(0xFF00A2FF)],
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

                  tariffStatusBadge(context),

                  const SizedBox(height: 12),

                  Text(
                    isVerifiedTariff
                        ? 'Estimated electricity bill'
                        : 'Provisional bill estimate',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
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
              context,
              title: 'Billing information',
              child: Column(
                children: [
                  line(context, 'Provider', result.provider),
                  line(context, 'Consumed units', '${result.units} kWh'),
                  line(context, 'Billing days', '${result.billingDays}'),
                  line(context, 'Start date', date(startDate)),
                  line(context, 'End date', date(endDate)),
                  line(context, 'Tariff effective', result.tariffEffectiveDate),
                  line(
                    context,
                    'Tariff status',
                    isVerifiedTariff ? 'Verified' : 'Provisional',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Charge summary.
            panel(
              context,
              title: 'Charge summary',
              child: Column(
                children: [
                  line(context, 'Energy charge', money(result.energyCharge)),
                  line(context, 'Fixed charge', money(result.fixedCharge)),
                  const Divider(),
                  line(
                    context,
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
              context,
              title: 'Energy charge breakdown',
              child: result.breakdown.isEmpty
                  ? const Text('No energy units charged.')
                  : Column(
                      children: result.breakdown.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Text(money(item.amount)),
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
            informationNotice(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/bill_calculator_service.dart';

class BillDetailsScreen extends StatelessWidget {
  final BillResult result;
  final DateTime startDate;
  final DateTime endDate;

  const BillDetailsScreen({
    super.key,
    required this.result,
    required this.startDate,
    required this.endDate,
  });

  static const blue = Color(0xFF0866D8);
  static const dark = Color(0xFF14213D);

  String money(double amount) => 'Rs. ${amount.toStringAsFixed(2)}';

  String date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';

  Widget line(String title, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
                color: dark,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
              color: emphasize ? blue : dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget panel({required String title, required Widget child}) {
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
            Container(
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
                  const SizedBox(height: 10),
                  const Text(
                    'Provisional bill estimate',
                    style: TextStyle(color: Colors.white, fontSize: 14),
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
            panel(
              title: 'Billing information',
              child: Column(
                children: [
                  line('Provider', result.provider),
                  line('Consumed units', '${result.units} kWh'),
                  line('Billing days', '${result.billingDays}'),
                  line('Start date', date(startDate)),
                  line('End date', date(endDate)),
                  line('Tariff effective', result.tariffEffectiveDate),
                ],
              ),
            ),
            const SizedBox(height: 16),
            panel(
              title: 'Charge summary',
              child: Column(
                children: [
                  line('Energy charge', money(result.energyCharge)),
                  line('Fixed charge', money(result.fixedCharge)),
                  const Divider(),
                  line('Estimated total', money(result.total), emphasize: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            panel(
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
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4D8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD56B)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFB77900)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Development preview only. The tariff is provisional. '
                      'Fixed-charge proration, rounding, tariff changes during '
                      'billing periods, and official charges are not yet verified. '
                      'Do not use this estimate for payment decisions.',
                      style: TextStyle(fontSize: 12, color: dark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String provider = 'CEB';
  bool useMeterReadings = true;

  final previousController = TextEditingController();
  final currentController = TextEditingController();
  final unitsController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  static const primaryBlue = Color(0xFF0866D8);

  @override
  void dispose() {
    previousController.dispose();
    currentController.dispose();
    unitsController.dispose();
    super.dispose();
  }

  int? get consumedUnits {
    if (!useMeterReadings) {
      return int.tryParse(unitsController.text);
    }

    final previous = int.tryParse(previousController.text);
    final current = int.tryParse(currentController.text);

    if (previous == null || current == null || current < previous) {
      return null;
    }

    return current - previous;
  }

  Future<void> selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          startDate = date;
        } else {
          endDate = date;
        }
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Select date';

    return '${date.day}/${date.month}/${date.year}';
  }

  void calculateBill() {
    final units = consumedUnits;

    if (units == null || units < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid electricity readings or units.'),
        ),
      );
      return;
    }

    if (startDate == null ||
        endDate == null ||
        !endDate!.isAfter(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid billing period.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$provider • $units kWh • Input validated successfully',
        ),
      ),
    );

    // Next: connect the verified tariff calculation service.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'Electricity Bill Calculator',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Calculate your estimated electricity bill',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Select electricity provider',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              providerCard('CEB'),
              const SizedBox(width: 12),
              providerCard('LECO'),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Consumption entry method',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Meter Readings'),
              ),
              ButtonSegment(
                value: false,
                label: Text('Total Units'),
              ),
            ],
            selected: {useMeterReadings},
            onSelectionChanged: (selection) {
              setState(() {
                useMeterReadings = selection.first;
              });
            },
          ),

          const SizedBox(height: 20),

          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    useMeterReadings
                        ? 'Enter Meter Readings'
                        : 'Enter Total Units',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (useMeterReadings) ...[
                    inputField(
                      'Previous Meter Reading',
                      previousController,
                    ),
                    const SizedBox(height: 12),
                    inputField(
                      'Current Meter Reading',
                      currentController,
                    ),
                  ] else
                    inputField(
                      'Consumed Units (kWh)',
                      unitsController,
                    ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F1FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Units Consumed: ${consumedUnits?.toString() ?? '--'} kWh',
                      style: const TextStyle(
                        color: primaryBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Billing Period',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  dateButton('Start Date', startDate, true),
                  const SizedBox(height: 8),
                  dateButton('End Date', endDate, false),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: calculateBill,
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate Bill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Unofficial electricity bill estimator. '
            'Actual charges may vary based on applicable tariffs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget providerCard(String name) {
    final selected = provider == name;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => provider = name),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFE7F1FF)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? primaryBlue : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.electric_bolt, color: primaryBlue),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget inputField(
    String label,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget dateButton(
    String label,
    DateTime? date,
    bool isStart,
  ) {
    return OutlinedButton.icon(
      onPressed: () => selectDate(isStart),
      icon: const Icon(Icons.calendar_month),
      label: Text('$label: ${formatDate(date)}'),
    );
  }
}

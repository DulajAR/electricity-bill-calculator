import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/bill_calculator_service.dart';
import 'bill_details_screen.dart';
import '../widgets/gradient_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryBlue = Color(0xFF0866D8);
  static const Color background = Color(0xFFF7F9FC);
  static const Color textDark = Color(0xFF14213D);

  String provider = 'CEB';
  bool useMeterReadings = true;
  int selectedNavigationIndex = 0;
  bool isCalculating = false;
  BillResult? lastResult;
  DateTime? lastStartDate;
  DateTime? lastEndDate;

  final previousController = TextEditingController();
  final currentController = TextEditingController();
  final unitsController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

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

  String formatDate(DateTime? date) {
    if (date == null) return 'Select date';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> selectDate(bool isStart) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (startDate ?? now)
          : (endDate ?? startDate?.add(const Duration(days: 30)) ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isStart
          ? 'Select billing start date'
          : 'Select billing end date',
    );

    if (!mounted || date == null) return;

    setState(() {
      if (isStart) {
        startDate = date;
      } else {
        endDate = date;
      }
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> calculateBill() async {
    if (isCalculating) return;

    final units = consumedUnits;
    if (units == null || units < 0) {
      showMessage('Please enter valid electricity readings or units.');
      return;
    }

    final start = startDate;
    final end = endDate;
    if (start == null || end == null || !end.isAfter(start)) {
      showMessage('Please select a valid billing period.');
      return;
    }

    setState(() => isCalculating = true);
    try {
      // Development preview ONLY: bypasses the verified-only repository.
      // Do not use this path for production or official bill estimates.
      final content = await rootBundle.loadString(
        'assets/tariffs/domestic_2026_05_11.json',
      );
      final tariff = jsonDecode(content) as Map<String, dynamic>;
      if (tariff['status'] != 'provisional') {
        throw StateError('Development preview expects a provisional tariff.');
      }

      final result = BillCalculatorService.calculateWithTariff(
        units: units,
        provider: provider,
        startDate: start,
        endDate: end,
        tariff: tariff,
      );

      if (!mounted) return;
      setState(() {
        lastResult = result;
        lastStartDate = start;
        lastEndDate = end;
      });
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              BillDetailsScreen(result: result, startDate: start, endDate: end),
        ),
      );
    } on FormatException catch (error) {
      if (mounted) showMessage('Invalid tariff data: ${error.message}');
    } on ArgumentError catch (error) {
      if (mounted)
        showMessage(error.message?.toString() ?? 'Invalid billing input.');
    } on StateError catch (error) {
      if (mounted) showMessage(error.message);
    } catch (_) {
      if (mounted) showMessage('Unable to calculate the preview bill.');
    } finally {
      if (mounted) setState(() => isCalculating = false);
    }
  }

  void onNavigationSelected(int index) {
    if (index == 0) {
      setState(() => selectedNavigationIndex = 0);
      return;
    }

    if (index == 1) {
      final result = lastResult;
      final start = lastStartDate;
      final end = lastEndDate;
      if (result == null || start == null || end == null) {
        showMessage('Calculate a bill first to view its details.');
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              BillDetailsScreen(result: result, startDate: start, endDate: end),
        ),
      );
      return;
    }

    const pages = ['Calculator', 'Bill Details', 'Tariff Rates', 'Settings'];
    showMessage('${pages[index]} screen will be implemented next.');
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      ),
    );
  }

  Widget providerCard(String name) {
    final selected = provider == name;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => provider = name),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE7F1FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primaryBlue : const Color(0xFFE1E8F0),
              width: selected ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.electric_bolt, color: primaryBlue, size: 30),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? primaryBlue : Colors.grey,
                    size: 21,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name == 'CEB'
                    ? 'Ceylon Electricity Board'
                    : 'Lanka Electricity Company',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.speed_outlined, color: primaryBlue),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
    );
  }

  Widget dateButton(String label, DateTime? date, bool isStart) {
    return InkWell(
      onTap: () => selectDate(isStart),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: primaryBlue,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatDate(date),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget contentCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const GradientHeader(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionTitle('Select electricity provider'),

                  Row(
                    children: [
                      providerCard('CEB'),
                      const SizedBox(width: 12),
                      providerCard('LECO'),
                    ],
                  ),

                  const SizedBox(height: 26),

                  sectionTitle('Consumption entry method'),

                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.speed_outlined),
                          label: Text('Meter Readings'),
                        ),
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.bolt_outlined),
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
                  ),

                  const SizedBox(height: 22),

                  contentCard(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          useMeterReadings
                              ? 'Enter Meter Readings'
                              : 'Enter Total Units',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),

                        const SizedBox(height: 18),

                        if (useMeterReadings)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 330) {
                                return Column(
                                  children: [
                                    inputField(
                                      'Previous Reading',
                                      previousController,
                                      hint: 'e.g. 12500',
                                    ),
                                    const SizedBox(height: 12),
                                    inputField(
                                      'Current Reading',
                                      currentController,
                                      hint: 'e.g. 12850',
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: inputField(
                                      'Previous Reading',
                                      previousController,
                                      hint: '12500',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: inputField(
                                      'Current Reading',
                                      currentController,
                                      hint: '12850',
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        else
                          inputField(
                            'Total Units (kWh)',
                            unitsController,
                            hint: 'Enter consumed units',
                          ),

                        const SizedBox(height: 18),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F1FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt,
                                color: primaryBlue,
                                size: 30,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Units Consumed',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${consumedUnits?.toString() ?? '--'} kWh',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  contentCard(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Billing Period',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: dateButton('Start Date', startDate, true),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: dateButton('End Date', endDate, false),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF064AAB), Color(0xFF00A2FF)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: isCalculating ? null : calculateBill,
                        icon: isCalculating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.calculate_outlined),
                        label: Text(
                          isCalculating ? 'Calculating...' : 'Calculate Bill',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
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
                            'This is an unofficial electricity bill estimator. '
                            'Actual charges may vary based on applicable '
                            'tariffs and adjustments.',
                            style: TextStyle(fontSize: 12, color: textDark),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedNavigationIndex,
        onDestinationSelected: onNavigationSelected,
        indicatorColor: const Color(0xFFE7F1FF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: primaryBlue),
            label: 'Calculator',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Bill Details',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Tariff Rates',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

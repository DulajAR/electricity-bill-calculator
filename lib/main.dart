
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ElectricityBillApp());
}

class ElectricityBillApp extends StatelessWidget {
  const ElectricityBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electricity Bill Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0866D8),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

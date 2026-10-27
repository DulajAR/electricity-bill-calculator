import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_settings_service.dart';
import 'services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = ThemeController(AppSettingsService());

  try {
    await themeController.loadTheme();
  } catch (_) {
    // Use system theme if saved preferences cannot load.
  }

  runApp(ElectricityBillApp(themeController: themeController));
}

class ElectricityBillApp extends StatefulWidget {
  const ElectricityBillApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<ElectricityBillApp> createState() => _ElectricityBillAppState();
}

class _ElectricityBillAppState extends State<ElectricityBillApp> {
  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: widget.themeController,
      child: ListenableBuilder(
        listenable: widget.themeController,
        builder: (context, child) {
          return MaterialApp(
            title: 'Electricity Bill Calculator',
            debugShowCheckedModeBanner: false,
            themeMode: widget.themeController.themeMode,

            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0866D8),
                brightness: Brightness.light,
              ),
            ),

            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0866D8),
                brightness: Brightness.dark,
              ),
            ),

            home: child,
          );
        },
        child: const HomeScreen(),
      ),
    );
  }
}

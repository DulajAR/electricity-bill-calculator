import 'package:flutter/material.dart';

import 'app_settings_service.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._settingsService);

  final AppSettingsService _settingsService;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    _themeMode = await _settingsService.getThemeMode();
    notifyListeners();
  }

  Future<void> changeTheme(ThemeMode mode) async {
    await _settingsService.setThemeMode(mode);
    _themeMode = mode;
    notifyListeners();
  }
}

// Makes the same controller available to all screens.
class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>();

    assert(scope != null, 'ThemeControllerScope not found.');

    return scope!.notifier!;
  }
}

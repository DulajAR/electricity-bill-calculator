import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const String _providerKey = 'default_electricity_provider';
  static const String _themeKey = 'app_theme_mode';
  static const String _automaticTariffUpdatesKey = 'automatic_tariff_updates';

  static const String defaultProvider = 'CEB';
  static const bool defaultAutomaticTariffUpdates = true;

  Future<String> getDefaultProvider() async {
    final preferences = await SharedPreferences.getInstance();
    final provider = preferences.getString(_providerKey);
    if (provider == 'CEB' || provider == 'LECO') return provider!;
    return defaultProvider;
  }

  Future<void> setDefaultProvider(String provider) async {
    if (provider != 'CEB' && provider != 'LECO') {
      throw ArgumentError.value(provider, 'provider', 'Provider must be CEB or LECO.');
    }
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_providerKey, provider);
    if (!saved) throw StateError('Unable to save provider preference.');
  }

  Future<ThemeMode> getThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final storedMode = preferences.getString(_themeKey);
    switch (storedMode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_themeKey, mode.name);
    if (!saved) throw StateError('Unable to save theme preference.');
  }

  Future<bool> getAutomaticTariffUpdates() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_automaticTariffUpdatesKey) ??
        defaultAutomaticTariffUpdates;
  }

  Future<void> setAutomaticTariffUpdates(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_automaticTariffUpdatesKey, enabled);
    if (!saved) throw StateError('Unable to save automatic tariff update preference.');
  }
}

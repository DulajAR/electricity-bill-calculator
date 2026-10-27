import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';
import '../services/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color primaryBlue = Color(0xFF0866D8);

  final AppSettingsService _settingsService = AppSettingsService();

  String _selectedProvider = AppSettingsService.defaultProvider;

  bool _isLoading = true;
  bool _isSavingProvider = false;
  bool _isSavingTheme = false;
  bool _automaticTariffUpdates = AppSettingsService.defaultAutomaticTariffUpdates;
  bool _isSavingAutomaticUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final provider = await _settingsService.getDefaultProvider();
      final automaticUpdates = await _settingsService.getAutomaticTariffUpdates();

      if (!mounted) return;

      setState(() {
        _selectedProvider = provider;
        _automaticTariffUpdates = automaticUpdates;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load saved settings.');
    }
  }

  Future<void> _saveProvider(String provider) async {
    if (_isSavingProvider || provider == _selectedProvider) {
      return;
    }

    setState(() {
      _isSavingProvider = true;
    });

    try {
      await _settingsService.setDefaultProvider(provider);

      if (!mounted) return;

      setState(() {
        _selectedProvider = provider;
      });

      _showMessage('Default provider updated to $provider.');
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to save provider preference.');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProvider = false;
        });
      }
    }
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    final controller = ThemeControllerScope.of(context);

    if (_isSavingTheme || mode == controller.themeMode) {
      return;
    }

    setState(() {
      _isSavingTheme = true;
    });

    try {
      await controller.changeTheme(mode);

      if (!mounted) return;

      _showMessage('Appearance preference saved.');
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to save appearance preference.');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingTheme = false;
        });
      }
    }
  }

  Future<void> _saveAutomaticTariffUpdates(bool enabled) async {
    if (_isSavingAutomaticUpdates || enabled == _automaticTariffUpdates) return;
    setState(() => _isSavingAutomaticUpdates = true);
    try {
      await _settingsService.setAutomaticTariffUpdates(enabled);
      if (!mounted) return;
      setState(() => _automaticTariffUpdates = enabled);
      _showMessage(enabled
          ? 'Automatic tariff checks enabled.'
          : 'Automatic tariff checks disabled. Manual checks remain available.');
    } catch (_) {
      if (mounted) _showMessage('Unable to save automatic update preference.');
    } finally {
      if (mounted) setState(() => _isSavingAutomaticUpdates = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: primaryBlue,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _settingsCard(Widget child) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: child,
      ),
    );
  }

  Widget _providerOption(String provider, String description) {
    return RadioListTile<String>(
      title: Text(
        provider,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(description),
      value: provider,
      activeColor: primaryBlue,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _providerSettings() {
    return _settingsCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.electric_bolt, color: primaryBlue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Default Electricity Provider',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Choose the provider selected by default '
            'on the Calculator screen.',
            style: TextStyle(fontSize: 12),
          ),

          const SizedBox(height: 12),

          RadioGroup<String>(
            groupValue: _selectedProvider,
            onChanged: (value) {
              if (!_isSavingProvider && value != null) {
                _saveProvider(value);
              }
            },
            child: Column(
              children: [
                _providerOption('CEB', 'Ceylon Electricity Board'),
                _providerOption('LECO', 'Lanka Electricity Company'),
              ],
            ),
          ),

          if (_isSavingProvider)
            const LinearProgressIndicator(color: primaryBlue),
        ],
      ),
    );
  }

  Widget _themeOption({
    required ThemeMode mode,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return RadioListTile<ThemeMode>(
      value: mode,
      contentPadding: EdgeInsets.zero,
      activeColor: primaryBlue,
      secondary: Icon(icon, color: primaryBlue),
      title: Text(title),
      subtitle: Text(description),
    );
  }

  Widget _appearanceSettings() {
    final controller = ThemeControllerScope.of(context);

    return _settingsCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette_outlined, color: primaryBlue),
              SizedBox(width: 10),
              Text(
                'Application Theme',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Choose how the application looks.',
            style: TextStyle(fontSize: 12),
          ),

          const SizedBox(height: 12),

          RadioGroup<ThemeMode>(
            groupValue: controller.themeMode,
            onChanged: (value) {
              if (!_isSavingTheme && value != null) {
                _saveTheme(value);
              }
            },
            child: Column(
              children: [
                _themeOption(
                  mode: ThemeMode.system,
                  title: 'System Default',
                  description: 'Follow device appearance',
                  icon: Icons.smartphone_outlined,
                ),
                _themeOption(
                  mode: ThemeMode.light,
                  title: 'Light Mode',
                  description: 'Always use light appearance',
                  icon: Icons.light_mode_outlined,
                ),
                _themeOption(
                  mode: ThemeMode.dark,
                  title: 'Dark Mode',
                  description: 'Always use dark appearance',
                  icon: Icons.dark_mode_outlined,
                ),
              ],
            ),
          ),

          if (_isSavingTheme) const LinearProgressIndicator(color: primaryBlue),
        ],
      ),
    );
  }

  Widget _tariffUpdateSettings() {
    return _settingsCard(
      Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.sync_outlined, color: primaryBlue),
            title: const Text('Automatic Tariff Updates'),
            subtitle: const Text(
              'Check for verified tariff updates when the app starts. '
              'Manual checks remain available when disabled.',
            ),
            value: _automaticTariffUpdates,
            onChanged: _isSavingAutomaticUpdates
                ? null
                : _saveAutomaticTariffUpdates,
          ),
          if (_isSavingAutomaticUpdates)
            const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _aboutSettings() {
    return _settingsCard(
      const Column(
        children: [
          ListTile(
            leading: Icon(Icons.info_outline, color: primaryBlue),
            title: Text('Electricity Bill Calculator'),
            subtitle: Text('Version 1.0.0'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.verified_outlined, color: primaryBlue),
            title: Text('Tariff Information'),
            subtitle: Text(
              'Only verified tariff data is '
              'automatically used for calculations.',
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.gavel_outlined, color: primaryBlue),
            title: Text('Disclaimer'),
            subtitle: Text(
              'This is an unofficial electricity bill '
              'estimator. Provider-issued bills '
              'remain authoritative.',
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
        title: const Text('Settings'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Manage your electricity calculator preferences.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 24),
                _sectionTitle('ELECTRICITY PROVIDER'),
                _providerSettings(),

                const SizedBox(height: 24),
                _sectionTitle('APPEARANCE'),
                _appearanceSettings(),

                const SizedBox(height: 24),
                _sectionTitle('TARIFF UPDATES'),
                _tariffUpdateSettings(),

                const SizedBox(height: 24),
                _sectionTitle('ABOUT'),
                _aboutSettings(),

                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

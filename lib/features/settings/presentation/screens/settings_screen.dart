import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/preferences_service.dart';
import '../../../../core/utils/currency_utils.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/widgets/loading_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  String _selectedCurrency = 'USD';
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _hapticFeedbackEnabled = true;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = PreferencesService.getCurrency() ?? 'USD';
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account section
          _SectionHeader(title: 'ACCOUNT'),
          
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user?.displayName ?? 'User'),
            subtitle: Text(user?.email ?? ''),
          ),

          const Divider(),

          // Preferences section
          _SectionHeader(title: 'PREFERENCES'),

          // CURRENCY SWITCHING - DISABLED FOR MVP
          // TODO: Re-enable after implementing proper multi-currency conversion
          // ListTile(
          //   leading: const Icon(Icons.monetization_on),
          //   title: const Text('Currency'),
          //   subtitle: Text('$_selectedCurrency (${CurrencyUtils.getCurrencySymbol(_selectedCurrency)})'),
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () => _showCurrencyPicker(),
          // ),

          // Show currency as read-only
          ListTile(
            leading: const Icon(Icons.monetization_on),
            title: const Text('Currency'),
            subtitle: Text(
              '$_selectedCurrency (${CurrencyUtils.getCurrencySymbol(_selectedCurrency)}) - Auto-detected',
            ),
          ),

          // Dark Mode Toggle
          ListTile(
            leading: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Dark Mode'),
            subtitle: Text(_isDarkMode ? 'Enabled' : 'Disabled'),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) {
                HapticUtils.light();
                setState(() {
                  _isDarkMode = value;
                });
                // TODO: Implement theme switching with provider
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Theme switching coming soon!'),
                  ),
                );
              },
            ),
          ),
          
          // Notifications Toggle
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: Text(_notificationsEnabled ? 'Enabled' : 'Disabled'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                HapticUtils.light();
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),
          
          // Haptic Feedback Toggle
          ListTile(
            leading: const Icon(Icons.vibration),
            title: const Text('Haptic Feedback'),
            subtitle: Text(_hapticFeedbackEnabled ? 'Enabled' : 'Disabled'),
            trailing: Switch(
              value: _hapticFeedbackEnabled,
              onChanged: (value) {
                if (value) {
                  HapticUtils.light();
                }
                setState(() {
                  _hapticFeedbackEnabled = value;
                });
              },
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              HapticUtils.light();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language selection coming soon')),
              );
            },
          ),

          const Divider(),

          // Data section
          _SectionHeader(title: 'DATA'),

          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Data'),
            subtitle: const Text('Download your transactions as CSV'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export coming soon')),
              );
            },
          ),

          const Divider(),

          // About section
          _SectionHeader(title: 'ABOUT'),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(AppConstants.appVersion),
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy policy coming soon')),
              );
            },
          ),

          const Divider(),

          // Danger zone
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _confirmSignOut(),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // CURRENCY SWITCHING - DISABLED FOR MVP
  // TODO: Re-enable after implementing proper multi-currency conversion
  /* void _showCurrencyPicker() {
    final currencies = [
      {'code': 'USD', 'name': 'US Dollar'},
      {'code': 'EUR', 'name': 'Euro'},
      {'code': 'GBP', 'name': 'British Pound'},
      {'code': 'JPY', 'name': 'Japanese Yen'},
      {'code': 'CNY', 'name': 'Chinese Yuan'},
      {'code': 'CAD', 'name': 'Canadian Dollar'},
      {'code': 'AUD', 'name': 'Australian Dollar'},
      {'code': 'CHF', 'name': 'Swiss Franc'},
      {'code': 'TRY', 'name': 'Turkish Lira'},
      {'code': 'INR', 'name': 'Indian Rupee'},
      {'code': 'BRL', 'name': 'Brazilian Real'},
      {'code': 'MXN', 'name': 'Mexican Peso'},
      {'code': 'ZAR', 'name': 'South African Rand'},
      {'code': 'KRW', 'name': 'South Korean Won'},
      {'code': 'SGD', 'name': 'Singapore Dollar'},
      {'code': 'HKD', 'name': 'Hong Kong Dollar'},
      {'code': 'SEK', 'name': 'Swedish Krona'},
      {'code': 'NOK', 'name': 'Norwegian Krone'},
      {'code': 'DKK', 'name': 'Danish Krone'},
      {'code': 'PLN', 'name': 'Polish Zloty'},
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Currency',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: currencies.length,
                  itemBuilder: (context, index) {
                    final currency = currencies[index];
                    final isSelected = _selectedCurrency == currency['code'];

                    return ListTile(
                      leading: Text(
                        CurrencyUtils.getCurrencySymbol(currency['code']!),
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(currency['name']!),
                      subtitle: Text(currency['code']!),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                      selected: isSelected,
                      onTap: () async {
                        await PreferencesService.setCurrency(currency['code']!);
                        
                        final user = _authService.currentUser;
                        if (user != null) {
                          await _authService.updateUserPreferences(
                            userId: user.uid,
                            currency: currency['code']!,
                            language: PreferencesService.getLanguage() ?? 'en',
                            countryCode: currency['code']!.substring(0, 2),
                          );
                        }

                        setState(() {
                          _selectedCurrency = currency['code']!;
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Currency changed to ${currency['code']}'),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  } */

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        context.go(AppConstants.routeSignIn);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
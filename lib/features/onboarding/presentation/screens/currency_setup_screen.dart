import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/preferences_service.dart';

class CurrencySetupScreen extends StatefulWidget {
  const CurrencySetupScreen({super.key});

  @override
  State<CurrencySetupScreen> createState() => _CurrencySetupScreenState();
}

class _CurrencySetupScreenState extends State<CurrencySetupScreen> {
  final AuthService _authService = AuthService();
  late String _selectedCurrency;
  late String _detectedCurrency;
  bool _isLoading = false;

  // Popular currencies for quick selection
  final List<Map<String, String>> _popularCurrencies = [
    {'code': 'USD', 'name': 'US Dollar'},
    {'code': 'EUR', 'name': 'Euro'},
    {'code': 'GBP', 'name': 'British Pound'},
    {'code': 'JPY', 'name': 'Japanese Yen'},
    {'code': 'CNY', 'name': 'Chinese Yuan'},
    {'code': 'CAD', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'name': 'Australian Dollar'},
    {'code': 'TRY', 'name': 'Turkish Lira'},
    {'code': 'INR', 'name': 'Indian Rupee'},
    {'code': 'BRL', 'name': 'Brazilian Real'},
  ];

  @override
  void initState() {
    super.initState();
    _detectedCurrency = CurrencyUtils.detectCurrency();
    _selectedCurrency = _detectedCurrency;
  }

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Save to SharedPreferences
      await PreferencesService.setCurrency(_selectedCurrency);
      await PreferencesService.setLanguage('en'); // Default to English for now

      // Update Firestore
      await _authService.updateUserPreferences(
        userId: user.uid,
        currency: _selectedCurrency,
        language: 'en',
        countryCode: _selectedCurrency.substring(0, 2), // Simple mapping
      );

      if (mounted) {
        context.push('/onboarding/complete');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Setup'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Icon
              const Icon(
                Icons.monetization_on,
                size: 80,
                color: Colors.blue,
              ),
              
              const SizedBox(height: 24),
              
              // Title
              const Text(
                'Choose Your Currency',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Auto-detected currency
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Auto-detected:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '$_detectedCurrency (${CurrencyUtils.getCurrencySymbol(_detectedCurrency)})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Currency selection
              const Text(
                'Or choose a different currency:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Popular currencies grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _popularCurrencies.length,
                  itemBuilder: (context, index) {
                    final currency = _popularCurrencies[index];
                    final isSelected = _selectedCurrency == currency['code'];
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCurrency = currency['code']!;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.blue 
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? Colors.blue 
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                CurrencyUtils.getCurrencySymbol(currency['code']!),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currency['code']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected 
                                      ? Colors.white 
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
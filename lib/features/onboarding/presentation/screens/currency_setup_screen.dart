import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../shared/widgets/glass_card.dart';
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
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: DesignTokens.space12),
              
              // Icon
              Icon(
                PhosphorIcons.currencyCircleDollar(PhosphorIconsStyle.duotone),
                size: 64,
                color: AppTheme.primaryIndigo,
              ).animate().fadeIn().scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
              ),
              
              SizedBox(height: DesignTokens.space20),
              
              // Title
              Text(
                'Choose Your Currency',
                textAlign: TextAlign.center,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 100.ms),
              
              SizedBox(height: DesignTokens.space8),
              
              // Auto-detected currency
              GlassCard(
                padding: EdgeInsets.all(DesignTokens.space16),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.mapPin(), color: AppTheme.primaryIndigo, size: DesignTokens.iconMD),
                    SizedBox(width: DesignTokens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto-detected:',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            '$_detectedCurrency (${CurrencyUtils.getCurrencySymbol(_detectedCurrency)})',
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedCurrency == _detectedCurrency)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.space8,
                          vertical: DesignTokens.space4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentEmerald.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                        ),
                        child: Text(
                          'Selected',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: AppTheme.accentEmerald,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
              
              SizedBox(height: DesignTokens.space24),
              
              // Currency selection label
              Text(
                'Or choose a different currency:',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 300.ms),
              
              SizedBox(height: DesignTokens.space16),
              
              // Popular currencies grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: DesignTokens.space12,
                    mainAxisSpacing: DesignTokens.space12,
                  ),
                  itemCount: _popularCurrencies.length,
                  itemBuilder: (context, index) {
                    final currency = _popularCurrencies[index];
                    final isSelected = _selectedCurrency == currency['code'];
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCurrency = currency['code']!;
                        });
                      },
                      child: AnimatedContainer(
                        duration: DesignTokens.durationFast,
                        curve: DesignTokens.curveStandard,
                        padding: EdgeInsets.all(DesignTokens.space12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.primaryIndigo
                              : context.colors.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                          border: Border.all(
                            color: isSelected 
                                ? AppTheme.primaryIndigo 
                                : context.colors.outlineVariant.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                CurrencyUtils.getCurrencySymbol(currency['code']!),
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                              SizedBox(height: DesignTokens.space2),
                              Text(
                                currency['code']!,
                                style: context.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isSelected 
                                      ? Colors.white.withOpacity(0.8)
                                      : context.colors.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (350 + index * 50).ms).scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.0, 1.0),
                    );
                  },
                ),
              ),
              
              SizedBox(height: DesignTokens.space20),
              
              // Continue Button
              PremiumButton(
                onPressed: _isLoading ? null : _handleContinue,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
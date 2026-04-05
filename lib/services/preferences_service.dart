import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class PreferencesService {
  static SharedPreferences? _prefs;
  
  // Initialize
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Onboarding
  static Future<void> setOnboardingComplete(bool value) async {
    await _prefs?.setBool(AppConstants.keyOnboardingComplete, value);
    print('✅ PREFS: Set onboarding complete = $value');
    print('📝 PREFS: Verification read = ${_prefs?.getBool(AppConstants.keyOnboardingComplete)}');
  }
  
  static bool isOnboardingComplete() {
    final result = _prefs?.getBool(AppConstants.keyOnboardingComplete) ?? false;
    print('🔍 PREFS: Check onboarding complete = $result');
    return result;
  }
  
  // Currency
  static Future<void> setCurrency(String currency) async {
    await _prefs?.setString(AppConstants.keyCurrency, currency);
  }
  
  static String? getCurrency() {
    return _prefs?.getString(AppConstants.keyCurrency);
  }
  
  // Language
  static Future<void> setLanguage(String language) async {
    await _prefs?.setString(AppConstants.keyLanguage, language);
  }
  
  static String? getLanguage() {
    return _prefs?.getString(AppConstants.keyLanguage);
  }

  // Notifications enabled
  static Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool('notifications_enabled', value);
  }

  static bool isNotificationsEnabled() {
    return _prefs?.getBool('notifications_enabled') ?? true;
  }

  // Haptic feedback enabled
  static Future<void> setHapticFeedbackEnabled(bool value) async {
    await _prefs?.setBool('haptic_feedback_enabled', value);
  }

  static bool isHapticFeedbackEnabled() {
    return _prefs?.getBool('haptic_feedback_enabled') ?? true;
  }
}
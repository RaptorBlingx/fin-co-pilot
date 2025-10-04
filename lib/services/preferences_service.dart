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
  }
  
  static bool isOnboardingComplete() {
    return _prefs?.getBool(AppConstants.keyOnboardingComplete) ?? false;
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
}
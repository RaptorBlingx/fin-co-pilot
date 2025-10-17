import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }
  
  bool get isLightMode {
    return _themeMode == ThemeMode.light;
  }
  
  bool get isSystemMode {
    return _themeMode == ThemeMode.system;
  }

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  /// Toggle between light and dark mode
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  /// Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeToPrefs();
    notifyListeners();
  }

  /// Get the light theme
  ThemeData get lightTheme => AppTheme.lightTheme;

  /// Get the dark theme
  ThemeData get darkTheme => AppTheme.darkTheme;

  /// Load theme preference from SharedPreferences
  void _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
          default:
            _themeMode = ThemeMode.system;
            break;
        }
        notifyListeners();
      }
    } catch (e) {
      // If there's an error loading preferences, stick with system default
      _themeMode = ThemeMode.system;
    }
  }

  /// Save theme preference to SharedPreferences
  void _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      
      switch (_themeMode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
        default:
          themeString = 'system';
          break;
      }
      
      await prefs.setString(_themeKey, themeString);
    } catch (e) {
      // Handle save error silently
      debugPrint('Error saving theme preference: $e');
    }
  }
}
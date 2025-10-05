import 'package:flutter/services.dart';

/// Utility class for consistent haptic feedback throughout the app
class HapticUtils {
  
  /// Light haptic feedback for subtle interactions
  /// Use for: Button taps, switch toggles, selection changes
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }
  
  /// Medium haptic feedback for standard interactions
  /// Use for: Navigation, form submissions, confirmations
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }
  
  /// Heavy haptic feedback for important interactions
  /// Use for: Deletions, critical actions, major state changes
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }
  
  /// Selection haptic feedback for picker/slider interactions
  /// Use for: Scrolling through lists, adjusting sliders, picking dates
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }
  
  /// Vibration pattern for success actions
  /// Use for: Successful transactions, completed tasks, achievements
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }
  
  /// Vibration pattern for error/warning actions  
  /// Use for: Form errors, failed operations, warnings
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }
  
  /// Double tap haptic pattern
  /// Use for: Like actions, favorites, bookmarks
  static Future<void> doubleTap() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }
  
  /// Long press haptic feedback
  /// Use for: Context menus, drag operations, long press actions
  static Future<void> longPress() async {
    await HapticFeedback.mediumImpact();
  }
  
  /// Notification haptic pattern
  /// Use for: Incoming notifications, alerts, reminders
  static Future<void> notification() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 75));
    await HapticFeedback.lightImpact();
  }
}
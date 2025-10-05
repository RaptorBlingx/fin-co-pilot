import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class HapticUtils {
  // Light impact - for selections, switches
  static void light() {
    HapticFeedback.lightImpact();
  }

  // Medium impact - for button taps
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  // Heavy impact - for important actions
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  // Selection click - for picker changes
  static void selection() {
    HapticFeedback.selectionClick();
  }

  // Success feedback
  static void success() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 50), () {
      HapticFeedback.lightImpact();
    });
  }

  // Error feedback
  static void error() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 50), () {
      HapticFeedback.heavyImpact();
    });
  }

  // Warning feedback
  static void warning() {
    HapticFeedback.mediumImpact();
  }
}

// Extension for easy use on widgets
extension HapticWidget on Widget {
  Widget withHaptic({
    VoidCallback? onTap,
    HapticFeedbackType type = HapticFeedbackType.medium,
  }) {
    return GestureDetector(
      onTap: () {
        _triggerHaptic(type);
        onTap?.call();
      },
      child: this,
    );
  }

  void _triggerHaptic(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.light:
        HapticUtils.light();
        break;
      case HapticFeedbackType.medium:
        HapticUtils.medium();
        break;
      case HapticFeedbackType.heavy:
        HapticUtils.heavy();
        break;
      case HapticFeedbackType.selection:
        HapticUtils.selection();
        break;
      case HapticFeedbackType.success:
        HapticUtils.success();
        break;
      case HapticFeedbackType.error:
        HapticUtils.error();
        break;
      case HapticFeedbackType.warning:
        HapticUtils.warning();
        break;
    }
  }
}

enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
  success,
  error,
  warning,
}
import 'package:flutter/material.dart';

/// SOTA Design Tokens — Single source of truth for every dimension, timing,
/// and visual constant in the app. No magic numbers anywhere else.
abstract final class DesignTokens {
  // ─────────────────────────── Spacing ───────────────────────────
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Named aliases for semantic usage
  static const double paddingXS = space4;
  static const double paddingS = space8;
  static const double paddingM = space16;
  static const double paddingL = space24;
  static const double paddingXL = space32;
  static const double paddingXXL = space48;

  static const double gapXS = space4;
  static const double gapS = space8;
  static const double gapM = space16;
  static const double gapL = space24;
  static const double gapXL = space32;

  // Screen-level horizontal padding
  static const double screenPadding = space24;
  static const EdgeInsets screenInsets =
      EdgeInsets.symmetric(horizontal: screenPadding);
  static const EdgeInsets screenInsetsAll = EdgeInsets.all(screenPadding);

  // ─────────────────────────── Radius ────────────────────────────
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusFull = 9999.0;

  static const BorderRadius borderRadiusXS =
      BorderRadius.all(Radius.circular(radiusXS));
  static const BorderRadius borderRadiusSM =
      BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius borderRadiusMD =
      BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius borderRadiusLG =
      BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius borderRadiusXL =
      BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderRadiusXXL =
      BorderRadius.all(Radius.circular(radiusXXL));
  static const BorderRadius borderRadiusFull =
      BorderRadius.all(Radius.circular(radiusFull));

  // ─────────────────────────── Icon Sizes ────────────────────────
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 28.0;
  static const double iconXL = 32.0;
  static const double iconXXL = 48.0;

  // ─────────────────────────── Tap Targets ───────────────────────
  static const double minTapTarget = 48.0; // Material 3 minimum
  static const double buttonMinHeight = 48.0;
  static const double buttonMinWidth = 120.0;

  // ─────────────────────────── Motion ────────────────────────────
  // Durations
  static const Duration durationInstant = Duration(milliseconds: 100);
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationDramatic = Duration(milliseconds: 800);

  // Curves
  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveDecelerate = Curves.easeOutCubic;
  static const Curve curveAccelerate = Curves.easeInCubic;
  static const Curve curveSpring = Curves.elasticOut;
  static const Curve curveBounce = Curves.bounceOut;
  static const Curve curveEmphasized = Cubic(0.2, 0.0, 0.0, 1.0); // M3

  // Stagger
  static const Duration staggerDelay = Duration(milliseconds: 50);
  static Duration staggerFor(int index) =>
      Duration(milliseconds: 50 * index);

  // ─────────────────────────── Elevation ─────────────────────────
  // M3 tonal surface elevation (opacity values for surface tint)
  static const double elevationLevel0 = 0.0;   // 0% tint
  static const double elevationLevel1 = 0.05;  // 5% tint
  static const double elevationLevel2 = 0.08;  // 8% tint
  static const double elevationLevel3 = 0.11;  // 11% tint
  static const double elevationLevel4 = 0.12;  // 12% tint
  static const double elevationLevel5 = 0.14;  // 14% tint

  // ─────────────────────────── Glass ─────────────────────────────
  static const double glassBlurLight = 12.0;
  static const double glassBlurMedium = 20.0;
  static const double glassBlurHeavy = 30.0;

  // Dark mode glass
  static const double glassOpacityDark = 0.12;
  static const double glassBorderOpacityDark = 0.08;
  static const double glassHighlightOpacityDark = 0.05;

  // Light mode glass
  static const double glassOpacityLight = 0.70;
  static const double glassBorderOpacityLight = 0.15;
  static const double glassHighlightOpacityLight = 0.25;

  // Glass border width
  static const double glassBorderWidth = 1.0;

  // ─────────────────────────── Misc ──────────────────────────────
  // Hero spending card height ratio
  static const double heroCardHeightRatio = 0.35;

  // Avatar / icon container sizes
  static const double avatarSM = 32.0;
  static const double avatarMD = 40.0;
  static const double avatarLG = 48.0;
  static const double avatarXL = 56.0;
  static const double avatarXXL = 80.0;

  // Card internal padding
  static const EdgeInsets cardPadding = EdgeInsets.all(space16);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(space20);

  // Bottom navigation bar height
  static const double bottomNavHeight = 80.0;

  // FAB
  static const double fabSize = 56.0;
  static const double fabIconSize = 28.0;
  static const double fabPressScale = 0.88;
  static const double buttonPressScale = 0.97;

  // Sparkline / chart constants
  static const double chartStrokeWidth = 2.5;
  static const double chartDotRadius = 4.0;

  // Progress ring
  static const double progressRingStroke = 6.0;
  static const double progressRingStrokeLarge = 8.0;
}

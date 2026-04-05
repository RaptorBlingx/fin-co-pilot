import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_tokens.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// THEME EXTENSIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Finance-specific semantic colors.
/// Access: `Theme.of(context).extension<FinanceColors>()!`
class FinanceColors extends ThemeExtension<FinanceColors> {
  final Color positive;       // Income / gains
  final Color negative;       // Expenses / losses
  final Color neutral;        // Neutral amounts
  final Color budgetHealthy;  // < 50% spent
  final Color budgetWarning;  // 50–80%
  final Color budgetDanger;   // 80–100%
  final Color budgetCritical; // > 100%

  const FinanceColors({
    required this.positive,
    required this.negative,
    required this.neutral,
    required this.budgetHealthy,
    required this.budgetWarning,
    required this.budgetDanger,
    required this.budgetCritical,
  });

  @override
  FinanceColors copyWith({
    Color? positive,
    Color? negative,
    Color? neutral,
    Color? budgetHealthy,
    Color? budgetWarning,
    Color? budgetDanger,
    Color? budgetCritical,
  }) {
    return FinanceColors(
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      neutral: neutral ?? this.neutral,
      budgetHealthy: budgetHealthy ?? this.budgetHealthy,
      budgetWarning: budgetWarning ?? this.budgetWarning,
      budgetDanger: budgetDanger ?? this.budgetDanger,
      budgetCritical: budgetCritical ?? this.budgetCritical,
    );
  }

  @override
  FinanceColors lerp(FinanceColors? other, double t) {
    if (other == null) return this;
    return FinanceColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      budgetHealthy: Color.lerp(budgetHealthy, other.budgetHealthy, t)!,
      budgetWarning: Color.lerp(budgetWarning, other.budgetWarning, t)!,
      budgetDanger: Color.lerp(budgetDanger, other.budgetDanger, t)!,
      budgetCritical: Color.lerp(budgetCritical, other.budgetCritical, t)!,
    );
  }
}

/// Glassmorphism tokens.
/// Access: `Theme.of(context).extension<GlassTheme>()!`
class GlassTheme extends ThemeExtension<GlassTheme> {
  final Color glassBackground;
  final Color glassBorder;
  final Color glassHighlight;
  final double blurSigma;

  const GlassTheme({
    required this.glassBackground,
    required this.glassBorder,
    required this.glassHighlight,
    required this.blurSigma,
  });

  @override
  GlassTheme copyWith({
    Color? glassBackground,
    Color? glassBorder,
    Color? glassHighlight,
    double? blurSigma,
  }) {
    return GlassTheme(
      glassBackground: glassBackground ?? this.glassBackground,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      blurSigma: blurSigma ?? this.blurSigma,
    );
  }

  @override
  GlassTheme lerp(GlassTheme? other, double t) {
    if (other == null) return this;
    return GlassTheme(
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONVENIENCE EXTENSION ON BuildContext
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  FinanceColors get financeColors => theme.extension<FinanceColors>()!;
  GlassTheme get glass => theme.extension<GlassTheme>()!;
  bool get isDark => theme.brightness == Brightness.dark;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// APP THEME
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppTheme {
  AppTheme._();

  // ─────────────── Brand Colors ──────────────────────────────────
  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color primaryIndigoLight = Color(0xFF818CF8);
  static const Color primaryIndigoDark = Color(0xFF3730A3);

  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentEmeraldLight = Color(0xFF34D399);
  static const Color accentEmeraldDark = Color(0xFF059669);

  static const Color accentPurple = Color(0xFF7C3AED);

  // ─────────────── Full Tonal Palettes ───────────────────────────
  // Indigo
  static const Color indigo50  = Color(0xFFEEF2FF);
  static const Color indigo100 = Color(0xFFE0E7FF);
  static const Color indigo200 = Color(0xFFC7D2FE);
  static const Color indigo300 = Color(0xFFA5B4FC);
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF4338CA);
  static const Color indigo800 = Color(0xFF3730A3);
  static const Color indigo900 = Color(0xFF312E81);

  // Emerald
  static const Color emerald50  = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald800 = Color(0xFF065F46);
  static const Color emerald900 = Color(0xFF064E3B);

  // Rose (for negative amounts — softer than red)
  static const Color rose50  = Color(0xFFFFF1F2);
  static const Color rose100 = Color(0xFFFFE4E6);
  static const Color rose200 = Color(0xFFFECDD3);
  static const Color rose300 = Color(0xFFFDA4AF);
  static const Color rose400 = Color(0xFFFB7185);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose600 = Color(0xFFE11D48);
  static const Color rose700 = Color(0xFFBE123C);

  // Amber (warnings)
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);

  // Slate (neutrals)
  static const Color slate50  = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // ─────────────── Dark Surface Layers ───────────────────────────
  static const Color darkBackground       = Color(0xFF0C0F14);
  static const Color darkSurface          = Color(0xFF141820);
  static const Color darkSurfaceContainer = Color(0xFF1A1F2A);
  static const Color darkSurfaceHigh      = Color(0xFF222836);
  static const Color darkSurfaceHighest   = Color(0xFF2A3140);

  // ─────────────── Semantic Colors ───────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);

  // ─────────────── Category Colors (WCAG AA) ─────────────────────
  /// 10 curated colors that work on both light and dark backgrounds.
  static const List<Color> categoryColors = [
    Color(0xFF10B981), // Emerald  — Groceries
    Color(0xFFF97316), // Orange   — Dining
    Color(0xFF3B82F6), // Blue     — Transport
    Color(0xFF8B5CF6), // Violet   — Entertainment
    Color(0xFFEC4899), // Pink     — Shopping
    Color(0xFFEF4444), // Red      — Health
    Color(0xFF78716C), // Stone    — Bills
    Color(0xFF6366F1), // Indigo   — Education
    Color(0xFF14B8A6), // Teal     — Travel
    Color(0xFF94A3B8), // Slate    — Other
  ];

  /// Chart palette — 10 perceptually-spaced colors for data viz.
  static const List<Color> chartPalette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF97316), // Orange
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF43F5E), // Rose
    Color(0xFF3B82F6), // Blue
    Color(0xFFFBBF24), // Amber
    Color(0xFF14B8A6), // Teal
    Color(0xFFEC4899), // Pink
    Color(0xFF78716C), // Stone
  ];

  // ─────────────── Gradients ─────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryIndigo, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [indigo700, Color(0xFF5B21B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [emerald500, Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─────────────── Compatibility Aliases ─────────────────────────
  static const Color primaryGreen = accentEmerald;
  static const Color primaryGreenLight = accentEmeraldLight;
  static const Color primaryGreenDark = accentEmeraldDark;
  static const Color successGreen = success;
  static const Color errorRed = error;
  static const Color infoBlue = info;
  static const Color accentBlue = info;
  static const Color accentOrange = warning;
  static const Color warningOrange = warning;
  static const Color lightGray = slate200;
  static const Color mediumGray = slate400;

  // Legacy spacing (prefer DesignTokens)
  static const double spacingXS = DesignTokens.paddingXS;
  static const double spacingS = DesignTokens.paddingS;
  static const double spacingM = DesignTokens.paddingM;
  static const double spacingL = DesignTokens.paddingL;
  static const double spacingXL = DesignTokens.paddingXL;

  // Legacy radius (prefer DesignTokens)
  static const BorderRadius smallRadius = DesignTokens.borderRadiusSM;
  static const BorderRadius mediumRadius = DesignTokens.borderRadiusMD;
  static const BorderRadius largeRadius = DesignTokens.borderRadiusLG;

  // ─────────────── Utility Methods ───────────────────────────────
  static Color getSurfaceColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color getSecondaryTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? slate600 : slate400;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TYPOGRAPHY HELPERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Hero money amount (e.g. "$1,234.56" on dashboard card)
  static TextStyle displayAmountStyle(BuildContext context) {
    return TextStyle(
      fontFamily: 'Manrope',
      fontSize: 40,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      height: 1.1,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  /// Inline amount in lists (e.g. "-$24.99" in transaction tile)
  static TextStyle monoAmountStyle(BuildContext context) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.0,
      height: 1.2,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LIGHT THEME
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primaryIndigo,
      onPrimary: Colors.white,
      primaryContainer: indigo100,
      onPrimaryContainer: indigo900,
      secondary: accentEmerald,
      onSecondary: Colors.white,
      secondaryContainer: emerald100,
      onSecondaryContainer: emerald900,
      tertiary: accentPurple,
      error: error,
      onError: Colors.white,
      errorContainer: rose100,
      onErrorContainer: rose700,
      surface: Colors.white,
      onSurface: slate900,
      onSurfaceVariant: slate600,
      surfaceContainerLowest: slate50,
      surfaceContainerLow: Color(0xFFF5F6F8),
      surfaceContainer: Color(0xFFF0F2F5),
      surfaceContainerHigh: slate100,
      surfaceContainerHighest: slate200,
      outline: slate300,
      outlineVariant: slate200,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DARK THEME (Hero)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: indigo400,
      onPrimary: Colors.white,
      primaryContainer: indigo800,
      onPrimaryContainer: indigo100,
      secondary: emerald400,
      onSecondary: Colors.white,
      secondaryContainer: emerald800,
      onSecondaryContainer: emerald100,
      tertiary: Color(0xFFA78BFA), // Violet-400
      error: rose400,
      onError: Colors.white,
      errorContainer: Color(0xFF4A0D20),
      onErrorContainer: rose200,
      surface: darkSurface,
      onSurface: slate50,
      onSurfaceVariant: slate400,
      surfaceContainerLowest: darkBackground,
      surfaceContainerLow: Color(0xFF121620),
      surfaceContainer: darkSurfaceContainer,
      surfaceContainerHigh: darkSurfaceHigh,
      surfaceContainerHighest: darkSurfaceHighest,
      outline: Color(0xFF363E50),
      outlineVariant: Color(0xFF252C3A),
      shadow: Colors.black,
      scrim: Colors.black,
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SHARED BUILDER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static ThemeData _buildTheme(ColorScheme cs, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Text colors
    final textPrimary = cs.onSurface;
    final textSecondary = cs.onSurfaceVariant;
    final textTertiary = isDark ? slate500 : slate400;

    // ─── Text Theme ───
    final textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.1,
        color: textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
        color: textPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.2,
        color: textPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.2,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.2,
        color: textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        height: 1.25,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
        height: 1.25,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.35,
        color: textPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.35,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
        color: textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.0,
        color: textPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.0,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.0,
        color: textTertiary,
      ),
    );

    // ─── Build ThemeData ───
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: isDark ? darkBackground : slate50,
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
          color: cs.onSurface,
        ),
        iconTheme: IconThemeData(
          color: cs.onSurface,
          size: DesignTokens.iconMD,
        ),
      ),

      // Card
      cardTheme: CardTheme(
        color: cs.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusMD,
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : cs.outlineVariant,
            width: DesignTokens.glassBorderWidth,
          ),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          minimumSize: const Size(
            DesignTokens.buttonMinWidth,
            DesignTokens.buttonMinHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.paddingL,
            vertical: DesignTokens.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMD,
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          elevation: 0,
          minimumSize: const Size(
            DesignTokens.buttonMinWidth,
            DesignTokens.buttonMinHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.paddingL,
            vertical: DesignTokens.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMD,
          ),
          side: BorderSide(color: cs.outline),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size(DesignTokens.minTapTarget, DesignTokens.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.paddingM,
            vertical: DesignTokens.paddingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusSM,
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            DesignTokens.buttonMinWidth,
            DesignTokens.buttonMinHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.paddingL,
            vertical: DesignTokens.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMD,
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurfaceContainer : slate50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.paddingM,
          vertical: DesignTokens.paddingM,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: textTertiary,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation Bar (legacy — will be replaced by NavigationBar)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? darkSurface : Colors.white,
        selectedItemColor: cs.primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
        ),
      ),

      // Navigation Bar (M3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: cs.primary.withOpacity(0.12),
        elevation: 0,
        height: DesignTokens.bottomNavHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary, size: DesignTokens.iconMD);
          }
          return IconThemeData(color: textTertiary, size: DesignTokens.iconMD);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: cs.primary,
            );
          }
          return TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
            color: textTertiary,
          );
        }),
      ),

      // Segmented Button (for period selectors)
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return cs.primary;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return cs.onPrimary;
            }
            return cs.onSurfaceVariant;
          }),
          textStyle: WidgetStateProperty.all(const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          )),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusSM,
            ),
          ),
          side: WidgetStateProperty.all(
            BorderSide(color: cs.outlineVariant),
          ),
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.onPrimary;
          return cs.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return cs.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return cs.outline;
        }),
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusXL,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? darkSurfaceHigh : slate800,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusMD,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // TabBar
      tabBarTheme: TabBarTheme(
        labelColor: cs.primary,
        unselectedLabelColor: textSecondary,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: cs.primary, width: 2.5),
          borderRadius: DesignTokens.borderRadiusFull,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
        ),
        dividerHeight: 0,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? darkSurfaceHighest : slate800,
          borderRadius: DesignTokens.borderRadiusSM,
        ),
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: isDark ? slate200 : Colors.white,
        ),
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.primary.withOpacity(0.12),
        circularTrackColor: cs.primary.withOpacity(0.12),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? darkSurfaceContainer : Colors.white,
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusFull,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? darkSurfaceContainer : Colors.white,
        modalBackgroundColor: isDark ? darkSurfaceContainer : Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusXXL),
          ),
        ),
        dragHandleColor: cs.onSurfaceVariant.withOpacity(0.4),
        dragHandleSize: const Size(32, 4),
        showDragHandle: true,
      ),

      // Extensions
      extensions: [
        // Finance colors
        isDark
            ? const FinanceColors(
                positive: emerald400,
                negative: rose400,
                neutral: slate400,
                budgetHealthy: emerald400,
                budgetWarning: amber400,
                budgetDanger: rose400,
                budgetCritical: rose500,
              )
            : const FinanceColors(
                positive: emerald600,
                negative: rose500,
                neutral: slate500,
                budgetHealthy: emerald500,
                budgetWarning: amber500,
                budgetDanger: rose500,
                budgetCritical: rose600,
              ),

        // Glass theme
        isDark
            ? GlassTheme(
                glassBackground:
                    Colors.white.withOpacity(DesignTokens.glassOpacityDark),
                glassBorder: Colors.white
                    .withOpacity(DesignTokens.glassBorderOpacityDark),
                glassHighlight: Colors.white
                    .withOpacity(DesignTokens.glassHighlightOpacityDark),
                blurSigma: DesignTokens.glassBlurMedium,
              )
            : GlassTheme(
                glassBackground:
                    Colors.white.withOpacity(DesignTokens.glassOpacityLight),
                glassBorder: Colors.white
                    .withOpacity(DesignTokens.glassBorderOpacityLight),
                glassHighlight: Colors.white
                    .withOpacity(DesignTokens.glassHighlightOpacityLight),
                blurSigma: DesignTokens.glassBlurLight,
              ),
      ],
    );
  }
}
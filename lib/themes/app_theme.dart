import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Primary brand colors
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryGreenDark = Color(0xFF1B5E20);
  static const Color primaryGreenLight = Color(0xFF4CAF50);
  
  // Secondary colors
  static const Color accentBlue = Color(0xFF1976D2);
  static const Color accentOrange = Color(0xFFFF8F00);
  static const Color accentPurple = Color(0xFF7B1FA2);
  
  // Neutral colors
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);
  static const Color darkGray = Color(0xFF424242);
  
  // Status colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);
  
  // Background colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Text colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0BEC5);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, primaryGreenLight],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
  );
  
  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2C2C2C), Color(0xFF1E1E1E)],
  );

  // Shadow definitions
  static const BoxShadow lightShadow = BoxShadow(
    color: Color(0x0A000000),
    offset: Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  );
  
  static const BoxShadow mediumShadow = BoxShadow(
    color: Color(0x14000000),
    offset: Offset(0, 4),
    blurRadius: 16,
    spreadRadius: 0,
  );
  
  static const BoxShadow heavyShadow = BoxShadow(
    color: Color(0x1F000000),
    offset: Offset(0, 8),
    blurRadius: 24,
    spreadRadius: 0,
  );

  // Border radius
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius extraLargeRadius = BorderRadius.all(Radius.circular(24));

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: backgroundLight,
      
      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        primaryContainer: primaryGreenLight,
        secondary: accentBlue,
        secondaryContainer: Color(0xFFE3F2FD),
        surface: surfaceLight,
        background: backgroundLight,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        onBackground: textPrimaryLight,
        onError: Colors.white,
        tertiary: accentOrange,
        outline: mediumGray,
      ),
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundLight,
        foregroundColor: textPrimaryLight,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: mediumRadius),
        margin: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryGreen.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: mediumRadius),
          padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: mediumRadius),
          padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: smallRadius),
          padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: const BorderSide(color: mediumGray, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: const BorderSide(color: mediumGray, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingM),
        labelStyle: const TextStyle(
          color: textSecondaryLight,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: mediumGray,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundLight,
        selectedItemColor: primaryGreen,
        unselectedItemColor: mediumGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Tab bar theme
      tabBarTheme: const TabBarTheme(
        labelColor: primaryGreen,
        unselectedLabelColor: mediumGray,
        indicatorColor: primaryGreen,
        labelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: darkGray,
        size: 24,
      ),
      
      // Primary icon theme
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      
      // Text theme
      textTheme: _buildTextTheme(false),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: lightGray,
        thickness: 1,
        space: 1,
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen;
          }
          return mediumGray;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreenLight;
          }
          return lightGray;
        }),
      ),
      
      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: const BorderSide(color: mediumGray, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      
      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen;
          }
          return mediumGray;
        }),
      ),
      
      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryGreen,
        inactiveTrackColor: lightGray,
        thumbColor: primaryGreen,
        overlayColor: primaryGreen.withOpacity(0.2),
        valueIndicatorColor: primaryGreen,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: lightGray,
        circularTrackColor: lightGray,
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: lightGray,
        selectedColor: primaryGreenLight,
        secondarySelectedColor: primaryGreenLight,
        padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
        labelStyle: const TextStyle(
          color: textPrimaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: extraLargeRadius),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.green,
      primaryColor: primaryGreenLight,
      scaffoldBackgroundColor: backgroundDark,
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryGreenLight,
        primaryContainer: primaryGreen,
        secondary: accentBlue,
        secondaryContainer: Color(0xFF1565C0),
        surface: surfaceDark,
        background: backgroundDark,
        error: errorRed,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
        onBackground: textPrimaryDark,
        onError: Colors.white,
        tertiary: accentOrange,
        outline: Color(0xFF616161),
      ),
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: backgroundDark,
        foregroundColor: textPrimaryDark,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        color: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: mediumRadius),
        margin: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreenLight,
          foregroundColor: Colors.black,
          elevation: 3,
          shadowColor: primaryGreenLight.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: mediumRadius),
          padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreenLight,
          side: const BorderSide(color: primaryGreenLight, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: mediumRadius),
          padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreenLight,
          shape: RoundedRectangleBorder(borderRadius: smallRadius),
          padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: const BorderSide(color: Color(0xFF616161), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: const BorderSide(color: Color(0xFF616161), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: const BorderSide(color: primaryGreenLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: mediumRadius,
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingM),
        labelStyle: const TextStyle(
          color: textSecondaryDark,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF616161),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryGreenLight,
        unselectedItemColor: Color(0xFF616161),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Tab bar theme
      tabBarTheme: const TabBarTheme(
        labelColor: primaryGreenLight,
        unselectedLabelColor: Color(0xFF616161),
        indicatorColor: primaryGreenLight,
        labelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: textSecondaryDark,
        size: 24,
      ),
      
      // Primary icon theme
      primaryIconTheme: const IconThemeData(
        color: Colors.black,
        size: 24,
      ),
      
      // Text theme
      textTheme: _buildTextTheme(true),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
        thickness: 1,
        space: 1,
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreenLight;
          }
          return Color(0xFF616161);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreen;
          }
          return Color(0xFF424242);
        }),
      ),
      
      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreenLight;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.black),
        side: const BorderSide(color: Color(0xFF616161), width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      
      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryGreenLight;
          }
          return Color(0xFF616161);
        }),
      ),
      
      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryGreenLight,
        inactiveTrackColor: Color(0xFF424242),
        thumbColor: primaryGreenLight,
        overlayColor: primaryGreenLight.withOpacity(0.2),
        valueIndicatorColor: primaryGreenLight,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreenLight,
        linearTrackColor: Color(0xFF424242),
        circularTrackColor: Color(0xFF424242),
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreenLight,
        foregroundColor: Colors.black,
        elevation: 6,
        shape: CircleBorder(),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF424242),
        selectedColor: primaryGreen,
        secondarySelectedColor: primaryGreen,
        padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
        labelStyle: const TextStyle(
          color: textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: extraLargeRadius),
      ),
    );
  }

  // Text theme builder
  static TextTheme _buildTextTheme(bool isDark) {
    final Color primaryTextColor = isDark ? textPrimaryDark : textPrimaryLight;
    final Color secondaryTextColor = isDark ? textSecondaryDark : textSecondaryLight;
    
    return TextTheme(
      // Headlines
      headlineLarge: TextStyle(
        color: primaryTextColor,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        color: primaryTextColor,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        color: primaryTextColor,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.3,
      ),
      
      // Titles
      titleLarge: TextStyle(
        color: primaryTextColor,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        color: primaryTextColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        color: primaryTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      
      // Body text
      bodyLarge: TextStyle(
        color: primaryTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: primaryTextColor,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        color: secondaryTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.3,
      ),
      
      // Labels
      labelLarge: TextStyle(
        color: primaryTextColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      labelMedium: TextStyle(
        color: primaryTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
      ),
      labelSmall: TextStyle(
        color: secondaryTextColor,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
      ),
    );
  }

  // Utility methods for consistent styling
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: backgroundLight,
    borderRadius: mediumRadius,
    boxShadow: const [lightShadow],
  );
  
  static BoxDecoration get darkCardDecoration => BoxDecoration(
    color: surfaceDark,
    borderRadius: mediumRadius,
    boxShadow: const [mediumShadow],
  );
  
  static BoxDecoration get primaryGradientDecoration => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: mediumRadius,
    boxShadow: [
      heavyShadow.copyWith(color: primaryGreen.withOpacity(0.3)),
    ],
  );
  
  // Status color helpers
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'approved':
        return successGreen;
      case 'warning':
      case 'pending':
      case 'processing':
        return warningOrange;
      case 'error':
      case 'failed':
      case 'rejected':
        return errorRed;
      case 'info':
      case 'active':
      case 'ongoing':
        return infoBlue;
      default:
        return mediumGray;
    }
  }
  
  // Icon color helpers
  static Color getIconColor(BuildContext context, {bool isActive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isActive) {
      return isDark ? primaryGreenLight : primaryGreen;
    }
    return isDark ? textSecondaryDark : textSecondaryLight;
  }
  
  // Text color helpers
  static Color getPrimaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? textPrimaryDark : textPrimaryLight;
  }
  
  static Color getSecondaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? textSecondaryDark : textSecondaryLight;
  }
  
  // Surface color helper
  static Color getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? surfaceDark : surfaceLight;
  }
}
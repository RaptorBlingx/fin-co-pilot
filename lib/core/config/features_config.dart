import 'package:flutter/foundation.dart';

/// Feature flags configuration for FinCoPilot
/// 
/// This class manages all feature toggles to enable/disable functionality
/// for different release phases (v1.0, v2.0, v3.0+)
/// 
/// Usage:
/// ```dart
/// if (FeaturesConfig.enablePriceIntelligence) {
///   // Show price intelligence features
/// }
/// ```

class FeaturesConfig {
  // ==========================================================================
  // ENVIRONMENT DETECTION
  // ==========================================================================
  
  /// Current environment (dev, staging, prod)
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );
  
  static bool get isDevelopment => environment == 'dev';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'prod';
  
  // ==========================================================================
  // TIER 1: CORE FEATURES (v1.0) - Always Enabled ✅
  // ==========================================================================
  
  /// Manual transaction entry
  static const bool enableManualTransactions = true;
  
  /// Conversational transaction input ("I spent $50 on groceries")
  static const bool enableConversationalTransactions = true;
  
  /// Receipt scanning and parsing
  static const bool enableReceiptScanning = true;
  
  /// Budget creation and tracking
  static const bool enableBudgets = true;
  
  /// Basic insights (3 charts: spending by category, trend, income vs expenses)
  static const bool enableBasicInsights = true;
  
  /// AI Financial Coaching (simplified: daily tip + Q&A)
  static const bool enableCoaching = true;
  
  /// Push notifications for budget alerts
  static const bool enableNotifications = true;
  
  /// User authentication (Firebase Auth)
  static const bool enableAuth = true;
  
  /// Analytics tracking
  static const bool enableAnalytics = true;
  
  // ==========================================================================
  // TIER 2: V2.0 FEATURES - Disabled for v1.0 Launch 💤
  // ==========================================================================
  
  // --- Price Intelligence ---
  
  /// Price intelligence and comparison (complex feature)
  static const bool enablePriceIntelligence = false;
  
  /// Price drop alerts and tracking
  static const bool enablePriceAlerts = false;
  
  /// Enhanced price finding
  static const bool enableEnhancedPriceFinder = false;
  
  /// Shopping features (wishlist, price tracking)
  static const bool enableShopping = false;
  
  // --- Smart Nudges & Pattern Learning ---
  
  /// Proactive spending suggestions and nudges
  static const bool enableSmartNudges = false;
  
  /// Pattern learning and detection
  static const bool enablePatternLearning = false;
  
  /// Proactive coaching (scheduled tips, interventions)
  static const bool enableProactiveCoaching = false;
  
  // --- Enhanced Insights & Analysis ---
  
  /// Enhanced insights beyond basic charts
  static const bool enableEnhancedInsights = false;
  
  /// Deep financial analysis
  static const bool enableFinancialAnalyst = false;
  
  /// Predictive cash flow forecasting
  static const bool enableCashFlowPrediction = false;
  
  /// Financial health score and gamification
  static const bool enableHealthScore = true;
  
  /// Money stories and narratives
  static const bool enableMoneyStories = false;
  
  // --- Subscriptions ---
  
  /// Auto-detect recurring subscriptions
  static const bool enableSubscriptionDetection = true;
  
  /// Subscription management dashboard
  static const bool enableSubscriptionManagement = true;
  
  // --- Export Features ---
  
  /// Export transactions to CSV
  static const bool enableCsvExport = true;
  
  /// Export reports to PDF
  static const bool enablePdfExport = true;
  
  /// Report generation with AI
  static const bool enableReportGenerator = true;
  
  // --- Coaching Tips Library ---
  
  /// Static coaching tips library (AI generates dynamically instead)
  static const bool enableCoachingTipsLibrary = true;
  
  /// Scheduled coaching notifications
  static const bool enableCoachingNotifications = false;
  
  // --- Additional Agents ---
  
  /// Item tracker agent (track specific purchases)
  static const bool enableItemTracker = false;
  
  /// Transaction classifier agent (auto-categorization)
  static const bool enableTransactionClassifier = false;
  
  // --- Other V2.0 Features ---
  
  /// Exchange rate service for international users
  static const bool enableExchangeRates = false;
  
  // ==========================================================================
  // TIER 3: OUT OF SCOPE - Permanently Disabled ❌
  // ==========================================================================
  
  /// Couples account management (completely out of scope)
  static const bool enableCouples = false;
  
  /// AI relationship mediation (completely out of scope)
  static const bool enableAiMediator = false;
  
  /// SMS transaction import (too complex, error-prone)
  static const bool enableSmsImport = false;
  
  // ==========================================================================
  // DEBUG & DEVELOPMENT FLAGS
  // ==========================================================================
  
  /// Show debug information in UI
  static bool get enableDebugMode => isDevelopment;
  
  /// Enable verbose logging
  static bool get enableVerboseLogging => isDevelopment;
  
  /// Enable test data generation
  static bool get enableTestData => isDevelopment;
  
  /// Skip onboarding (for development)
  static bool get skipOnboarding => isDevelopment;
  
  // ==========================================================================
  // REMOTE CONFIG (Future Enhancement)
  // ==========================================================================
  
  /// Whether remote config is initialized
  // ignore: unused_field
  static bool _remoteConfigInitialized = false;
  
  /// Initialize remote config (Firebase Remote Config)
  /// This allows changing feature flags without app updates
  static Future<void> initRemoteConfig() async {
    // TODO: Implement Firebase Remote Config in v2.0
    // For now, just mark as initialized
    _remoteConfigInitialized = true;
  }
  
  /// Get feature flag from remote config (fallback to local value)
  static bool getRemoteFeatureFlag(String key, bool defaultValue) {
    // TODO: Implement Firebase Remote Config lookup
    // For now, return default value
    return defaultValue;
  }
  
  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================
  
  /// Check if any price-related feature is enabled
  static bool get hasPriceFeatures =>
      enablePriceIntelligence ||
      enablePriceAlerts ||
      enableEnhancedPriceFinder ||
      enableShopping;
  
  /// Check if any AI coaching feature is enabled
  static bool get hasCoachingFeatures =>
      enableCoaching ||
      enableProactiveCoaching ||
      enableCoachingTipsLibrary;
  
  /// Check if any advanced analytics is enabled
  static bool get hasAdvancedAnalytics =>
      enableEnhancedInsights ||
      enableFinancialAnalyst ||
      enableCashFlowPrediction ||
      enableHealthScore;
  
  /// Check if any export feature is enabled
  static bool get hasExportFeatures =>
      enableCsvExport ||
      enablePdfExport ||
      enableReportGenerator;
  
  /// Check if any Tier 2 feature is enabled
  static bool get hasTier2Features =>
      hasPriceFeatures ||
      enableSmartNudges ||
      enablePatternLearning ||
      hasAdvancedAnalytics ||
      enableSubscriptionDetection ||
      hasExportFeatures;
  
  /// Get list of enabled feature names (for debugging)
  static List<String> getEnabledFeatures() {
    final features = <String>[];
    
    // Tier 1 (always enabled)
    if (enableManualTransactions) features.add('Manual Transactions');
    if (enableConversationalTransactions) features.add('Conversational Input');
    if (enableReceiptScanning) features.add('Receipt Scanning');
    if (enableBudgets) features.add('Budgets');
    if (enableBasicInsights) features.add('Basic Insights');
    if (enableCoaching) features.add('AI Coaching');
    
    // Tier 2 (v2.0 features - should be empty for v1.0)
    if (enablePriceIntelligence) features.add('Price Intelligence');
    if (enableSmartNudges) features.add('Smart Nudges');
    if (enablePatternLearning) features.add('Pattern Learning');
    if (enableEnhancedInsights) features.add('Enhanced Insights');
    if (enableHealthScore) features.add('Health Score');
    if (enableSubscriptionDetection) features.add('Subscription Detection');
    
    return features;
  }
  
  /// Get list of disabled Tier 2 features (for future roadmap)
  static List<String> getDisabledTier2Features() {
    final features = <String>[];
    
    if (!enablePriceIntelligence) features.add('Price Intelligence');
    if (!enableSmartNudges) features.add('Smart Nudges');
    if (!enablePatternLearning) features.add('Pattern Learning');
    if (!enableEnhancedInsights) features.add('Enhanced Insights');
    if (!enableFinancialAnalyst) features.add('Financial Analyst');
    if (!enableCashFlowPrediction) features.add('Cash Flow Prediction');
    if (!enableHealthScore) features.add('Financial Health Score');
    if (!enableMoneyStories) features.add('Money Stories');
    if (!enableSubscriptionDetection) features.add('Subscription Detection');
    if (!enableCsvExport) features.add('CSV Export');
    if (!enablePdfExport) features.add('PDF Export');
    
    return features;
  }
  
  /// Print current configuration (for debugging)
  static void printConfig() {
    if (!kDebugMode) return;
    print('=== FinCoPilot Feature Configuration ===');
    print('Environment: $environment');
    print('Development Mode: $isDevelopment');
    print('');
    print('Enabled Features (${getEnabledFeatures().length}):');
    for (final feature in getEnabledFeatures()) {
      print('  ✅ $feature');
    }
    print('');
    print('Disabled Tier 2 Features (${getDisabledTier2Features().length}):');
    for (final feature in getDisabledTier2Features()) {
      print('  💤 $feature');
    }
    print('=========================================');
  }
}

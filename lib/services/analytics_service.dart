import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);
  
  // User Authentication Events
  static Future<void> logSignIn(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }
  
  static Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }
  
  static Future<void> logSignOut() async {
    await _analytics.logEvent(name: 'sign_out');
  }
  
  // Transaction Events
  static Future<void> logTransactionAdded({
    required String method, // 'manual', 'voice', 'receipt'
    required String category,
    required double amount,
    String? merchant,
  }) async {
    await _analytics.logEvent(
      name: 'transaction_added',
      parameters: {
        'method': method,
        'category': category,
        'amount': amount,
        'currency': 'USD', // Could be dynamic based on user preference
        if (merchant != null) 'merchant': merchant,
      },
    );
  }
  
  static Future<void> logTransactionEdited({
    required String category,
    required double amount,
  }) async {
    await _analytics.logEvent(
      name: 'transaction_edited',
      parameters: {
        'category': category,
        'amount': amount,
      },
    );
  }
  
  static Future<void> logTransactionDeleted({
    required String category,
    required double amount,
  }) async {
    await _analytics.logEvent(
      name: 'transaction_deleted',
      parameters: {
        'category': category,
        'amount': amount,
      },
    );
  }
  
  // Voice Input Events
  static Future<void> logVoiceInputUsed({
    required bool success,
    String? recognizedText,
  }) async {
    await _analytics.logEvent(
      name: 'voice_input_used',
      parameters: {
        'success': success,
        if (recognizedText != null) 'text_length': recognizedText.length,
      },
    );
  }
  
  static Future<void> logVoiceInputError(String error) async {
    await _analytics.logEvent(
      name: 'voice_input_error',
      parameters: {
        'error_type': error,
      },
    );
  }
  
  // Receipt Processing Events
  static Future<void> logReceiptScanned({
    required bool success,
    String? errorMessage,
  }) async {
    await _analytics.logEvent(
      name: 'receipt_scanned',
      parameters: {
        'success': success,
        if (errorMessage != null) 'error_message': errorMessage,
      },
    );
  }
  
  static Future<void> logReceiptProcessed({
    required bool success,
    int? extractedFields,
  }) async {
    await _analytics.logEvent(
      name: 'receipt_processed',
      parameters: {
        'success': success,
        if (extractedFields != null) 'extracted_fields': extractedFields,
      },
    );
  }
  
  // Analytics & Insights Events
  static Future<void> logInsightsViewed() async {
    await _analytics.logEvent(name: 'insights_viewed');
  }
  
  static Future<void> logAIInsightsGenerated({
    required bool success,
    String? insightType,
  }) async {
    await _analytics.logEvent(
      name: 'ai_insights_generated',
      parameters: {
        'success': success,
        if (insightType != null) 'insight_type': insightType,
      },
    );
  }
  
  static Future<void> logChartViewed(String chartType) async {
    await _analytics.logEvent(
      name: 'chart_viewed',
      parameters: {
        'chart_type': chartType, // 'pie', 'bar', 'line'
      },
    );
  }
  
  // AI Orchestrator Events
  static Future<void> logAIOrchestratorUsed({
    required String intent,
    required bool success,
    String? agent,
  }) async {
    await _analytics.logEvent(
      name: 'ai_orchestrator_used',
      parameters: {
        'intent': intent,
        'success': success,
        if (agent != null) 'routed_agent': agent,
      },
    );
  }
  
  static Future<void> logAIQueryProcessed({
    required String query,
    required String intent,
    required bool success,
  }) async {
    await _analytics.logEvent(
      name: 'ai_query_processed',
      parameters: {
        'query_length': query.length,
        'intent': intent,
        'success': success,
      },
    );
  }
  
  // User Engagement Events
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
  
  static Future<void> logFeatureUsed(String featureName) async {
    await _analytics.logEvent(
      name: 'feature_used',
      parameters: {
        'feature_name': featureName,
      },
    );
  }
  
  static Future<void> logOnboardingCompleted() async {
    await _analytics.logEvent(name: 'onboarding_completed');
  }
  
  static Future<void> logCurrencyChanged({
    required String fromCurrency,
    required String toCurrency,
  }) async {
    await _analytics.logEvent(
      name: 'currency_changed',
      parameters: {
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
      },
    );
  }
  
  // Performance Events
  static Future<void> logPerformanceEvent({
    required String eventName,
    required int durationMs,
  }) async {
    await _analytics.logEvent(
      name: 'performance_event',
      parameters: {
        'event_name': eventName,
        'duration_ms': durationMs,
      },
    );
  }
  
  // Error Events
  static Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screenName,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }
  
  // User Properties
  static Future<void> setUserProperties({
    String? userId,
    String? currency,
    String? language,
    int? transactionCount,
  }) async {
    if (userId != null) {
      await _analytics.setUserId(id: userId);
    }
    
    if (currency != null) {
      await _analytics.setUserProperty(name: 'preferred_currency', value: currency);
    }
    
    if (language != null) {
      await _analytics.setUserProperty(name: 'preferred_language', value: language);
    }
    
    if (transactionCount != null) {
      await _analytics.setUserProperty(name: 'transaction_count_range', value: _getTransactionCountRange(transactionCount));
    }
  }
  
  // Helper method to categorize transaction counts
  static String _getTransactionCountRange(int count) {
    if (count == 0) return '0';
    if (count <= 10) return '1-10';
    if (count <= 50) return '11-50';
    if (count <= 100) return '51-100';
    if (count <= 500) return '101-500';
    return '500+';
  }
  
  // Enable/Disable Analytics Collection
  static Future<void> setAnalyticsEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }
}
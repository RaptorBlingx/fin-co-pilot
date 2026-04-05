import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/auth_state_notifier.dart';
import 'services/preferences_service.dart';
import 'services/connectivity_service.dart';

import 'services/budget_monitoring_service.dart';
import 'services/coaching_service.dart';
import 'services/price_alert_service.dart';
import 'services/app_initializer.dart';
import 'core/constants/app_constants.dart';
import 'core/config/features_config.dart';

import 'core/theme/theme_provider.dart';

import 'features/auth/presentation/screens/sign_in_screen.dart';
import 'features/onboarding/presentation/screens/welcome_screen.dart';
import 'features/onboarding/presentation/screens/currency_setup_screen.dart';
import 'features/onboarding/presentation/screens/complete_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/coaching/presentation/screens/unified_coach_screen.dart';
import 'features/shopping/presentation/screens/shopping_screen.dart';
import 'features/reports/presentation/screens/reports_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/settings/presentation/screens/notification_settings_screen.dart';
import 'features/receipts/screens/receipt_capture_screen.dart';
import 'features/health_score/screens/health_score_screen.dart';
import 'features/subscriptions/screens/subscriptions_screen.dart';
import 'features/transactions/presentation/screens/manual_transaction_screen.dart';
// REMOVED: import 'features/receipts/screens/price_watchlist_screen.dart'; // Tier 2 - V2.0 feature
import 'core/navigation/app_navigation.dart';

// Riverpod provider for theme management
final themeProvider = ChangeNotifierProvider<ThemeProvider>((ref) {
  return ThemeProvider();
});

// Global auth state notifier (initialized after Firebase)
late final AuthStateNotifier _authStateNotifier;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge immersive system UI
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence (cached reads + queued writes)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Start connectivity monitoring
  ConnectivityService().init();

  // Initialize SharedPreferences
  await PreferencesService.init();
  
  // Initialize auth state notifier
  _authStateNotifier = AuthStateNotifier(AuthService());

  // Initialize App Services (includes Notification Service, SMS Listener)
  await AppInitializer().initialize();

  // Initialize Price Alert Service (Tier 2 — only if enabled)
  if (FeaturesConfig.enablePriceAlerts) {
    await PriceAlertService().initialize();
  }

  // Setup periodic monitoring
  _setupPeriodicTasks();
  
  // Setup Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(
    ProviderScope(
      child: const FinCopilotApp(),
    ),
  );
}

/// Setup periodic background tasks
void _setupPeriodicTasks() {
  final budgetMonitoring = BudgetMonitoringService();
  final coachingService = CoachingService();

  // Check budget alerts every hour
  budgetMonitoring.checkBudgetAlerts();
  budgetMonitoring.checkSpendingMilestones();

  // Send daily coaching tip
  coachingService.sendDailyCoachingTip();

  // Price alerts — only if enabled (Tier 2)
  if (FeaturesConfig.enablePriceAlerts) {
    final priceAlertService = PriceAlertService();
    priceAlertService.checkAllPriceAlerts();
  }
}

class FinCopilotApp extends ConsumerWidget {
  const FinCopilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Fin Copilot',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.lightTheme,
      darkTheme: themeNotifier.darkTheme,
      themeMode: themeNotifier.themeMode,
      routerConfig: _router,
    );
  }
}

// Router configuration with auth state management
final _router = GoRouter(
  initialLocation: AppConstants.routeSignIn,
  refreshListenable: _authStateNotifier, // Listen to auth changes
  redirect: (context, state) {
    final isLoggedIn = _authStateNotifier.isLoggedIn;
    final isOnboardingComplete = PreferencesService.isOnboardingComplete();
    
    if (kDebugMode) {
      print('🔄 ROUTER: location=${state.matchedLocation}, isLoggedIn=$isLoggedIn, onboarding=$isOnboardingComplete');
    }
    
    // If not logged in, go to sign in
    if (!isLoggedIn) {
      return AppConstants.routeSignIn;
    }
    
    // If logged in and onboarding complete, redirect away from onboarding/sign-in to dashboard
    if (isOnboardingComplete && 
        (state.matchedLocation.startsWith('/onboarding') || state.matchedLocation == AppConstants.routeSignIn)) {
      return AppConstants.routeDashboard;
    }
    
    // If logged in but onboarding not complete, go to onboarding
    if (!isOnboardingComplete && !state.matchedLocation.startsWith('/onboarding')) {
      return AppConstants.routeOnboarding;
    }
    
    // If logged in and onboarding complete, allow navigation
    return null;
  },
  routes: [
    GoRoute(
      path: AppConstants.routeSignIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: AppConstants.routeOnboarding,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/onboarding/currency',
      builder: (context, state) => const CurrencySetupScreen(),
    ),
    GoRoute(
      path: '/onboarding/complete',
      builder: (context, state) => const OnboardingCompleteScreen(),
    ),
    GoRoute(
      path: AppConstants.routeDashboard,
      builder: (context, state) => const AppNavigation(),
    ),
    GoRoute(
      path: AppConstants.routeSettings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppConstants.routeCoaching,
      builder: (context, state) => const UnifiedCoachScreen(),
    ),
    // Shopping route — Tier 2, only registered if enabled
    if (FeaturesConfig.enableShopping)
      GoRoute(
        path: AppConstants.routeShopping,
        builder: (context, state) => const ShoppingScreen(),
      ),
    GoRoute(
      path: AppConstants.routeReports,
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: AppConstants.routeNotifications,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: AppConstants.routeNotificationSettings,
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: AppConstants.routeReceiptCapture,
      builder: (context, state) => const ReceiptCaptureScreen(),
    ),
    GoRoute(
      path: AppConstants.routeHealthScore,
      builder: (context, state) => const HealthScoreScreen(),
    ),
    // coaching-tips route now handled by unified Coach screen
    GoRoute(
      path: AppConstants.routeCoachingTips,
      builder: (context, state) => const UnifiedCoachScreen(),
    ),
    GoRoute(
      path: AppConstants.routeSubscriptions,
      builder: (context, state) => const SubscriptionsScreen(),
    ),
    GoRoute(
      path: AppConstants.routeAddTransaction,
      builder: (context, state) => const ManualTransactionScreen(),
    ),
    // REMOVED: routeWatchlist - Tier 2 V2.0 feature (Price Intelligence)
  ],
);



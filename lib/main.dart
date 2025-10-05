import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/preferences_service.dart';
import 'services/notification_service.dart';
import 'services/budget_monitoring_service.dart';
import 'services/coaching_service.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/presentation/screens/sign_in_screen.dart';
import 'features/onboarding/presentation/screens/welcome_screen.dart';
import 'features/onboarding/presentation/screens/currency_setup_screen.dart';
import 'features/onboarding/presentation/screens/complete_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/coaching/presentation/screens/coaching_screen.dart';
import 'features/shopping/presentation/screens/shopping_screen.dart';
import 'features/reports/presentation/screens/reports_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/settings/presentation/screens/notification_settings_screen.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize SharedPreferences
  await PreferencesService.init();
  
  // Initialize Notification Service
  await NotificationService().initialize();
  
  // Setup periodic monitoring
  _setupPeriodicTasks();
  
  // Setup Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(const FinCopilotApp());
}

/// Setup periodic background tasks
void _setupPeriodicTasks() {
  final budgetMonitoring = BudgetMonitoringService();
  final coachingService = CoachingService();
  
  // Check budget alerts every hour
  // In production, this would be handled by cloud functions or background tasks
  // For demo purposes, we'll check when the app starts
  budgetMonitoring.checkBudgetAlerts();
  budgetMonitoring.checkSpendingMilestones();
  
  // Send daily coaching tip
  coachingService.sendDailyCoachingTip();
}

class FinCopilotApp extends StatefulWidget {
  const FinCopilotApp({super.key});

  @override
  State<FinCopilotApp> createState() => _FinCopilotAppState();
}

class _FinCopilotAppState extends State<FinCopilotApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}

// Router configuration
final _router = GoRouter(
  initialLocation: AppConstants.routeSignIn,
  redirect: (context, state) {
    final authService = AuthService();
    final isLoggedIn = authService.currentUser != null;
    final isOnboardingComplete = PreferencesService.isOnboardingComplete();
    
    // If not logged in, go to sign in
    if (!isLoggedIn) {
      return AppConstants.routeSignIn;
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
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppConstants.routeSettings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppConstants.routeCoaching,
      builder: (context, state) => const CoachingScreen(),
    ),
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
  ],
);



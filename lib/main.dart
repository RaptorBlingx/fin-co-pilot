import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/preferences_service.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/presentation/screens/sign_in_screen.dart';
import 'features/onboarding/presentation/screens/welcome_screen.dart';
import 'features/onboarding/presentation/screens/currency_setup_screen.dart';
import 'features/onboarding/presentation/screens/complete_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/coaching/presentation/screens/coaching_screen.dart';
import 'features/shopping/presentation/screens/shopping_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize SharedPreferences
  await PreferencesService.init();
  
  // Setup Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(const FinCopilotApp());
}

class FinCopilotApp extends StatelessWidget {
  const FinCopilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
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
  ],
);



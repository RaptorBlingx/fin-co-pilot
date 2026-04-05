import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics_service.dart';
import 'notification_service.dart';
import 'budget_monitoring_service.dart';
import 'preferences_service.dart';
import 'dart:io' show Platform;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Check if user document exists (edge case: user deleted from Firestore but auth exists)
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      final isReturningUser = userDoc.exists;
      final hasCompletedOnboarding = isReturningUser && (userDoc.data()?['onboarding_complete'] == true);
      
      if (!isReturningUser) {
        print('⚠️ AUTH: Email sign-in but no Firestore doc (recreating)');
        await _createUserDocument(userCredential.user!);
        print('🔄 AUTH: Setting onboarding flag = FALSE');
        await PreferencesService.setOnboardingComplete(false);
      } else if (!hasCompletedOnboarding) {
        print('⚠️ AUTH: Email sign-in but onboarding NOT complete in Firestore');
        print('🔄 AUTH: Setting onboarding flag = FALSE');
        await PreferencesService.setOnboardingComplete(false);
      } else {
        print('🔍 AUTH: Email sign-in, returning user with completed onboarding');
        await PreferencesService.setOnboardingComplete(true);
      }
      
      // Track analytics
      await AnalyticsService.logSignIn('email');
      await AnalyticsService.setUserProperties(userId: userCredential.user?.uid);
      
      // Initialize notifications after successful login
      await _initializeNotificationsForUser(userCredential.user!);
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('🆕 AUTH: New email sign-up');
      
      // Track analytics
      await AnalyticsService.logSignUp('email');
      await AnalyticsService.setUserProperties(userId: credential.user?.uid);
      
      // Create user document in Firestore
      if (credential.user != null) {
        await _createUserDocument(credential.user!);
        // Initialize notifications for new user
        await _initializeNotificationsForUser(credential.user!);
      }
      
      // CRITICAL: Reset onboarding flag for new users
      print('🔄 AUTH: Resetting onboarding flag to false for new email user');
      await PreferencesService.setOnboardingComplete(false);
      
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign in aborted');
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Check if user document exists in Firestore (reliable way to detect returning users)
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      final isReturningUser = userDoc.exists;
      final hasCompletedOnboarding = isReturningUser && (userDoc.data()?['onboarding_complete'] == true);
      
      // Track analytics
      if (!isReturningUser) {
        print('🆕 AUTH: New Google user (no Firestore doc), creating user document');
        await AnalyticsService.logSignUp('google');
        await _createUserDocument(userCredential.user!);
        // CRITICAL: Reset onboarding flag for new users (clears old cached value)
        print('🔄 AUTH: New user → Setting onboarding flag = FALSE');
        await PreferencesService.setOnboardingComplete(false);
      } else if (!hasCompletedOnboarding) {
        print('⚠️ AUTH: Returning Google user but onboarding NOT complete in Firestore');
        await AnalyticsService.logSignIn('google');
        print('🔄 AUTH: Onboarding incomplete → Setting flag = FALSE');
        await PreferencesService.setOnboardingComplete(false);
      } else {
        print('🔍 AUTH: Returning Google user with completed onboarding');
        await AnalyticsService.logSignIn('google');
        // Set onboarding complete for returning users
        print('✅ AUTH: Returning user → Setting onboarding flag = TRUE');
        await PreferencesService.setOnboardingComplete(true);
      }
      
      // Set user properties
      await AnalyticsService.setUserProperties(userId: userCredential.user?.uid);
      
      // Initialize notifications after successful login
      await _initializeNotificationsForUser(userCredential.user!);
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Apple (iOS only)
  Future<UserCredential> signInWithApple() async {
    try {
      if (!Platform.isIOS) {
        throw Exception('Apple Sign In is only available on iOS');
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      
      // Create user document if first time
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(userCredential.user!);
      }
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in anonymously (for testing/demo)
  Future<UserCredential> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      
      // Create basic user document for anonymous users
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        await _createUserDocument(userCredential.user!);
      }
      
      // Initialize notifications
      await _initializeNotificationsForUser(userCredential.user!);
      
      // Existing anonymous users skip onboarding
      if (!isNewUser) {
        await PreferencesService.setOnboardingComplete(true);
      }
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    
    await userDoc.set({
      'uid': user.uid,
      'email': user.email,
      'display_name': user.displayName ?? '',
      'avatar_url': user.photoURL ?? '',
      'created_at': FieldValue.serverTimestamp(),
      'last_login': FieldValue.serverTimestamp(),
      
      // Onboarding status (CRITICAL: must be false for new users)
      'onboarding_complete': false,
      
      // Default preferences (will be updated during onboarding)
      'device_locale': Platform.localeName,
      'country_code': '',
      'currency_preference': '',
      'language_preference': '',
      
      // Subscription
      'subscription_tier': 'free',
      'total_transactions': 0,
      
      // Analytics consent
      'analytics_consent': true,
    });
  }

  // Update user preferences after onboarding
  Future<void> updateUserPreferences({
    required String userId,
    required String currency,
    required String language,
    required String countryCode,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'currency_preference': currency,
      'language_preference': language,
      'country_code': countryCode,
    });
  }

  // Initialize notifications for user after login
  Future<void> _initializeNotificationsForUser(User user) async {
    try {
      final notificationService = NotificationService();
      final budgetMonitoring = BudgetMonitoringService();
      
      // Save FCM token to Firestore
      if (notificationService.fcmToken != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': notificationService.fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
      
      // Check for immediate budget alerts
      await budgetMonitoring.checkBudgetAlerts();
      
      // Check for spending milestones
      await budgetMonitoring.checkSpendingMilestones();
      
      print('Notifications initialized for user: ${user.uid}');
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Track analytics before signing out
    await AnalyticsService.logSignOut();
    
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
}
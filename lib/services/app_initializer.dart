import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// REMOVED: import 'sms/sms_listener_service.dart'; // Tier 3 - Deleted
import 'notification_service.dart';

/// App Initializer Service
///
/// Handles app-wide initialization tasks on startup:
/// - SMS listener service (Week 2)
/// - Notification service
/// - User-specific services
///
/// Called once on app startup after Firebase initialization
class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  factory AppInitializer() => _instance;
  AppInitializer._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // REMOVED: final SmsListenerService _smsService = SmsListenerService(); // Tier 3 - Deleted
  final NotificationService _notificationService = NotificationService();

  bool _isInitialized = false;

  /// Initialize all app services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('AppInitializer: Starting initialization...');

      // Initialize notification service
      await _notificationService.initialize();
      print('AppInitializer: Notification service initialized');

      // Listen for auth state changes
      _auth.authStateChanges().listen(_onAuthStateChanged);
      print('AppInitializer: Auth listener registered');

      // Initialize for current user if logged in
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _initializeForUser(currentUser);
      }

      _isInitialized = true;
      print('AppInitializer: Initialization complete');
    } catch (e) {
      print('AppInitializer: Error during initialization: $e');
    }
  }

  /// Handle auth state changes
  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      print('AppInitializer: User signed in: ${user.uid}');
      await _initializeForUser(user);
    } else {
      print('AppInitializer: User signed out');
      await _cleanupForUser();
    }
  }

  /// Initialize user-specific services
  Future<void> _initializeForUser(User user) async {
    try {
      // Get user preferences from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        print('AppInitializer: User document not found');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Check if SMS parsing is enabled
      final smsEnabled = userData['preferences']?['smsParsingEnabled'] as bool? ?? false;
      final smsPermissionGranted = userData['onboarding']?['smsPermissionGranted'] as bool? ?? false;

      if (smsEnabled && smsPermissionGranted) {
        print('AppInitializer: SMS parsing disabled - Tier 3 feature removed');
        // COMMENTED OUT: await _initializeSmsListener(user.uid);
      } else {
        print('AppInitializer: SMS parsing disabled or permission not granted');
      }
    } catch (e) {
      print('AppInitializer: Error initializing for user: $e');
    }
  }

  /*
  // COMMENTED OUT: SMS listener initialization - Tier 3 deleted
  /// Initialize SMS listener service
  Future<void> _initializeSmsListener(String userId) async {
    try {
      // Check if permissions are granted
      final hasPermissions = await _smsService.hasPermissions();

      if (!hasPermissions) {
        print('AppInitializer: SMS permissions not granted');
        return;
      }

      // Initialize SMS listener
      final success = await _smsService.initialize(userId);

      if (success) {
        print('AppInitializer: SMS listener started successfully');
      } else {
        print('AppInitializer: Failed to start SMS listener');
      }
    } catch (e) {
      print('AppInitializer: Error initializing SMS listener: $e');
    }
  }
  */

  /// Cleanup user-specific services on sign out
  Future<void> _cleanupForUser() async {
    try {
      // COMMENTED OUT: Stop SMS listener - Tier 3 deleted
      // await _smsService.stopListening();
      print('AppInitializer: User cleanup completed (SMS listener disabled)');
    } catch (e) {
      print('AppInitializer: Error during cleanup: $e');
    }
  }

  /// Enable SMS auto-parsing for current user
  /// Called when user grants permission in onboarding or settings
  Future<bool> enableSmsAutoParsing() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Update user preferences
      await _firestore.collection('users').doc(user.uid).update({
        'preferences.smsParsingEnabled': true,
        'onboarding.smsPermissionGranted': true,
      });

      // COMMENTED OUT: Initialize SMS listener - Tier 3 deleted
      // await _initializeSmsListener(user.uid);

      return true;
    } catch (e) {
      print('AppInitializer: Error enabling SMS auto-parsing: $e');
      return false;
    }
  }

  /// Disable SMS auto-parsing for current user
  Future<bool> disableSmsAutoParsing() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // COMMENTED OUT: Stop SMS listener - Tier 3 deleted
      // await _smsService.stopListening();

      // Update user preferences
      await _firestore.collection('users').doc(user.uid).update({
        'preferences.smsParsingEnabled': false,
      });

      return true;
    } catch (e) {
      print('AppInitializer: Error disabling SMS auto-parsing: $e');
      return false;
    }
  }

  /// Check if SMS auto-parsing is enabled
  Future<bool> isSmsAutoParsingEnabled() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['preferences']?['smsParsingEnabled'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get singleton instance
  bool get isInitialized => _isInitialized;
}

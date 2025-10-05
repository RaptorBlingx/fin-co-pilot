import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Background message handler (must be top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;
  String? _fcmToken;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Request permissions
      await _requestPermissions();

      // Get FCM token
      await _getFCMToken();

      // Set up message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      if (kDebugMode) {
        print('NotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing NotificationService: $e');
      }
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final List<AndroidNotificationChannel> channels = [
      const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
      const AndroidNotificationChannel(
        'budget_alerts',
        'Budget Alerts',
        description: 'Notifications for budget warnings and overages.',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
      const AndroidNotificationChannel(
        'coaching_tips',
        'Financial Coaching Tips',
        description: 'Daily tips and advice for better financial management.',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        'price_alerts',
        'Price Drop Alerts',
        description: 'Notifications for price drops on tracked items.',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'milestones',
        'Spending Milestones',
        description: 'Achievements and milestone notifications.',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Configure foreground notification presentation options for iOS
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Request FCM permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // Request local notification permissions for Android 13+
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $_fcmToken');
      }

      // Save token to user document
      final user = _auth.currentUser;
      if (user != null && _fcmToken != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': _fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle app launch from notification
    _handleAppLaunchFromNotification();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _updateFCMToken(newToken);
    });
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Received foreground message: ${message.messageId}');
    }

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      final String channelId = _getChannelId(data['type'] ?? 'default');
      
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _getChannelName(channelId),
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(data),
      );
    }
  }

  /// Get notification channel ID based on type
  String _getChannelId(String type) {
    switch (type) {
      case 'budget_alert':
        return 'budget_alerts';
      case 'coaching_tip':
        return 'coaching_tips';
      case 'price_alert':
        return 'price_alerts';
      case 'milestone':
        return 'milestones';
      default:
        return 'high_importance_channel';
    }
  }

  /// Get channel name based on channel ID
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'budget_alerts':
        return 'Budget Alerts';
      case 'coaching_tips':
        return 'Financial Coaching Tips';
      case 'price_alerts':
        return 'Price Drop Alerts';
      case 'milestones':
        return 'Spending Milestones';
      default:
        return 'High Importance Notifications';
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final Map<String, dynamic> data = jsonDecode(response.payload!);
      _handleNotificationAction(data);
    }
  }

  /// Handle notification tap from Firebase messaging
  void _handleNotificationTap(RemoteMessage message) {
    _handleNotificationAction(message.data);
  }

  /// Handle app launch from notification
  Future<void> _handleAppLaunchFromNotification() async {
    final RemoteMessage? message = await _messaging.getInitialMessage();
    if (message != null) {
      _handleNotificationAction(message.data);
    }
  }

  /// Handle notification action based on data
  void _handleNotificationAction(Map<String, dynamic> data) {
    final String? action = data['action'];
    
    switch (action) {
      case 'open_budget':
        // Navigate to budget screen
        // NavigationService.navigateTo('/budgets');
        break;
      case 'open_coaching':
        // Navigate to coaching screen
        // NavigationService.navigateTo('/coaching');
        break;
      case 'open_price_alerts':
        // Navigate to price alerts screen
        // NavigationService.navigateTo('/price-alerts');
        break;
      case 'open_achievements':
        // Navigate to achievements screen
        // NavigationService.navigateTo('/achievements');
        break;
      default:
        // Navigate to home screen
        // NavigationService.navigateTo('/home');
        break;
    }
  }

  /// Update FCM token in Firestore
  Future<void> _updateFCMToken(String newToken) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating FCM token: $e');
      }
    }
  }

  /// Send budget alert notification
  Future<void> sendBudgetAlert({
    required String title,
    required String body,
    required String category,
    required double amount,
    required double budgetLimit,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'type': 'budget_alert',
        'title': title,
        'body': body,
        'data': {
          'category': category,
          'amount': amount,
          'budgetLimit': budgetLimit,
          'action': 'open_budget',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error sending budget alert: $e');
      }
    }
  }

  /// Send coaching tip notification
  Future<void> sendCoachingTip({
    required String title,
    required String body,
    required String tipCategory,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'type': 'coaching_tip',
        'title': title,
        'body': body,
        'data': {
          'tipCategory': tipCategory,
          'action': 'open_coaching',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error sending coaching tip: $e');
      }
    }
  }

  /// Send price drop alert
  Future<void> sendPriceAlert({
    required String title,
    required String body,
    required String itemName,
    required double oldPrice,
    required double newPrice,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'type': 'price_alert',
        'title': title,
        'body': body,
        'data': {
          'itemName': itemName,
          'oldPrice': oldPrice,
          'newPrice': newPrice,
          'action': 'open_price_alerts',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error sending price alert: $e');
      }
    }
  }

  /// Send milestone achievement notification
  Future<void> sendMilestoneNotification({
    required String title,
    required String body,
    required String milestoneType,
    required Map<String, dynamic> achievementData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'type': 'milestone',
        'title': title,
        'body': body,
        'data': {
          'milestoneType': milestoneType,
          'achievementData': achievementData,
          'action': 'open_achievements',
        },
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error sending milestone notification: $e');
      }
    }
  }

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}
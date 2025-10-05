# 🔔 Push Notifications Setup Guide

## Required Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies...
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.2
  timezone: ^0.9.2

dev_dependencies:
  # Existing dev dependencies...
```

## Platform Configuration

### Android Setup (`android/app/src/main/AndroidManifest.xml`)

Add these permissions and configurations:

```xml
<!-- Notification permissions -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.WAKE_LOCK" />

<!-- Inside <application> tag -->
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

### iOS Setup (`ios/Runner/AppDelegate.swift`)

Add notification handling:

```swift
import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Request notification permissions
    UNUserNotificationCenter.current().delegate = self
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Integration Steps

1. **Initialize in main.dart:**
```dart
import 'services/coaching_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize notification service
  await CoachingNotificationService().initialize();
  
  runApp(const MyApp());
}
```

2. **Request permissions on first launch:**
```dart
// In your app's initialization or settings screen
final notificationService = CoachingNotificationService();
await notificationService.initialize();
```

3. **Configure notification preferences:**
```dart
await notificationService.updateNotificationPreferences(
  weeklyCoaching: true,
  dailyReminders: false,
  highPriorityAlerts: true,
  milestoneNotifications: true,
  reminderHour: 9,
  reminderMinute: 0,
);
```

## Notification Types

### 🎯 Weekly Coaching (Mondays at 9 AM)
- Automatically generates new coaching tips
- Personalized based on spending patterns
- High-priority alerts for urgent financial insights

### 💡 Daily Reminders (Optional)
- Configurable time
- Gentle nudges for financial habits
- Budget tracking reminders

### 🚨 High Priority Alerts
- Immediate notifications for critical insights
- Overspending warnings
- Unusual activity detection

### 🎉 Milestone Notifications
- Goal achievements
- Streak celebrations
- Progress milestones

## Usage Examples

```dart
final notificationService = CoachingNotificationService();

// Send high priority tip
await notificationService.sendHighPriorityNotification(tip);

// Send milestone achievement
await notificationService.sendMilestoneNotification(
  milestone: 'Savings Goal',
  message: 'You\'ve saved \$1,000 this month!',
);

// Schedule daily reminder
await notificationService.scheduleDailyReminder(
  hour: 19,
  minute: 0,
  message: 'Don\'t forget to log today\'s expenses!',
);
```

## Testing

1. **Local Notifications:**
   - Test weekly scheduling
   - Verify notification tapping
   - Check notification preferences

2. **Firebase Cloud Messaging:**
   - Set up FCM console project
   - Test token registration
   - Send test messages

3. **Background Processing:**
   - Test notification generation when app is closed
   - Verify scheduled notifications trigger correctly
   - Test notification action handling

## Security & Privacy

- FCM tokens are securely stored in Firestore
- Notification preferences are user-configurable
- No sensitive financial data in notification content
- All notifications respect user privacy settings

## Error Handling

The service includes comprehensive error handling for:
- Permission denied scenarios
- Network connectivity issues
- Firebase service unavailability
- Local notification scheduling failures

## Production Considerations

1. **Notification Channels:** Configure proper Android notification channels
2. **Rate Limiting:** Implement notification frequency limits
3. **User Preferences:** Provide granular notification controls
4. **Testing:** Thoroughly test on different devices and OS versions
5. **Analytics:** Track notification engagement metrics
import 'package:cloud_firestore/cloud_firestore.dart';

/// Push notifications log
///
/// Per DATA_MODELS.md specification:
/// Tracks all push notifications sent to users.
/// Supports read/unread status and optional actions.
///
/// Features:
/// - Multiple notification types
/// - Priority levels
/// - Optional CTAs
/// - Read status tracking
/// - Auto-expiration
/// - NEW v3: 'money_story' notification type for daily 9 PM stories
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationPriority priority;

  final String title;
  final String body;

  /// Additional data (type-specific)
  final Map<String, dynamic>? data;

  /// Optional call-to-action
  final NotificationAction? action;

  /// Read status
  final bool read;
  final DateTime? readAt;

  final DateTime sentAt;

  /// Optional expiration timestamp
  final DateTime? expiresAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    this.data,
    this.action,
    required this.read,
    this.readAt,
    required this.sentAt,
    this.expiresAt,
  });

  /// Create from Firestore document
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: (data['user_id'] ?? data['userId']) as String,
      type: NotificationType.values.byName(data['type'] as String),
      priority: NotificationPriority.values.byName(data['priority'] as String),
      title: data['title'] as String,
      body: data['body'] as String,
      data: data['data'] != null
          ? Map<String, dynamic>.from(data['data'])
          : null,
      action: data['action'] != null
          ? NotificationAction.fromMap(data['action'] as Map<String, dynamic>)
          : null,
      read: data['read'] as bool,
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'type': type.name,
      'priority': priority.name,
      'title': title,
      'body': body,
      'data': data,
      'action': action?.toMap(),
      'read': read,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'sentAt': Timestamp.fromDate(sentAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  /// Check if notification is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if notification is unread
  bool get isUnread => !read;

  /// Check if notification is active (unread and not expired)
  bool get isActive => isUnread && !isExpired;

  /// Mark as read
  AppNotification markAsRead() {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      priority: priority,
      title: title,
      body: body,
      data: data,
      action: action,
      read: true,
      readAt: DateTime.now(),
      sentAt: sentAt,
      expiresAt: expiresAt,
    );
  }

  /// Get age in hours
  int get ageInHours => DateTime.now().difference(sentAt).inHours;

  /// Get age in days
  int get ageInDays => DateTime.now().difference(sentAt).inDays;
}

/// Notification action (CTA)
class NotificationAction {
  final String label;
  final String target;

  NotificationAction({
    required this.label,
    required this.target,
  });

  factory NotificationAction.fromMap(Map<String, dynamic> map) {
    return NotificationAction(
      label: map['label'] as String,
      target: map['target'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'target': target,
    };
  }
}

/// Notification type
enum NotificationType {
  /// NEW v3: Daily Money Story notification (9 PM)
  moneyStory('money_story'),

  /// Budget alerts (over threshold, approaching limit)
  budget('budget'),

  /// Subscription reminders (renewal, cancellation suggestion)
  subscription('subscription'),

  /// Smart nudges (proactive warnings)
  nudge('nudge'),

  /// Couples dashboard notifications (invites, disconnections)
  couples('couples'),

  /// System notifications (updates, tips)
  system('system');

  final String value;
  const NotificationType(this.value);
}

/// Notification priority
enum NotificationPriority {
  high,
  medium,
  low,
}

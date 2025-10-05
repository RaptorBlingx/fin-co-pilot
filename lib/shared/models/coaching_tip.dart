import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoachingTip {
  final String id;
  final String userId;
  final String type; // encouragement, warning, suggestion, milestone, challenge
  final String priority; // high, medium, low
  final String title;
  final String message;
  final bool actionable; // Does this tip have a specific action?
  final String? actionText; // The action to take
  final DateTime createdAt;
  final bool read;
  final bool dismissed;

  CoachingTip({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.actionable,
    this.actionText,
    required this.createdAt,
    this.read = false,
    this.dismissed = false,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type,
      'priority': priority,
      'title': title,
      'message': message,
      'actionable': actionable,
      'action_text': actionText,
      'created_at': Timestamp.fromDate(createdAt),
      'read': read,
      'dismissed': dismissed,
    };
  }

  // Create from Firestore map
  factory CoachingTip.fromMap(Map<String, dynamic> map, String id) {
    return CoachingTip(
      id: id,
      userId: map['user_id'] ?? '',
      type: map['type'] ?? 'suggestion',
      priority: map['priority'] ?? 'medium',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      actionable: map['actionable'] ?? false,
      actionText: map['action_text'],
      createdAt: (map['created_at'] as Timestamp).toDate(),
      read: map['read'] ?? false,
      dismissed: map['dismissed'] ?? false,
    );
  }

  // Copy with method
  CoachingTip copyWith({
    String? id,
    String? userId,
    String? type,
    String? priority,
    String? title,
    String? message,
    bool? actionable,
    String? actionText,
    DateTime? createdAt,
    bool? read,
    bool? dismissed,
  }) {
    return CoachingTip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      actionable: actionable ?? this.actionable,
      actionText: actionText ?? this.actionText,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      dismissed: dismissed ?? this.dismissed,
    );
  }

  // UI Helper Getters
  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'encouragement':
        return '🎉';
      case 'warning':
        return '⚠️';
      case 'suggestion':
        return '💡';
      case 'milestone':
        return '🏆';
      case 'challenge':
        return '🎯';
      case 'welcome':
        return '👋';
      default:
        return '📌';
    }
  }

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFFF5722);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'low':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  bool get isNew => !read;

  bool get hasAction => actionable && actionText != null && actionText!.isNotEmpty;
}
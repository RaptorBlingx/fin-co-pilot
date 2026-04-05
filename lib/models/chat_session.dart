import 'package:cloud_firestore/cloud_firestore.dart';

/// A single chat session (conversation thread).
/// Stored at `users/{uid}/chat_sessions/{sessionId}`.
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
    'message_count': messageCount,
  };

  factory ChatSession.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatSession(
      id: id,
      title: data['title'] as String? ?? 'New Chat',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageCount: data['message_count'] as int? ?? 0,
    );
  }
}

/// A single message within a chat session.
/// Stored at `users/{uid}/chat_sessions/{sessionId}/messages/{messageId}`.
class ChatSessionMessage {
  final String? id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Map<String, dynamic>>? quickActions;

  const ChatSessionMessage({
    this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickActions,
  });

  Map<String, dynamic> toFirestore() => {
    'text': text,
    'is_user': isUser,
    'timestamp': Timestamp.fromDate(timestamp),
    if (quickActions != null) 'quick_actions': quickActions,
  };

  factory ChatSessionMessage.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatSessionMessage(
      id: id,
      text: data['text'] as String? ?? '',
      isUser: data['is_user'] as bool? ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      quickActions: (data['quick_actions'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}

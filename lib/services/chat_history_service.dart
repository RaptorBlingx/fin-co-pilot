import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_session.dart';

/// CRUD service for persistent chat sessions & messages.
///
/// Firestore structure:
///   users/{uid}/chat_sessions/{sessionId}
///   users/{uid}/chat_sessions/{sessionId}/messages/{messageId}
class ChatHistoryService {
  final FirebaseFirestore _firestore;

  ChatHistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessionsCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('chat_sessions');

  CollectionReference<Map<String, dynamic>> _messagesCol(
          String userId, String sessionId) =>
      _sessionsCol(userId).doc(sessionId).collection('messages');

  // ─────────────────────── Session CRUD ───────────────────────

  /// Create a new chat session. Returns the generated session ID.
  Future<String> createSession(String userId) async {
    final now = DateTime.now();
    final doc = await _sessionsCol(userId).add(ChatSession(
      id: '',
      title: 'New Chat',
      createdAt: now,
      updatedAt: now,
    ).toFirestore());
    return doc.id;
  }

  /// Update the session title (called after first user message).
  Future<void> updateSessionTitle(
      String userId, String sessionId, String title) async {
    final trimmed = title.length > 40 ? '${title.substring(0, 37)}…' : title;
    await _sessionsCol(userId).doc(sessionId).update({
      'title': trimmed,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Stream of all sessions for the user, newest-first.
  Stream<List<ChatSession>> getSessions(String userId, {int? limit}) {
    var query = _sessionsCol(userId).orderBy('updated_at', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map((snap) => snap.docs
        .map((d) => ChatSession.fromFirestore(d.id, d.data()))
        .toList());
  }

  /// Delete a session and all its messages.
  Future<void> deleteSession(String userId, String sessionId) async {
    // Delete messages subcollection first (batched)
    final msgSnap = await _messagesCol(userId, sessionId).get();
    if (msgSnap.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in msgSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    // Delete the session document
    await _sessionsCol(userId).doc(sessionId).delete();
  }

  // ─────────────────────── Message CRUD ──────────────────────

  /// Save a single message to a session. Fire-and-forget.
  Future<void> saveMessage(
      String userId, String sessionId, ChatSessionMessage msg) async {
    await _messagesCol(userId, sessionId).add(msg.toFirestore());
    // Bump session metadata
    await _sessionsCol(userId).doc(sessionId).update({
      'updated_at': Timestamp.fromDate(DateTime.now()),
      'message_count': FieldValue.increment(1),
    });
  }

  /// Load all messages for a session, ordered chronologically.
  Future<List<ChatSessionMessage>> getSessionMessages(
      String userId, String sessionId) async {
    final snap = await _messagesCol(userId, sessionId)
        .orderBy('timestamp')
        .get();
    return snap.docs
        .map((d) => ChatSessionMessage.fromFirestore(d.id, d.data()))
        .toList();
  }
}

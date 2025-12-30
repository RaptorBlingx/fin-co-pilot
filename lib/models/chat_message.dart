import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat message model (simplified from chat_history in v2)
///
/// Per DATA_MODELS.md specification:
/// Stores conversation history between user and AI agents.
/// No session concept - flat message list per user.
///
/// Features:
/// - User and assistant messages
/// - Agent identification (financial_copilot, vision, analyst)
/// - Function call tracking
/// - Transaction extraction metadata
/// - NEW v3: Direct transaction saving from chat
class ChatMessage {
  final String id;
  final String userId;
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  /// Optional metadata about the message
  final ChatMessageMetadata? metadata;

  /// NEW v3: Link to saved transaction (if message resulted in transaction)
  final String? savedTransactionId;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
    this.savedTransactionId,
  });

  /// Create from Firestore document
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      userId: (data['user_id'] ?? data['userId']) as String,
      role: MessageRole.values.byName(data['role'] as String),
      content: data['content'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'] != null
          ? ChatMessageMetadata.fromMap(
              data['metadata'] as Map<String, dynamic>)
          : null,
      savedTransactionId: data['savedTransactionId'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'role': role.name,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata?.toMap(),
      'savedTransactionId': savedTransactionId,
    };
  }

  /// Check if message is from user
  bool get isUser => role == MessageRole.user;

  /// Check if message is from assistant
  bool get isAssistant => role == MessageRole.assistant;

  /// Check if message has transaction data
  bool get hasTransactionData =>
      metadata?.extractedData != null &&
      metadata!.extractedData!.amount != null;

  /// Check if message resulted in saved transaction
  bool get hasSavedTransaction => savedTransactionId != null;
}

/// Message metadata
class ChatMessageMetadata {
  /// Which AI agent processed this message
  final String agent;

  /// Function calls made (if any)
  final List<FunctionCall>? functionCalls;

  /// Extracted transaction data (if any)
  final ExtractedTransactionData? extractedData;

  ChatMessageMetadata({
    required this.agent,
    this.functionCalls,
    this.extractedData,
  });

  factory ChatMessageMetadata.fromMap(Map<String, dynamic> map) {
    // Parse function calls
    List<FunctionCall>? calls;
    if (map['functionCalls'] != null) {
      final callsData = map['functionCalls'] as List<dynamic>;
      calls = callsData
          .map((c) => FunctionCall.fromMap(c as Map<String, dynamic>))
          .toList();
    }

    return ChatMessageMetadata(
      agent: map['agent'] as String,
      functionCalls: calls,
      extractedData: map['extractedData'] != null
          ? ExtractedTransactionData.fromMap(
              map['extractedData'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agent': agent,
      'functionCalls': functionCalls?.map((c) => c.toMap()).toList(),
      'extractedData': extractedData?.toMap(),
    };
  }
}

/// Function call record
class FunctionCall {
  final String name;
  final Map<String, dynamic> args;
  final dynamic result;

  FunctionCall({
    required this.name,
    required this.args,
    this.result,
  });

  factory FunctionCall.fromMap(Map<String, dynamic> map) {
    return FunctionCall(
      name: map['name'] as String,
      args: Map<String, dynamic>.from(map['args'] ?? {}),
      result: map['result'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'args': args,
      'result': result,
    };
  }
}

/// Extracted transaction data from chat
class ExtractedTransactionData {
  final double? amount;
  final String? merchant;
  final String? category;

  ExtractedTransactionData({
    this.amount,
    this.merchant,
    this.category,
  });

  factory ExtractedTransactionData.fromMap(Map<String, dynamic> map) {
    return ExtractedTransactionData(
      amount:
          map['amount'] != null ? (map['amount'] as num).toDouble() : null,
      merchant: map['merchant'] as String?,
      category: map['category'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'merchant': merchant,
      'category': category,
    };
  }

  /// Check if has all required transaction fields
  bool get isComplete => amount != null && merchant != null && category != null;
}

/// Message role enum
enum MessageRole {
  user,
  assistant,
}

/// AI agent identifiers
class AgentIdentifier {
  static const String financialCopilot = 'financial_copilot';
  static const String vision = 'vision';
  static const String analyst = 'analyst';
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Smart Nudge Model (NEW in v3)
///
/// Per Knowledge Base: DATA_MODELS.md - smart_nudges collection
/// Proactive warnings before spending (Week 4 feature)
class SmartNudge {
  final String id;
  final String userId;
  final NudgeType type;
  final NudgePriority priority;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final NudgeTrigger? triggeredBy;
  final NudgeAction? action;
  final NudgeStatus status;
  final DateTime generatedAt;
  final DateTime? expiresAt;
  final DateTime? dismissedAt;

  SmartNudge({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.data,
    this.triggeredBy,
    this.action,
    required this.status,
    required this.generatedAt,
    this.expiresAt,
    this.dismissedAt,
  });

  factory SmartNudge.fromFirestore(DocumentSnapshot doc) {
    final docData = doc.data() as Map<String, dynamic>;
    return SmartNudge(
      id: doc.id,
      userId: docData['userId'] as String,
      type: NudgeType.values.byName(docData['type'] as String),
      priority: NudgePriority.values.byName(docData['priority'] as String),
      title: docData['title'] as String,
      message: docData['message'] as String,
      data: docData['data'] as Map<String, dynamic>,
      triggeredBy: docData['triggeredBy'] != null
          ? NudgeTrigger.fromMap(docData['triggeredBy'] as Map<String, dynamic>)
          : null,
      action: docData['action'] != null
          ? NudgeAction.fromMap(docData['action'] as Map<String, dynamic>)
          : null,
      status: NudgeStatus.values.byName(docData['status'] as String),
      generatedAt: (docData['generatedAt'] as Timestamp).toDate(),
      expiresAt: docData['expiresAt'] != null
          ? (docData['expiresAt'] as Timestamp).toDate()
          : null,
      dismissedAt: docData['dismissedAt'] != null
          ? (docData['dismissedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'type': type.name,
      'priority': priority.name,
      'title': title,
      'message': message,
      'data': data,
      'triggeredBy': triggeredBy?.toMap(),
      'action': action?.toMap(),
      'status': status.name,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'dismissedAt':
          dismissedAt != null ? Timestamp.fromDate(dismissedAt!) : null,
    };
  }

  /// Check if nudge is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if nudge is active
  bool get isActive => status == NudgeStatus.active && !isExpired;
}

class NudgeTrigger {
  final String? transactionId;
  final String? budgetId;
  final String? pattern;

  NudgeTrigger({
    this.transactionId,
    this.budgetId,
    this.pattern,
  });

  factory NudgeTrigger.fromMap(Map<String, dynamic> map) {
    return NudgeTrigger(
      transactionId: map['transactionId'] as String?,
      budgetId: map['budgetId'] as String?,
      pattern: map['pattern'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'budgetId': budgetId,
      'pattern': pattern,
    };
  }
}

class NudgeAction {
  final String label;
  final NudgeActionType type;
  final String? target;

  NudgeAction({
    required this.label,
    required this.type,
    this.target,
  });

  factory NudgeAction.fromMap(Map<String, dynamic> map) {
    return NudgeAction(
      label: map['label'] as String,
      type: NudgeActionType.values.byName(map['type'] as String),
      target: map['target'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'type': type.name,
      'target': target,
    };
  }
}

enum NudgeType {
  budgetWarning,      // "You're at 90% of your dining budget"
  impulseAlert,       // "You've spent $200 on shopping in 3 days"
  billReminder,       // "Netflix due tomorrow"
  savingsOpportunity, // "You could save $50/month"
}

enum NudgePriority {
  high,
  medium,
  low,
}

enum NudgeStatus {
  active,
  dismissed,
  expired,
}

enum NudgeActionType {
  dismiss,
  viewBudget,
  viewTransactions,
}

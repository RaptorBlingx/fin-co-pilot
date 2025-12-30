import 'package:cloud_firestore/cloud_firestore.dart';

/// Couples Dashboard - Shared financial visibility model
///
/// Per DATA_MODELS.md specification:
/// Enables couples to share budgets, categories, and financial data.
/// Supports AI Mediator feature for conflict resolution.
///
/// Features:
/// - Two-user account linking
/// - Shared budgets and categories
/// - Configurable visibility (full vs summary)
/// - Large spend notifications
/// - AI-powered conflict detection and mediation
/// - Week 10 feature: Couples Dashboard
class CoupleAccount {
  final String id;

  /// Users in this couple account (max 2 users)
  /// Map of userId -> CoupleUser details
  final Map<String, CoupleUser> users;

  /// Shared budget IDs
  final List<String> sharedBudgets;

  /// Shared category names
  final List<String> sharedCategories;

  /// Account settings
  final CoupleAccountSettings settings;

  /// Detected conflicts (AI Mediator feature)
  final List<CoupleConflict> conflicts;

  final DateTime createdAt;
  final DateTime updatedAt;

  CoupleAccount({
    required this.id,
    required this.users,
    required this.sharedBudgets,
    required this.sharedCategories,
    required this.settings,
    required this.conflicts,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(users.length == 2, 'Couple account must have exactly 2 users');

  /// Create from Firestore document
  factory CoupleAccount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse users map
    final usersData = data['users'] as Map<String, dynamic>;
    final users = usersData.map(
      (userId, userData) => MapEntry(
        userId,
        CoupleUser.fromMap(userData as Map<String, dynamic>),
      ),
    );

    // Parse conflicts array
    final conflictsData = data['conflicts'] as List<dynamic>? ?? [];
    final conflicts = conflictsData
        .map((c) => CoupleConflict.fromMap(c as Map<String, dynamic>))
        .toList();

    return CoupleAccount(
      id: doc.id,
      users: users,
      sharedBudgets: List<String>.from(data['sharedBudgets'] ?? []),
      sharedCategories: List<String>.from(data['sharedCategories'] ?? []),
      settings: CoupleAccountSettings.fromMap(
          data['settings'] as Map<String, dynamic>),
      conflicts: conflicts,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'users': users.map((userId, user) => MapEntry(userId, user.toMap())),
      'sharedBudgets': sharedBudgets,
      'sharedCategories': sharedCategories,
      'settings': settings.toMap(),
      'conflicts': conflicts.map((c) => c.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get active conflicts (not resolved)
  List<CoupleConflict> get activeConflicts =>
      conflicts.where((c) => !c.isResolved).toList();

  /// Get resolved conflicts
  List<CoupleConflict> get resolvedConflicts =>
      conflicts.where((c) => c.isResolved).toList();

  /// Check if user is part of this couple account
  bool hasUser(String userId) => users.containsKey(userId);

  /// Get partner's user ID
  String? getPartnerId(String userId) {
    if (!hasUser(userId)) return null;
    return users.keys.firstWhere((id) => id != userId);
  }

  /// Get user details
  CoupleUser? getUser(String userId) => users[userId];
}

/// Individual user in a couple account
class CoupleUser {
  final String name;
  final CoupleRole role;
  final DateTime joinedAt;

  CoupleUser({
    required this.name,
    required this.role,
    required this.joinedAt,
  });

  factory CoupleUser.fromMap(Map<String, dynamic> map) {
    return CoupleUser(
      name: map['name'] as String,
      role: CoupleRole.values.byName(map['role'] as String),
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

/// Couple account settings
class CoupleAccountSettings {
  /// Visibility level: 'full' = see all transactions, 'summary' = aggregated only
  final VisibilityLevel visibility;

  /// Notify partner on large spends
  final bool notifyOnLargeSpend;

  /// Threshold for large spend notifications
  final double largeSpendThreshold;

  CoupleAccountSettings({
    required this.visibility,
    required this.notifyOnLargeSpend,
    required this.largeSpendThreshold,
  });

  factory CoupleAccountSettings.fromMap(Map<String, dynamic> map) {
    return CoupleAccountSettings(
      visibility: VisibilityLevel.values.byName(map['visibility'] as String),
      notifyOnLargeSpend: map['notifyOnLargeSpend'] as bool,
      largeSpendThreshold: (map['largeSpendThreshold'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visibility': visibility.name,
      'notifyOnLargeSpend': notifyOnLargeSpend,
      'largeSpendThreshold': largeSpendThreshold,
    };
  }
}

/// AI Mediator detected conflict
class CoupleConflict {
  final String id;

  /// Conflict topic (e.g., "Overspending on dining")
  final String topic;

  final DateTime detectedAt;

  /// Resolution timestamp (if resolved)
  final DateTime? resolvedAt;

  /// AI Mediator's advice/summary
  final String? mediationSummary;

  CoupleConflict({
    required this.id,
    required this.topic,
    required this.detectedAt,
    this.resolvedAt,
    this.mediationSummary,
  });

  factory CoupleConflict.fromMap(Map<String, dynamic> map) {
    return CoupleConflict(
      id: map['id'] as String,
      topic: map['topic'] as String,
      detectedAt: (map['detectedAt'] as Timestamp).toDate(),
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
      mediationSummary: map['mediationSummary'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'detectedAt': Timestamp.fromDate(detectedAt),
      'resolvedAt':
          resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'mediationSummary': mediationSummary,
    };
  }

  /// Check if conflict is resolved
  bool get isResolved => resolvedAt != null;

  /// Check if mediation has been provided
  bool get hasMediation => mediationSummary != null;
}

/// Role in couple account
enum CoupleRole {
  /// User who initiated the couple account
  initiator,

  /// User who accepted the invitation
  partner,
}

/// Visibility level for shared data
enum VisibilityLevel {
  /// See all transaction details
  full,

  /// See only aggregated summaries
  summary,
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// User model (v3 specification)
///
/// Per DATA_MODELS.md specification:
/// Core user profile with v3 features:
/// - Voice and SMS preferences (NEW)
/// - SMS permission tracking (NEW)
/// - Financial Health score (NEW)
/// - Couples account linking (NEW)
class User {
  /// Firebase Auth UID (also document ID)
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// User preferences
  final UserPreferences preferences;

  /// User settings
  final UserSettings settings;

  /// Onboarding status
  final OnboardingStatus onboarding;

  /// NEW v3: Financial Health tracking
  final FinancialHealthStatus financialHealth;

  /// NEW v3: Couples feature (optional)
  final CoupleAccountInfo? coupleAccount;

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
    required this.preferences,
    required this.settings,
    required this.onboarding,
    required this.financialHealth,
    this.coupleAccount,
  });

  /// Create from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      photoURL: data['photoURL'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      preferences: UserPreferences.fromMap(
          data['preferences'] as Map<String, dynamic>),
      settings:
          UserSettings.fromMap(data['settings'] as Map<String, dynamic>),
      onboarding: OnboardingStatus.fromMap(
          data['onboarding'] as Map<String, dynamic>),
      financialHealth: FinancialHealthStatus.fromMap(
          data['financialHealth'] as Map<String, dynamic>),
      coupleAccount: data['coupleAccount'] != null
          ? CoupleAccountInfo.fromMap(
              data['coupleAccount'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'preferences': preferences.toMap(),
      'settings': settings.toMap(),
      'onboarding': onboarding.toMap(),
      'financialHealth': financialHealth.toMap(),
      'coupleAccount': coupleAccount?.toMap(),
    };
  }

  /// Copy with updated fields
  User copyWith({
    String? displayName,
    String? photoURL,
    UserPreferences? preferences,
    UserSettings? settings,
    OnboardingStatus? onboarding,
    FinancialHealthStatus? financialHealth,
    CoupleAccountInfo? coupleAccount,
  }) {
    return User(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      preferences: preferences ?? this.preferences,
      settings: settings ?? this.settings,
      onboarding: onboarding ?? this.onboarding,
      financialHealth: financialHealth ?? this.financialHealth,
      coupleAccount: coupleAccount ?? this.coupleAccount,
    );
  }

  /// Check if user has completed onboarding
  bool get hasCompletedOnboarding => onboarding.completed;

  /// Check if user has granted SMS permission
  bool get hasSmsPermission => onboarding.smsPermissionGranted;

  /// Check if user is in a couple account
  bool get isInCoupleAccount => coupleAccount != null;

  /// Check if couple account is active
  bool get hasCoupleAccountActive =>
      coupleAccount?.status == CoupleAccountStatus.active;
}

/// User preferences
class UserPreferences {
  final String currency; // USD, EUR, etc.
  final String locale; // en-US, es-ES, etc.
  final String timezone; // America/New_York, etc.
  final ThemeMode theme;
  final bool notificationsEnabled;

  /// NEW v3: Voice input preference
  final bool voiceEnabled;

  /// NEW v3: SMS auto-parsing enabled
  final bool smsParsingEnabled;

  UserPreferences({
    required this.currency,
    required this.locale,
    required this.timezone,
    required this.theme,
    required this.notificationsEnabled,
    required this.voiceEnabled,
    required this.smsParsingEnabled,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      currency: map['currency'] as String? ?? 'USD',
      locale: map['locale'] as String? ?? 'en-US',
      timezone: map['timezone'] as String? ?? 'America/New_York',
      theme: ThemeMode.values.byName(map['theme'] as String? ?? 'system'),
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      voiceEnabled: map['voiceEnabled'] as bool? ?? false,
      smsParsingEnabled: map['smsParsingEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currency': currency,
      'locale': locale,
      'timezone': timezone,
      'theme': theme.name,
      'notificationsEnabled': notificationsEnabled,
      'voiceEnabled': voiceEnabled,
      'smsParsingEnabled': smsParsingEnabled,
    };
  }

  /// Create default preferences
  factory UserPreferences.defaults() {
    return UserPreferences(
      currency: 'USD',
      locale: 'en-US',
      timezone: 'America/New_York',
      theme: ThemeMode.system,
      notificationsEnabled: true,
      voiceEnabled: false,
      smsParsingEnabled: false,
    );
  }
}

/// User settings
class UserSettings {
  final double? monthlyIncome;
  final List<String> categories; // Custom categories
  final String? defaultPaymentMethod;
  final int budgetAlertThreshold; // 0-100 (percentage)

  UserSettings({
    this.monthlyIncome,
    required this.categories,
    this.defaultPaymentMethod,
    required this.budgetAlertThreshold,
  }) : assert(
            budgetAlertThreshold >= 0 && budgetAlertThreshold <= 100,
            'Budget alert threshold must be 0-100');

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      monthlyIncome: map['monthlyIncome'] != null
          ? (map['monthlyIncome'] as num).toDouble()
          : null,
      categories: List<String>.from(map['categories'] ?? []),
      defaultPaymentMethod: map['defaultPaymentMethod'] as String?,
      budgetAlertThreshold: map['budgetAlertThreshold'] as int? ?? 90,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monthlyIncome': monthlyIncome,
      'categories': categories,
      'defaultPaymentMethod': defaultPaymentMethod,
      'budgetAlertThreshold': budgetAlertThreshold,
    };
  }

  /// Create default settings
  factory UserSettings.defaults() {
    return UserSettings(
      categories: [],
      budgetAlertThreshold: 90,
    );
  }
}

/// Onboarding status
class OnboardingStatus {
  final bool completed;

  /// NEW v3: SMS permission granted
  final bool smsPermissionGranted;

  final DateTime? completedAt;

  OnboardingStatus({
    required this.completed,
    required this.smsPermissionGranted,
    this.completedAt,
  });

  factory OnboardingStatus.fromMap(Map<String, dynamic> map) {
    return OnboardingStatus(
      completed: map['completed'] as bool? ?? false,
      smsPermissionGranted: map['smsPermissionGranted'] as bool? ?? false,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'smsPermissionGranted': smsPermissionGranted,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  /// Create initial onboarding status
  factory OnboardingStatus.initial() {
    return OnboardingStatus(
      completed: false,
      smsPermissionGranted: false,
    );
  }

  /// Mark onboarding as completed
  OnboardingStatus complete() {
    return OnboardingStatus(
      completed: true,
      smsPermissionGranted: smsPermissionGranted,
      completedAt: DateTime.now(),
    );
  }
}

/// NEW v3: Financial Health status
class FinancialHealthStatus {
  /// Current score: 0-100
  final int currentScore;

  final DateTime lastCalculated;

  /// Trend: improving, stable, declining
  final HealthTrend trend;

  FinancialHealthStatus({
    required this.currentScore,
    required this.lastCalculated,
    required this.trend,
  }) : assert(currentScore >= 0 && currentScore <= 100,
            'Score must be 0-100');

  factory FinancialHealthStatus.fromMap(Map<String, dynamic> map) {
    return FinancialHealthStatus(
      currentScore: map['currentScore'] as int? ?? 0,
      lastCalculated: (map['lastCalculated'] as Timestamp).toDate(),
      trend: HealthTrend.values.byName(map['trend'] as String? ?? 'stable'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentScore': currentScore,
      'lastCalculated': Timestamp.fromDate(lastCalculated),
      'trend': trend.name,
    };
  }

  /// Create initial health status
  factory FinancialHealthStatus.initial() {
    return FinancialHealthStatus(
      currentScore: 0,
      lastCalculated: DateTime.now(),
      trend: HealthTrend.stable,
    );
  }

  /// Get score grade
  String get grade {
    if (currentScore >= 90) return 'A';
    if (currentScore >= 80) return 'B';
    if (currentScore >= 70) return 'C';
    if (currentScore >= 60) return 'D';
    return 'F';
  }
}

/// NEW v3: Couple account info
class CoupleAccountInfo {
  /// Partner's user ID
  final String partnerId;

  /// User's role in couple account
  final CoupleRole role;

  /// Connection status
  final CoupleAccountStatus status;

  /// When connection was established (if active)
  final DateTime? connectedAt;

  CoupleAccountInfo({
    required this.partnerId,
    required this.role,
    required this.status,
    this.connectedAt,
  });

  factory CoupleAccountInfo.fromMap(Map<String, dynamic> map) {
    return CoupleAccountInfo(
      partnerId: map['partnerId'] as String,
      role: CoupleRole.values.byName(map['role'] as String),
      status: CoupleAccountStatus.values.byName(map['status'] as String),
      connectedAt: map['connectedAt'] != null
          ? (map['connectedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partnerId': partnerId,
      'role': role.name,
      'status': status.name,
      'connectedAt':
          connectedAt != null ? Timestamp.fromDate(connectedAt!) : null,
    };
  }

  /// Check if connection is active
  bool get isActive => status == CoupleAccountStatus.active;

  /// Check if connection is pending
  bool get isPending => status == CoupleAccountStatus.pending;
}

/// Theme mode
enum ThemeMode {
  light,
  dark,
  system,
}

/// Health trend
enum HealthTrend {
  improving,
  stable,
  declining,
}

/// Couple role
enum CoupleRole {
  initiator,
  partner,
}

/// Couple account status
enum CoupleAccountStatus {
  pending,
  active,
  disconnected,
}

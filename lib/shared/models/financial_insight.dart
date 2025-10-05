class FinancialInsight {
  final String id;
  final String userId;
  final String type; // pattern, achievement, warning, opportunity, anomaly
  final String severity; // low, medium, high
  final String title;
  final String description;
  final String? suggestion;
  final double potentialSavings;
  final DateTime createdAt;
  final bool isRead;

  FinancialInsight({
    required this.id,
    required this.userId,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    this.suggestion,
    this.potentialSavings = 0.0,
    required this.createdAt,
    this.isRead = false,
  });

  /// Create FinancialInsight from Firestore map
  factory FinancialInsight.fromMap(Map<String, dynamic> map, String id) {
    return FinancialInsight(
      id: id,
      userId: map['user_id'] ?? '',
      type: map['type'] ?? 'info',
      severity: map['severity'] ?? 'low',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      suggestion: map['suggestion'],
      potentialSavings: (map['potential_savings'] ?? 0.0).toDouble(),
      createdAt: map['created_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : DateTime.now(),
      isRead: map['is_read'] ?? false,
    );
  }

  /// Convert FinancialInsight to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type,
      'severity': severity,
      'title': title,
      'description': description,
      'suggestion': suggestion,
      'potential_savings': potentialSavings,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_read': isRead,
    };
  }

  /// Copy insight with updated fields
  FinancialInsight copyWith({
    String? id,
    String? userId,
    String? type,
    String? severity,
    String? title,
    String? description,
    String? suggestion,
    double? potentialSavings,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return FinancialInsight(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      suggestion: suggestion ?? this.suggestion,
      potentialSavings: potentialSavings ?? this.potentialSavings,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Get icon for insight type
  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'pattern':
        return '📊';
      case 'achievement':
        return '🎉';
      case 'warning':
        return '⚠️';
      case 'opportunity':
        return '💡';
      case 'anomaly':
        return '🔍';
      default:
        return 'ℹ️';
    }
  }

  /// Get color for severity level
  String get severityColor {
    switch (severity.toLowerCase()) {
      case 'high':
        return '#F44336'; // Red
      case 'medium':
        return '#FF9800'; // Orange
      case 'low':
        return '#4CAF50'; // Green
      default:
        return '#757575'; // Grey
    }
  }

  /// Get background color for insight card
  String get backgroundColor {
    switch (type.toLowerCase()) {
      case 'achievement':
        return '#E8F5E8'; // Light green
      case 'warning':
        return '#FFF3E0'; // Light orange
      case 'opportunity':
        return '#E3F2FD'; // Light blue
      case 'anomaly':
        return '#FCE4EC'; // Light pink
      default:
        return '#F5F5F5'; // Light grey
    }
  }

  /// Check if insight has actionable suggestion
  bool get hasActionableSuggestion {
    return suggestion != null && suggestion!.isNotEmpty;
  }

  /// Check if insight represents savings opportunity
  bool get hasSavingsOpportunity {
    return potentialSavings > 0;
  }

  /// Get formatted potential savings
  String get formattedSavings {
    if (potentialSavings <= 0) return '';
    return '\$${potentialSavings.toStringAsFixed(0)}';
  }

  /// Get relative time since creation
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'FinancialInsight{id: $id, type: $type, severity: $severity, title: $title, potentialSavings: $potentialSavings}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialInsight &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
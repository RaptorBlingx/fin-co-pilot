import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../../features/add_transaction/models/transaction_data.dart';

/// Agent 7: Pattern Learner Agent
/// Learns user patterns and vocabulary for smarter interactions
class PatternLearnerAgent {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GenerativeModel _model;

  PatternLearnerAgent() {
    // ignore: deprecated_member_use
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',
    );
  }

  /// Learn from a transaction to build user profile
  Future<void> learnFromTransaction({
    required String userId,
    required TransactionData transaction,
    required String originalUserInput,
  }) async {
    try {
      // Update user vocabulary
      await _updateVocabulary(
        userId: userId,
        input: originalUserInput,
        transaction: transaction,
      );

      // Update spending patterns
      await _updateSpendingPatterns(
        userId: userId,
        transaction: transaction,
      );

      // Update merchant preferences
      if (transaction.merchant != null) {
        await _updateMerchantPreferences(
          userId: userId,
          merchant: transaction.merchant!,
          category: transaction.category ?? 'Other',
        );
      }
    } catch (e) {
      print('Pattern Learner Agent Error: $e');
    }
  }

  /// Update user's vocabulary and phrases
  Future<void> _updateVocabulary({
    required String userId,
    required String input,
    required TransactionData transaction,
  }) async {
    final vocabRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('vocabulary')
        .doc('phrases');

    await vocabRef.set({
      'last_updated': FieldValue.serverTimestamp(),
      'phrases': FieldValue.arrayUnion([
        {
          'input': input,
          'item': transaction.item,
          'category': transaction.category,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ]),
    }, SetOptions(merge: true));
  }

  /// Update spending patterns
  Future<void> _updateSpendingPatterns({
    required String userId,
    required TransactionData transaction,
  }) async {
    if (transaction.category == null) return;

    final categoryRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('spending_patterns')
        .doc(transaction.category);

    final doc = await categoryRef.get();

    if (doc.exists) {
      await categoryRef.update({
        'transaction_count': FieldValue.increment(1),
        'total_spent': FieldValue.increment(transaction.amount ?? 0),
        'last_transaction': FieldValue.serverTimestamp(),
      });
    } else {
      await categoryRef.set({
        'category': transaction.category,
        'transaction_count': 1,
        'total_spent': transaction.amount ?? 0,
        'first_transaction': FieldValue.serverTimestamp(),
        'last_transaction': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Update merchant preferences
  Future<void> _updateMerchantPreferences({
    required String userId,
    required String merchant,
    required String category,
  }) async {
    final merchantRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('merchant_preferences')
        .doc(_normalizeMerchantName(merchant));

    await merchantRef.set({
      'merchant_name': merchant,
      'category': category,
      'visit_count': FieldValue.increment(1),
      'last_visit': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user's spending patterns
  Future<SpendingPatterns> getSpendingPatterns({
    required String userId,
  }) async {
    final patternsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('spending_patterns')
        .orderBy('total_spent', descending: true)
        .limit(10)
        .get();

    final patterns = <CategoryPattern>[];
    for (final doc in patternsSnapshot.docs) {
      final data = doc.data();
      patterns.add(CategoryPattern(
        category: data['category'],
        transactionCount: data['transaction_count'] ?? 0,
        totalSpent: (data['total_spent'] as num?)?.toDouble() ?? 0.0,
      ));
    }

    return SpendingPatterns(patterns: patterns);
  }

  /// Get user's favorite merchants
  Future<List<MerchantPreference>> getFavoriteMerchants({
    required String userId,
  }) async {
    final merchantsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('merchant_preferences')
        .orderBy('visit_count', descending: true)
        .limit(10)
        .get();

    final merchants = <MerchantPreference>[];
    for (final doc in merchantsSnapshot.docs) {
      final data = doc.data();
      merchants.add(MerchantPreference(
        merchantName: data['merchant_name'],
        category: data['category'],
        visitCount: data['visit_count'] ?? 0,
      ));
    }

    return merchants;
  }

  /// Interpret user's "shorthand" phrases
  Future<TransactionData?> interpretShorthand({
    required String userId,
    required String input,
  }) async {
    try {
      // Get user's patterns and vocabulary
      final patterns = await getSpendingPatterns(userId: userId);
      final merchants = await getFavoriteMerchants(userId: userId);

      // Build context-aware prompt
      final prompt = _buildInterpretationPrompt(
        input: input,
        patterns: patterns,
        merchants: merchants,
      );

      // Ask AI to interpret
      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      // Parse interpretation
      // This would return structured data based on user's history
      // For now, return null to indicate no special interpretation needed
      return null;
    } catch (e) {
      print('Pattern interpretation error: $e');
      return null;
    }
  }

  /// Build interpretation prompt
  String _buildInterpretationPrompt({
    required String input,
    required SpendingPatterns patterns,
    required List<MerchantPreference> merchants,
  }) {
    final prompt = StringBuffer();
    prompt.writeln('Interpret this shorthand based on user history:');
    prompt.writeln('User input: "$input"');
    prompt.writeln();
    prompt.writeln('User patterns:');

    for (final pattern in patterns.patterns.take(5)) {
      prompt.writeln('- ${pattern.category}: ${pattern.transactionCount} transactions, \$${pattern.totalSpent.toStringAsFixed(2)}');
    }

    prompt.writeln();
    prompt.writeln('Frequent merchants:');
    for (final merchant in merchants.take(5)) {
      prompt.writeln('- ${merchant.merchantName} (${merchant.category}): ${merchant.visitCount} visits');
    }

    prompt.writeln();
    prompt.writeln('Examples of shorthand:');
    prompt.writeln('- "my usual" → could mean user\'s most frequent item');
    prompt.writeln('- "same as last time" → repeat previous transaction');
    prompt.writeln('- merchant name only → assume typical spend at that merchant');

    return prompt.toString();
  }

  /// Normalize merchant name
  String _normalizeMerchantName(String merchant) {
    return merchant
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  /// Get purchase frequency for prediction
  Future<PurchaseFrequency> getPurchaseFrequency({
    required String userId,
    required String itemName,
  }) async {
    // This would analyze item_profiles to determine how often user buys something
    // Used for predictive notifications: "You usually buy milk every 4 days"

    // For now, return placeholder
    return PurchaseFrequency(
      itemName: itemName,
      averageDaysBetween: 7.0,
      lastPurchaseDate: DateTime.now(),
      predictedNextPurchase: DateTime.now().add(const Duration(days: 7)),
    );
  }
}

/// Spending patterns
class SpendingPatterns {
  final List<CategoryPattern> patterns;

  SpendingPatterns({required this.patterns});
}

/// Category spending pattern
class CategoryPattern {
  final String category;
  final int transactionCount;
  final double totalSpent;

  CategoryPattern({
    required this.category,
    required this.transactionCount,
    required this.totalSpent,
  });
}

/// Merchant preference
class MerchantPreference {
  final String merchantName;
  final String category;
  final int visitCount;

  MerchantPreference({
    required this.merchantName,
    required this.category,
    required this.visitCount,
  });
}

/// Purchase frequency prediction
class PurchaseFrequency {
  final String itemName;
  final double averageDaysBetween;
  final DateTime lastPurchaseDate;
  final DateTime predictedNextPurchase;

  PurchaseFrequency({
    required this.itemName,
    required this.averageDaysBetween,
    required this.lastPurchaseDate,
    required this.predictedNextPurchase,
  });

  /// Is it time to buy again?
  bool get shouldBuySoon {
    final daysUntil = predictedNextPurchase.difference(DateTime.now()).inDays;
    return daysUntil <= 2; // Within 2 days
  }
}

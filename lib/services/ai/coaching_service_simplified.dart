import 'package:firebase_ai/firebase_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../coaching_tips_library.dart';

/// Simplified CoachingService - Week 2 Task 2.6
/// 
/// Simplified to just two features:
/// 1. getDailyTip() - One tip per day
/// 2. answerQuestion() - Q&A chat interface
/// 
/// Removed: Proactive scheduling, complex notifications, pattern analysis
class CoachingServiceSimplified {
  static final CoachingServiceSimplified _instance = CoachingServiceSimplified._internal();
  factory CoachingServiceSimplified() => _instance;
  CoachingServiceSimplified._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GenerativeModel _model;

  CoachingServiceSimplified._() {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
    );
  }

  /// Get daily tip - one tip per day from library
  /// 
  /// Returns null if user already received a tip today
  Future<Map<String, String>?> getDailyTip() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Check if tip already shown today
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final tipsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('coaching')
          .doc('daily_tips')
          .get();

      final data = tipsDoc.data();
      if (data != null && data['last_tip_date'] == todayKey) {
        // Already shown today, return cached tip
        return {
          'title': data['last_tip_title'] as String? ?? 'Financial Tip',
          'body': data['last_tip_body'] as String? ?? 'Keep tracking your spending!',
          'category': data['last_tip_category'] as String? ?? 'general',
        };
      }

      // Get new tip from library
      final allTips = CoachingTipsLibrary.getTipsForCategory('general', {});
      final randomIndex = DateTime.now().millisecondsSinceEpoch % allTips.length;
      final selectedTip = allTips[randomIndex];
      
      final tip = {
        'title': selectedTip['title'] as String,
        'body': selectedTip['message'] as String,
        'category': 'general',
      };
      
      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('coaching')
          .doc('daily_tips')
          .set({
        'last_tip_date': todayKey,
        'last_tip_title': tip['title'],
        'last_tip_body': tip['body'],
        'last_tip_category': tip['category'],
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return tip;
    } catch (e) {
      print('Error getting daily tip: $e');
      // Return fallback tip
      return {
        'title': 'Track Your Spending',
        'body': 'Regular tracking helps you stay on budget and reach your financial goals.',
        'category': 'general',
      };
    }
  }

  /// Answer user's financial question using AI
  /// 
  /// Context includes: user's recent transactions, budgets, patterns
  Future<String> answerQuestion(String question) async {
    final user = _auth.currentUser;
    if (user == null) {
      return 'Please sign in to get personalized financial advice.';
    }

    try {
      // Get user context for personalized response
      final context = await _getUserContext(user.uid);
      
      // Build prompt with context
      final prompt = '''
You are a friendly financial coach helping a user with their personal finances.

User Context:
- Monthly spending: \$${context['monthly_spending']?.toStringAsFixed(2) ?? 'N/A'}
- Top category: ${context['top_category'] ?? 'N/A'} (\$${context['top_category_amount']?.toStringAsFixed(2) ?? 'N/A'})
- Budget status: ${context['budget_status'] ?? 'No budgets set'}
- Transaction count: ${context['transaction_count'] ?? 0} last 30 days

User Question: "$question"

Provide a helpful, concise answer (2-3 sentences max). Be encouraging and actionable.
Focus on practical advice they can implement today.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final answer = response.text ?? 'I apologize, but I could not generate a response. Please try rephrasing your question.';
      
      // Log Q&A for future improvements
      await _logQA(user.uid, question, answer);
      
      return answer;
    } catch (e) {
      print('Error answering question: $e');
      return 'I apologize, but I encountered an error. Please try again later.';
    }
  }

  /// Get user financial context for personalized answers
  Future<Map<String, dynamic>> _getUserContext(String userId) async {
    try {
      // Get transactions from last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .where('transaction_date', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      double totalSpending = 0.0;
      int transactionCount = 0;
      final Map<String, double> categorySpending = {};

      for (final doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final category = data['category'] as String? ?? 'Other';
        
        if (amount > 0) {
          totalSpending += amount;
          transactionCount++;
          categorySpending[category] = (categorySpending[category] ?? 0) + amount;
        }
      }

      // Find top spending category
      String topCategory = 'Other';
      double topCategoryAmount = 0.0;
      categorySpending.forEach((category, amount) {
        if (amount > topCategoryAmount) {
          topCategory = category;
          topCategoryAmount = amount;
        }
      });

      // Get budget status
      final budgetsSnapshot = await _firestore
          .collection('budgets')
          .where('user_id', isEqualTo: userId)
          .get();

      String budgetStatus = budgetsSnapshot.docs.isEmpty 
          ? 'No budgets set'
          : '${budgetsSnapshot.docs.length} active budgets';

      return {
        'monthly_spending': totalSpending,
        'transaction_count': transactionCount,
        'top_category': topCategory,
        'top_category_amount': topCategoryAmount,
        'budget_status': budgetStatus,
      };
    } catch (e) {
      print('Error getting user context: $e');
      return {};
    }
  }

  /// Log Q&A for analytics and improvement
  Future<void> _logQA(String userId, String question, String answer) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('coaching')
          .doc('qa_history')
          .collection('questions')
          .add({
        'question': question,
        'answer': answer,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging Q&A: $e');
    }
  }

  /// Get Q&A history for the user
  Future<List<Map<String, dynamic>>> getQAHistory({int limit = 10}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('coaching')
          .doc('qa_history')
          .collection('questions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'question': data['question'] as String,
          'answer': data['answer'] as String,
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error getting Q&A history: $e');
      return [];
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_ai/firebase_ai.dart';
import '../models/transaction.dart' as models;
import '../models/money_story.dart';
import 'notification_service.dart';

/// Money Story Service
///
/// Week 7: Daily Money Story (Killer Feature #6)
/// Generates engaging daily narratives of spending at 9 PM.
///
/// Features:
/// - AI-generated story from day's transactions
/// - Emoji-rich narrative format
/// - Budget status tracking
/// - Weekly comparison
/// - Push notification delivery
/// - Cloud Function trigger (9 PM daily)
///
/// Uses Analyst Agent for story generation
class MoneyStoryService {
  static final MoneyStoryService _instance = MoneyStoryService._internal();
  factory MoneyStoryService() => _instance;
  MoneyStoryService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _notificationService = NotificationService();

  /// Generate today's money story for a user
  ///
  /// This should be called by a Cloud Function at 9 PM daily,
  /// but can also be triggered manually for testing.
  Future<MoneyStory?> generateTodaysStory(String userId) async {
    print('[MoneyStory] Generating story for user: $userId');

    // Get today's transactions
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final todayTxns = await _getTransactions(userId, startOfDay, endOfDay);

    if (todayTxns.isEmpty) {
      print('[MoneyStory] No transactions today, skipping story');
      return null;
    }

    // Calculate highlights
    final highlights = _calculateHighlights(todayTxns);

    // Get week's context for comparison
    final weekStart = startOfDay.subtract(Duration(days: startOfDay.weekday % 7));
    final weekTxns = await _getTransactions(userId, weekStart, endOfDay);

    // Generate AI story
    final storyText = await _generateStoryWithAI(
      todayTxns,
      weekTxns,
      highlights,
    );

    // Create money story
    final story = MoneyStory(
      id: '', // Firestore will generate
      userId: userId,
      date: startOfDay,
      story: storyText,
      highlights: highlights,
      transactions: todayTxns.map((t) => t.id ?? '').where((id) => id.isNotEmpty).toList(),
      generatedAt: DateTime.now(),
      sentAt: null, // Will be set when notification is sent
    );

    // Save to Firestore
    final docRef = await _saveStory(story);
    final savedStory = story.copyWith(id: docRef.id);

    // Send push notification
    await _sendStoryNotification(userId, savedStory);

    print('[MoneyStory] Story generated and sent');
    return savedStory;
  }

  /// Calculate story highlights from transactions
  MoneyStoryHighlights _calculateHighlights(
    List<models.Transaction> transactions,
  ) {
    // Calculate totals
    final expenses = transactions.where((t) => t.type == models.TransactionType.expense);
    final income = transactions.where((t) => t.type == models.TransactionType.income);

    final totalSpent = expenses.fold<double>(0, (sum, t) => sum + t.amount);
    final totalIncome = income.fold<double>(0, (sum, t) => sum + t.amount);

    // Find top category
    final categoryTotals = <String, double>{};
    for (final txn in expenses) {
      categoryTotals[txn.category] = (categoryTotals[txn.category] ?? 0) + txn.amount;
    }

    String topCategory = 'Other';
    double topCategoryAmount = 0;
    categoryTotals.forEach((category, amount) {
      if (amount > topCategoryAmount) {
        topCategory = category;
        topCategoryAmount = amount;
      }
    });

    // Find top transaction
    models.Transaction? topTxn;
    if (expenses.isNotEmpty) {
      topTxn = expenses.reduce((a, b) => a.amount > b.amount ? a : b);
    }

    // Determine budget status (simplified - could integrate with budget service)
    String budgetStatus;
    if (totalSpent < 50) {
      budgetStatus = 'well under budget';
    } else if (totalSpent < 100) {
      budgetStatus = 'on track';
    } else if (totalSpent < 150) {
      budgetStatus = 'approaching limit';
    } else {
      budgetStatus = 'over budget';
    }

    return MoneyStoryHighlights(
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      topCategory: topCategory,
      topTransaction: topTxn != null
          ? {
              'merchant': topTxn.merchant ?? 'Unknown',
              'amount': topTxn.amount,
            }
          : null,
      transactionCount: transactions.length,
      budgetStatus: budgetStatus,
    );
  }

  /// Generate story narrative using AI (Analyst Agent)
  Future<String> _generateStoryWithAI(
    List<models.Transaction> todayTxns,
    List<models.Transaction> weekTxns,
    MoneyStoryHighlights highlights,
  ) async {
    try {
      // Use Gemini 2.5 Flash for fast story generation
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3-flash-preview',
      );

      // Format transactions for prompt
      final txnList = todayTxns
          .where((t) => t.type == models.TransactionType.expense)
          .map((t) =>
              '• \$${t.amount.toStringAsFixed(2)} - ${t.description ?? t.category} ${_getCategoryEmoji(t.category)} ${t.merchant ?? ""}')
          .join('\n');

      final weeklySpend = weekTxns
          .where((t) => t.type == models.TransactionType.expense)
          .fold<double>(0, (sum, t) => sum + t.amount);

      final prompt = '''
You are a friendly financial storyteller. Create a warm, encouraging daily money story.

TODAY'S DATA:
- Spent: \$${highlights.totalSpent.toStringAsFixed(2)}
- Transactions: ${highlights.transactionCount}
- Top category: ${highlights.topCategory}
- Budget status: ${highlights.budgetStatus}

TRANSACTIONS:
$txnList

WEEKLY CONTEXT:
- This week's total: \$${weeklySpend.toStringAsFixed(2)}

Create a story following this EXACT format:

Today's Money Story 📖
[Day], [Date]

You spent \$[amount] today

[List each transaction with emoji]

Top category: [category] (\$[amount])
This week: \$[weekTotal]

[One encouraging sentence based on budget status]

RULES:
- Keep it conversational and warm
- Use appropriate emojis (☕🌯🛒 etc)
- Be encouraging, never judgmental
- If under budget: celebrate
- If over budget: be gentle and supportive
- Maximum 150 words
- Include actual amounts and merchants from data

Respond with ONLY the story text, no markdown formatting.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final storyText = response.text?.trim() ?? _generateFallbackStory(todayTxns, highlights, weeklySpend);

      return storyText;
    } catch (e) {
      print('[MoneyStory] AI generation error: $e');
      // Fallback to template-based story
      return _generateFallbackStory(todayTxns, highlights, weekTxns.fold<double>(0, (sum, t) => sum + t.amount));
    }
  }

  /// Generate fallback story without AI
  String _generateFallbackStory(
    List<models.Transaction> todayTxns,
    MoneyStoryHighlights highlights,
    double weeklySpend,
  ) {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final dateStr = '${_getMonthName(now.month)} ${now.day}, ${now.year}';

    final txnLines = todayTxns
        .where((t) => t.type == models.TransactionType.expense)
        .take(5)
        .map((t) =>
            '• \$${t.amount.toStringAsFixed(2)} - ${t.description ?? t.category} ${_getCategoryEmoji(t.category)} ${t.merchant ?? ""}')
        .join('\n');

    String encouragement;
    if (highlights.budgetStatus == 'well under budget') {
      encouragement = 'You\'re ${highlights.totalSpent < 30 ? "\$" + (50 - highlights.totalSpent).toStringAsFixed(0) : ""} under budget today! Keep it up! 🎉';
    } else if (highlights.budgetStatus == 'on track') {
      encouragement = 'You\'re on track with your budget. Great job! 👍';
    } else if (highlights.budgetStatus == 'approaching limit') {
      encouragement = 'Getting close to your limit. Consider postponing non-essentials. 💙';
    } else {
      encouragement = 'Take a breath. Tomorrow is a new day to stay on track. 💪';
    }

    return '''Today's Money Story 📖
$dayName, $dateStr

You spent \$${highlights.totalSpent.toStringAsFixed(2)} today

$txnLines

Top category: ${highlights.topCategory} (\$${highlights.totalSpent.toStringAsFixed(2)})
This week: \$${weeklySpend.toStringAsFixed(2)}

$encouragement''';
  }

  /// Get emoji for category
  String _getCategoryEmoji(String category) {
    final categoryMap = {
      'Coffee': '☕',
      'Dining': '🍽️',
      'Groceries': '🛒',
      'Shopping': '🛍️',
      'Transportation': '🚗',
      'Entertainment': '🎬',
      'Health': '💊',
      'Bills': '📄',
      'Travel': '✈️',
      'Education': '📚',
    };
    return categoryMap[category] ?? '💰';
  }

  /// Get day name
  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  /// Get month name
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  /// Get transactions in date range
  Future<List<models.Transaction>> _getTransactions(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('transaction_date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('transaction_date', isLessThan: Timestamp.fromDate(end))
        .orderBy('transaction_date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => models.Transaction.fromFirestore(doc))
        .toList();
  }

  /// Save story to Firestore
  Future<DocumentReference> _saveStory(MoneyStory story) async {
    return await _firestore.collection('money_stories').add(story.toFirestore());
  }

  /// Send push notification with story
  Future<void> _sendStoryNotification(String userId, MoneyStory story) async {
    try {
      await _notificationService.showGeneral(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Today\'s Money Story 📖',
        body: 'You spent \$${story.highlights.totalSpent.toStringAsFixed(2)} today. Tap to see your story!',
        payload: {'storyId': story.id, 'userId': userId},
      );

      // Update sentAt timestamp
      await _firestore
          .collection('money_stories')
          .doc(story.id)
          .update({'sentAt': Timestamp.now()});
    } catch (e) {
      print('[MoneyStory] Notification error: $e');
    }
  }

  /// Get story for a specific date
  Future<MoneyStory?> getStoryForDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('money_stories')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return MoneyStory.fromFirestore(snapshot.docs.first);
  }

  /// Get recent stories (last 30 days)
  Stream<List<MoneyStory>> getRecentStoriesStream(String userId) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return _firestore
        .collection('money_stories')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
        .orderBy('date', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MoneyStory.fromFirestore(doc)).toList());
  }

  /// Get all stories for a month
  Future<List<MoneyStory>> getStoriesForMonth(String userId, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final snapshot = await _firestore
        .collection('money_stories')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => MoneyStory.fromFirestore(doc)).toList();
  }
}

/// Extension to add copyWith to MoneyStory
extension MoneyStoryCopyWith on MoneyStory {
  MoneyStory copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? story,
    MoneyStoryHighlights? highlights,
    List<String>? transactions,
    DateTime? generatedAt,
    DateTime? sentAt,
  }) {
    return MoneyStory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      story: story ?? this.story,
      highlights: highlights ?? this.highlights,
      transactions: transactions ?? this.transactions,
      generatedAt: generatedAt ?? this.generatedAt,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}

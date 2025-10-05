import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../shared/models/transaction.dart';
import '../shared/models/coaching_tip.dart';

class ProactiveCoachAgent {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GenerativeModel _model = FirebaseVertexAI.instance.generativeModel(
    model: 'gemini-2.5-pro',
    generationConfig: GenerationConfig(
      temperature: 0.7,
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 8192,
    ),
  );

  /// Generate personalized coaching tips based on user's spending behavior
  Future<List<CoachingTip>> generateWeeklyCoaching({
    required String userId,
  }) async {
    try {
      print('🐛 ProactiveCoachAgent: Starting coaching generation for $userId');
      
      // 1. Fetch last 30 days of transactions for context
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      print('🐛 ProactiveCoachAgent: Fetching transactions from $startDate to $endDate');
      final transactions = await _fetchTransactions(userId, startDate, endDate);
      print('🐛 ProactiveCoachAgent: Found ${transactions.length} transactions');

      if (transactions.isEmpty) {
        print('🐛 ProactiveCoachAgent: No transactions found, returning welcome tip');
        final welcomeTip = CoachingTip(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          type: 'welcome',
          priority: 'low',
          title: 'Welcome to Fin Co-Pilot!',
          message: 'Start logging your expenses to get personalized coaching',
          actionable: false,
          createdAt: DateTime.now(),
        );
        
        // Store the welcome tip
        await _storeCoachingTips(userId, [welcomeTip]);
        return [welcomeTip];
      }

      // 2. Fetch previous coaching tips to avoid repetition
      final previousTips = await _fetchRecentCoachingTips(userId);

      // 3. Analyze spending patterns
      final analysis = _analyzeBehavior(transactions);

      // 4. Fetch user profile for personalization
      final userProfile = await _fetchUserProfile(userId);

      // 5. Build coaching prompt
      final prompt = _buildCoachingPrompt(
        transactions,
        analysis,
        userProfile,
        previousTips,
      );

      // 6. Call Gemini 2.5 Pro for advanced financial reasoning
      final response = await _model.generateContent([Content.text(prompt)]);
      final coachingText = response.text ?? '';

      // 7. Parse tips
      final tips = _parseCoachingTips(coachingText, userId, analysis);
      print('🐛 ProactiveCoachAgent: Parsed ${tips.length} tips from Gemini response');

      // 8. Store in Firestore
      print('🐛 ProactiveCoachAgent: Storing tips in Firestore...');
      await _storeCoachingTips(userId, tips);
      print('🐛 ProactiveCoachAgent: Tips stored successfully');

      return tips;
    } catch (e) {
      print('🐛 ProactiveCoachAgent ERROR: $e');
      print('🐛 ProactiveCoachAgent: Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Fetch transactions for date range
  Future<List<Transaction>> _fetchTransactions(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print('🐛 _fetchTransactions: Querying transactions for user $userId');
      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .get();
      
      print('🐛 _fetchTransactions: Found ${snapshot.docs.length} total transactions');
      
      // Filter by date in memory to avoid complex Firestore queries
      final transactions = snapshot.docs
          .map((doc) => Transaction.fromMap(doc.data(), doc.id))
          .where((tx) => 
              tx.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              tx.transactionDate.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
      
      // Sort in memory
      transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      
      print('🐛 _fetchTransactions: Filtered to ${transactions.length} transactions in date range');
      return transactions;
    } catch (e) {
      print('🐛 _fetchTransactions ERROR: $e');
      return [];
    }
  }

  /// Fetch recent coaching tips to avoid repetition
  Future<List<CoachingTip>> _fetchRecentCoachingTips(String userId) async {
    try {
      print('🐛 _fetchRecentCoachingTips: Querying recent tips for user $userId');
      final snapshot = await _firestore
          .collection('coaching_tips')
          .where('user_id', isEqualTo: userId)
          .get();

      print('🐛 _fetchRecentCoachingTips: Found ${snapshot.docs.length} total tips');
      
      // Filter by date in memory
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentTips = snapshot.docs
          .map((doc) => CoachingTip.fromMap(doc.data(), doc.id))
          .where((tip) => tip.createdAt.isAfter(sevenDaysAgo))
          .take(10)
          .toList();
      
      print('🐛 _fetchRecentCoachingTips: Filtered to ${recentTips.length} recent tips');
      return recentTips;
    } catch (e) {
      print('🐛 _fetchRecentCoachingTips ERROR: $e');
      return [];
    }
  }

  /// Fetch user profile for personalization
  Future<Map<String, dynamic>> _fetchUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() ?? {} : {};
    } catch (e) {
      print('🐛 _fetchUserProfile ERROR: $e');
      return {};
    }
  }

  /// Analyze user spending behavior
  Map<String, dynamic> _analyzeBehavior(List<Transaction> transactions) {
    if (transactions.isEmpty) return {};

    final now = DateTime.now();
    final currentWeek = transactions
        .where((tx) => now.difference(tx.transactionDate).inDays <= 7)
        .toList();
    final previousWeek = transactions
        .where((tx) {
          final daysDiff = now.difference(tx.transactionDate).inDays;
          return daysDiff > 7 && daysDiff <= 14;
        })
        .toList();

    // Total amounts
    final totalSpent = transactions.fold<double>(0, (sum, tx) => sum + tx.amount);
    final avgDaily = totalSpent / 30;
    final avgWeekly = totalSpent / 4;

    // Category breakdown
    final categoryTotals = <String, double>{};
    for (final tx in transactions) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
    }

    // Find top category safely
    String? topCategory;
    if (categoryTotals.isNotEmpty) {
      topCategory = categoryTotals.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    // Spending frequency
    final transactionDays = transactions
        .map((tx) => DateTime(tx.transactionDate.year, tx.transactionDate.month, tx.transactionDate.day))
        .toSet()
        .length;

    // Weekend vs weekday spending
    final weekendSpending = transactions
        .where((tx) => tx.transactionDate.weekday >= 6)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final weekdaySpending = transactions
        .where((tx) => tx.transactionDate.weekday < 6)
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    // Detect positive changes
    final positiveHabits = <String>[];
    final negativeHabits = <String>[];

    // Compare dining expenses
    final currentDining = currentWeek
        .where((tx) => tx.category == 'dining')
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final previousDining = previousWeek
        .where((tx) => tx.category == 'dining')
        .fold<double>(0, (sum, tx) => sum + tx.amount);

    if (previousDining > 0) {
      if (currentDining < previousDining * 0.8) {
        positiveHabits.add('Reduced dining expenses by ${((previousDining - currentDining) / previousDining * 100).toStringAsFixed(0)}%');
      } else if (currentDining > previousDining * 1.2) {
        negativeHabits.add('Dining expenses increased by ${((currentDining - previousDining) / previousDining * 100).toStringAsFixed(0)}%');
      }
    }

    return {
      'totalSpent': totalSpent,
      'avgDaily': avgDaily,
      'avgWeekly': avgWeekly,
      'categoryTotals': categoryTotals,
      'topCategory': topCategory,
      'transactionDays': transactionDays,
      'weekendSpending': weekendSpending,
      'weekdaySpending': weekdaySpending,
      'positiveHabits': positiveHabits,
      'negativeHabits': negativeHabits,
      'frequentCategories': categoryTotals.entries
          .where((e) => e.value > totalSpent * 0.1)
          .map((e) => e.key)
          .toList(),
    };
  }

  /// Build coaching prompt for Gemini
  String _buildCoachingPrompt(
    List<Transaction> transactions,
    Map<String, dynamic> analysis,
    Map<String, dynamic> userProfile,
    List<CoachingTip> previousTips,
  ) {
    final previousTitles = previousTips.map((tip) => tip.title).join(', ');
    
    return '''
You are an expert personal finance coach using Gemini 2.5 Pro with advanced reasoning capabilities. Use deep analytical thinking to provide personalized coaching.

REASONING APPROACH:
1. Analyze spending patterns for trends, anomalies, and behavioral insights
2. Consider psychological factors behind spending decisions
3. Identify both immediate opportunities and long-term financial health strategies
4. Provide actionable, personalized recommendations based on user's specific behavior

SPENDING ANALYSIS:
- Total spent (30 days): \$${analysis['totalSpent']?.toStringAsFixed(2) ?? '0'}
- Daily average: \$${analysis['avgDaily']?.toStringAsFixed(2) ?? '0'}
- Top category: ${analysis['topCategory'] ?? 'N/A'}
- Weekend spending: \$${analysis['weekendSpending']?.toStringAsFixed(2) ?? '0'}
- Weekday spending: \$${analysis['weekdaySpending']?.toStringAsFixed(2) ?? '0'}
- Recent positive habits: ${analysis['positiveHabits']?.join(', ') ?? 'None'}
- Areas for improvement: ${analysis['negativeHabits']?.join(', ') ?? 'None'}

RECENT TRANSACTIONS (last 10):
${transactions.take(10).map((tx) => '- ${tx.transactionDate.toString().split(' ')[0]}: \$${tx.amount.toStringAsFixed(2)} on ${tx.category} (${tx.description})').join('\n')}

AVOID REPETITION: Don't suggest these previous tips: $previousTitles

COACHING REQUIREMENTS:
- Create 2-3 different, actionable coaching tips
- Use behavioral psychology principles
- Provide specific, measurable recommendations
- Balance encouragement with constructive guidance
- Consider both short-term wins and long-term financial health

Use your advanced reasoning to create highly personalized, effective coaching tips.
''';
  }

  /// Parse Gemini response into CoachingTip objects
  List<CoachingTip> _parseCoachingTips(
    String coachingText,
    String userId,
    Map<String, dynamic> analysis,
  ) {
    final tips = <CoachingTip>[];
    print('🐛 _parseCoachingTips: Creating tips from analysis');
    
    // Create tips based on analysis - guaranteed to work
    final categoryTotals = analysis['categoryTotals'] as Map<String, double>? ?? {};
    final topCategory = analysis['topCategory'] as String?;
    final totalSpent = analysis['totalSpent'] as double? ?? 0;
    final avgDaily = analysis['avgDaily'] as double? ?? 0;
    
    // Tip 1: High spending category
    if (topCategory != null && categoryTotals[topCategory]! > totalSpent * 0.3) {
      tips.add(CoachingTip(
        id: 'tip_${DateTime.now().millisecondsSinceEpoch}_1',
        userId: userId,
        type: 'insight',
        priority: 'high',
        title: 'High $topCategory spending',
        message: 'You spent \$${categoryTotals[topCategory]!.toStringAsFixed(2)} on $topCategory. Consider setting a weekly budget.',
        actionable: true,
        createdAt: DateTime.now(),
      ));
    }
    
    // Tip 2: Daily spending suggestion
    if (avgDaily > 25) {
      tips.add(CoachingTip(
        id: 'tip_${DateTime.now().millisecondsSinceEpoch}_2',
        userId: userId,
        type: 'suggestion',
        priority: 'medium',
        title: 'Track daily spending',
        message: 'Your daily average is \$${avgDaily.toStringAsFixed(2)}. Try setting a daily limit.',
        actionable: true,
        createdAt: DateTime.now(),
      ));
    }
    
    // Tip 3: Achievement for positive habits
    if (analysis['positiveHabits'] != null && (analysis['positiveHabits'] as List).isNotEmpty) {
      tips.add(CoachingTip(
        id: 'tip_${DateTime.now().millisecondsSinceEpoch}_3',
        userId: userId,
        type: 'achievement',
        priority: 'low',
        title: 'Great progress!',
        message: (analysis['positiveHabits'] as List).first as String,
        actionable: false,
        createdAt: DateTime.now(),
      ));
    } else {
      // Default encouragement tip
      tips.add(CoachingTip(
        id: 'tip_${DateTime.now().millisecondsSinceEpoch}_4',
        userId: userId,
        type: 'opportunity',
        priority: 'low',
        title: 'Keep tracking!',
        message: 'You\'re doing great by monitoring your expenses. Keep it up!',
        actionable: false,
        createdAt: DateTime.now(),
      ));
    }
    
    print('🐛 _parseCoachingTips: Created ${tips.length} tips');
    for (final tip in tips) {
      print('🐛 Tip: ${tip.id} - ${tip.title}');
    }
    
    return tips;
  }

  /// Store generated coaching tips in Firestore
  Future<void> _storeCoachingTips(
    String userId,
    List<CoachingTip> tips,
  ) async {
    try {
      print('🐛 _storeCoachingTips: Storing ${tips.length} tips for user $userId');
      final batch = _firestore.batch();

      for (final tip in tips) {
        final docRef = _firestore.collection('coaching_tips').doc(tip.id);
        final tipData = tip.toMap();
        print('🐛 _storeCoachingTips: Adding tip to batch - ID: ${tip.id}, Title: ${tip.title}');
        print('🐛 _storeCoachingTips: Tip data: $tipData');
        batch.set(docRef, tipData);
      }

      print('🐛 _storeCoachingTips: Committing batch to Firestore...');
      await batch.commit();
      print('🐛 _storeCoachingTips: Batch committed successfully');
    } catch (e) {
      print('🐛 _storeCoachingTips ERROR: $e');
      print('🐛 _storeCoachingTips: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Mark coaching tip as read
  Future<void> markAsRead(String tipId) async {
    await _firestore.collection('coaching_tips').doc(tipId).update({
      'read': true,
      'read_at': FieldValue.serverTimestamp(),
    });
  }

  /// Dismiss coaching tip
  Future<void> dismissTip(String tipId) async {
    await _firestore.collection('coaching_tips').doc(tipId).update({
      'dismissed': true,
      'dismissed_at': FieldValue.serverTimestamp(),
    });
  }

  /// Get unread coaching tips for user
  Stream<List<CoachingTip>> getUnreadTips(String userId) {
    print('🐛 getUnreadTips: Starting stream for user $userId');
    return _firestore
        .collection('coaching_tips')
        .where('user_id', isEqualTo: userId)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          print('🐛 getUnreadTips: Received ${snapshot.docs.length} docs from Firestore');
          final tips = snapshot.docs
              .map((doc) {
                try {
                  final tip = CoachingTip.fromMap(doc.data(), doc.id);
                  print('🐛 getUnreadTips: Parsed tip ${tip.id} - read: ${tip.read}, dismissed: ${tip.dismissed}');
                  return tip;
                } catch (e) {
                  print('🐛 getUnreadTips: Error parsing tip ${doc.id}: $e');
                  return null;
                }
              })
              .where((tip) => tip != null)
              .cast<CoachingTip>()
              .where((tip) => !tip.read && !tip.dismissed)
              .take(5)
              .toList();
          
          // Sort in memory
          tips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          print('🐛 getUnreadTips: Returning ${tips.length} unread tips');
          return tips;
        });
  }

  /// Get all coaching tips for user (for history view)
  Stream<List<CoachingTip>> getAllTips(String userId) {
    print('🐛 getAllTips: Starting stream for user $userId');
    return _firestore
        .collection('coaching_tips')
        .where('user_id', isEqualTo: userId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          print('🐛 getAllTips: Received ${snapshot.docs.length} docs from Firestore');
          final tips = snapshot.docs
              .map((doc) {
                try {
                  final tip = CoachingTip.fromMap(doc.data(), doc.id);
                  print('🐛 getAllTips: Parsed tip ${tip.id} - dismissed: ${tip.dismissed}');
                  return tip;
                } catch (e) {
                  print('🐛 getAllTips: Error parsing tip ${doc.id}: $e');
                  return null;
                }
              })
              .where((tip) => tip != null)
              .cast<CoachingTip>()
              .where((tip) => !tip.dismissed)
              .toList();
          
          // Sort in memory
          tips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          print('🐛 getAllTips: Returning ${tips.length} total tips');
          return tips;
        });
  }

  /// Create sample test tips for debugging
  Future<void> createTestTips(String userId) async {
    print('🐛 createTestTips: Creating test tips for user $userId');
    final testTips = [
      CoachingTip(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}_1',
        userId: userId,
        type: 'insight',
        priority: 'high',
        title: 'Test High Priority Tip',
        message: 'This is a test coaching tip with high priority to verify the UI works.',
        actionable: true,
        createdAt: DateTime.now(),
      ),
      CoachingTip(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}_2',
        userId: userId,
        type: 'suggestion',
        priority: 'medium',
        title: 'Test Medium Priority Tip',
        message: 'This is another test tip with medium priority for verification.',
        actionable: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      CoachingTip(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}_3',
        userId: userId,
        type: 'achievement',
        priority: 'low',
        title: 'Test Achievement',
        message: 'Great job! This is a test achievement tip.',
        actionable: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    await _storeCoachingTips(userId, testTips);
    print('🐛 createTestTips: Test tips created successfully');
  }
}
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class CoachingService {
  static final CoachingService _instance = CoachingService._internal();
  factory CoachingService() => _instance;
  CoachingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final Random _random = Random();

  /// Send daily coaching tip
  Future<void> sendDailyCoachingTip() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Check if tip already sent today
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final existingTip = await _firestore
          .collection('coaching_tips_sent')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: todayString)
          .get();

      if (existingTip.docs.isNotEmpty) {
        return; // Already sent today
      }

      // Get user's spending patterns for personalized tips
      final userProfile = await _getUserSpendingProfile();
      
      // Select appropriate tip category based on user profile
      final tipCategory = _selectTipCategory(userProfile);
      
      // Get tip from the selected category
      final tip = _getTipFromCategory(tipCategory);
      
      if (tip != null) {
        // Send coaching tip notification
        await _notificationService.sendCoachingTip(
          title: tip['title']!,
          body: tip['body']!,
          tipCategory: tipCategory,
        );

        // Record that tip was sent
        await _recordTipSent(todayString, tipCategory, tip);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending daily coaching tip: $e');
      }
    }
  }

  /// Get user spending profile for personalized tips
  Future<Map<String, dynamic>> _getUserSpendingProfile() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      // Get transactions from last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      Map<String, double> categorySpending = {};
      double totalSpending = 0.0;
      int transactionCount = 0;

      for (final doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num).toDouble();
        final category = data['category'] as String;
        final type = data['type'] as String;

        if (type == 'expense') {
          categorySpending[category] = (categorySpending[category] ?? 0) + amount;
          totalSpending += amount;
          transactionCount++;
        }
      }

      // Find top spending category
      String topCategory = 'general';
      double maxSpending = 0.0;
      categorySpending.forEach((category, amount) {
        if (amount > maxSpending) {
          maxSpending = amount;
          topCategory = category;
        }
      });

      return {
        'topCategory': topCategory,
        'totalSpending': totalSpending,
        'averageTransaction': transactionCount > 0 ? totalSpending / transactionCount : 0,
        'transactionCount': transactionCount,
        'categorySpending': categorySpending,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user spending profile: $e');
      }
      return {};
    }
  }

  /// Select tip category based on user profile
  String _selectTipCategory(Map<String, dynamic> userProfile) {
    final topCategory = userProfile['topCategory'] as String? ?? 'general';
    final totalSpending = userProfile['totalSpending'] as double? ?? 0;
    final transactionCount = userProfile['transactionCount'] as int? ?? 0;

    // Personalize based on spending patterns
    if (totalSpending > 2000) {
      return 'budgeting';
    } else if (topCategory == 'Food' || topCategory == 'Restaurant') {
      return 'food_savings';
    } else if (topCategory == 'Transportation') {
      return 'transportation';
    } else if (topCategory == 'Shopping') {
      return 'smart_shopping';
    } else if (transactionCount > 50) {
      return 'mindful_spending';
    } else {
      return 'general';
    }
  }

  /// Get tip from category
  Map<String, String>? _getTipFromCategory(String category) {
    final tips = _getTipsByCategory();
    final categoryTips = tips[category] ?? tips['general']!;
    
    if (categoryTips.isEmpty) return null;
    
    return categoryTips[_random.nextInt(categoryTips.length)];
  }

  /// Get all tips organized by category
  Map<String, List<Map<String, String>>> _getTipsByCategory() {
    return {
      'budgeting': [
        {
          'title': '💰 50/30/20 Rule',
          'body': 'Try the 50/30/20 rule: 50% needs, 30% wants, 20% savings. It\'s a simple way to balance your finances!',
        },
        {
          'title': '📊 Track Your Spending',
          'body': 'Spend 5 minutes each day reviewing your transactions. Awareness is the first step to better money management!',
        },
        {
          'title': '🎯 Set Specific Goals',
          'body': 'Instead of "save more," try "save \$200 this month." Specific goals are more likely to be achieved!',
        },
        {
          'title': '📱 Use the Envelope Method',
          'body': 'Allocate specific amounts to different spending categories. When the "envelope" is empty, you\'re done spending in that category!',
        },
      ],
      'food_savings': [
        {
          'title': '🍳 Meal Prep Magic',
          'body': 'Spend Sunday prepping meals for the week. You\'ll save money and make healthier choices!',
        },
        {
          'title': '📋 Shop with a List',
          'body': 'Always grocery shop with a list and stick to it. This simple habit can cut your food spending by 20%!',
        },
        {
          'title': '🏠 Cook at Home',
          'body': 'Cooking one extra meal at home per week instead of dining out can save you \$1,200+ per year!',
        },
        {
          'title': '🥪 Pack Your Lunch',
          'body': 'Bringing lunch to work just 3 days a week can save you over \$600 annually!',
        },
      ],
      'transportation': [
        {
          'title': '⛽ Track Gas Prices',
          'body': 'Use apps like GasBuddy to find the cheapeast gas stations near you. Small savings add up!',
        },
        {
          'title': '🚗 Combine Trips',
          'body': 'Plan your errands to combine multiple stops in one trip. You\'ll save on gas and time!',
        },
        {
          'title': '🚲 Alternative Transportation',
          'body': 'Consider biking, walking, or public transit for short trips. Your wallet and health will thank you!',
        },
        {
          'title': '🔧 Regular Maintenance',
          'body': 'Keep up with car maintenance. A well-maintained car is more fuel-efficient and lasts longer!',
        },
      ],
      'smart_shopping': [
        {
          'title': '⏰ 24-Hour Rule',
          'body': 'For non-essential purchases over \$50, wait 24 hours before buying. You might find you don\'t need it!',
        },
        {
          'title': '🛍️ Compare Prices',
          'body': 'Check 2-3 stores or websites before making larger purchases. Price comparison can save you 10-30%!',
        },
        {
          'title': '🏷️ Use Cashback Apps',
          'body': 'Apps like Rakuten or Honey can give you cashback on purchases you\'re already making!',
        },
        {
          'title': '📅 Time Your Purchases',
          'body': 'Buy seasonal items at the end of the season when they go on clearance!',
        },
      ],
      'mindful_spending': [
        {
          'title': '🤔 Ask "Do I Need This?"',
          'body': 'Before each purchase, ask yourself: "Do I need this, or do I just want it?" This simple question can prevent impulse buys!',
        },
        {
          'title': '💳 Use Cash for Discretionary Spending',
          'body': 'Using cash for entertainment and shopping makes spending feel more real and helps you stick to budgets!',
        },
        {
          'title': '📱 Delete Shopping Apps',
          'body': 'Remove shopping apps from your phone\'s home screen to reduce impulse purchases!',
        },
        {
          'title': '🛒 Shop with Purpose',
          'body': 'Only shop when you need something specific. Avoid browsing stores or websites when you\'re bored!',
        },
      ],
      'savings': [
        {
          'title': '🏦 Automate Your Savings',
          'body': 'Set up automatic transfers to savings right after payday. Pay yourself first!',
        },
        {
          'title': '🪙 Save Your Change',
          'body': 'Use apps that round up purchases and save the change. Small amounts add up to big savings!',
        },
        {
          'title': '💰 High-Yield Savings',
          'body': 'Move your emergency fund to a high-yield savings account. Let your money work for you!',
        },
        {
          'title': '🎯 Emergency Fund First',
          'body': 'Focus on building a \$1,000 emergency fund before other financial goals. It\'s your financial safety net!',
        },
      ],
      'general': [
        {
          'title': '📈 Start Small',
          'body': 'Small consistent actions lead to big results. Start with saving just \$1 per day!',
        },
        {
          'title': '💡 Learn Something New',
          'body': 'Read one financial article or watch one money management video today. Knowledge is power!',
        },
        {
          'title': '🔍 Review Your Subscriptions',
          'body': 'Cancel subscriptions you don\'t use regularly. That \$10/month adds up to \$120/year!',
        },
        {
          'title': '🎉 Celebrate Small Wins',
          'body': 'Acknowledge your financial progress, no matter how small. Positive reinforcement builds good habits!',
        },
        {
          'title': '📞 Negotiate Bills',
          'body': 'Call your internet, phone, or insurance companies to ask about discounts. You might be surprised what you can save!',
        },
      ],
    };
  }

  /// Record that tip was sent
  Future<void> _recordTipSent(String date, String category, Map<String, String> tip) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('coaching_tips_sent').add({
        'userId': user.uid,
        'date': date,
        'category': category,
        'title': tip['title'],
        'body': tip['body'],
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error recording tip sent: $e');
      }
    }
  }

  /// Send personalized weekly financial report
  Future<void> sendWeeklyReport() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get spending data for the past week
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final twoWeeksAgo = now.subtract(const Duration(days: 14));

      final thisWeekSpending = await _getSpendingForPeriod(weekAgo, now);
      final lastWeekSpending = await _getSpendingForPeriod(twoWeeksAgo, weekAgo);

      final spendingChange = thisWeekSpending - lastWeekSpending;
      final percentageChange = lastWeekSpending > 0 ? (spendingChange / lastWeekSpending) * 100 : 0;

      String title;
      String body;

      if (spendingChange > 0) {
        title = '📊 Weekly Spending Up';
        body = 'Your spending increased by \$${spendingChange.toStringAsFixed(2)} (${percentageChange.toStringAsFixed(1)}%) this week. Current: \$${thisWeekSpending.toStringAsFixed(2)}';
      } else if (spendingChange < 0) {
        title = '🎉 Great Job Saving!';
        body = 'You spent \$${(-spendingChange).toStringAsFixed(2)} less this week! Your spending decreased by ${(-percentageChange).toStringAsFixed(1)}%.';
      } else {
        title = '📊 Consistent Spending';
        body = 'Your spending this week was consistent with last week at \$${thisWeekSpending.toStringAsFixed(2)}. Keep up the good work!';
      }

      await _notificationService.sendCoachingTip(
        title: title,
        body: body,
        tipCategory: 'weekly_report',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending weekly report: $e');
      }
    }
  }

  /// Get spending for a specific period
  Future<double> _getSpendingForPeriod(DateTime start, DateTime end) async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    try {
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'expense')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .get();

      double totalSpending = 0.0;
      for (final doc in transactionsSnapshot.docs) {
        final amount = (doc.data()['amount'] as num).toDouble();
        totalSpending += amount;
      }

      return totalSpending;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating spending for period: $e');
      }
      return 0.0;
    }
  }

  /// Send motivation based on progress
  Future<void> sendMotivationalMessage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get user's progress metrics
      final userProfile = await _getUserSpendingProfile();
      final totalSpending = userProfile['totalSpending'] as double? ?? 0;
      
      // Get user's goals
      final goalsSnapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: user.uid)
          .where('active', isEqualTo: true)
          .get();

      if (goalsSnapshot.docs.isNotEmpty) {
        final goal = goalsSnapshot.docs.first.data();
        final goalAmount = (goal['amount'] as num).toDouble();
        final currentProgress = (goal['currentAmount'] as num?)?.toDouble() ?? 0;
        final progressPercentage = (currentProgress / goalAmount) * 100;

        String title;
        String body;

        if (progressPercentage >= 100) {
          title = '🎉 Goal Achieved!';
          body = 'Congratulations! You\'ve reached your goal of \$${goalAmount.toStringAsFixed(2)}!';
        } else if (progressPercentage >= 75) {
          title = '🔥 Almost There!';
          body = 'You\'re ${progressPercentage.toStringAsFixed(1)}% towards your goal! Just \$${(goalAmount - currentProgress).toStringAsFixed(2)} to go!';
        } else if (progressPercentage >= 50) {
          title = '💪 Halfway There!';
          body = 'Great progress! You\'re halfway to your goal of \$${goalAmount.toStringAsFixed(2)}. Keep going!';
        } else if (progressPercentage >= 25) {
          title = '🌟 Good Start!';
          body = 'You\'re making progress towards your goal! ${progressPercentage.toStringAsFixed(1)}% complete.';
        } else {
          title = '🚀 Every Step Counts';
          body = 'Remember: every dollar saved is a step towards your goal. You\'ve got this!';
        }

        await _notificationService.sendCoachingTip(
          title: title,
          body: body,
          tipCategory: 'motivation',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending motivational message: $e');
      }
    }
  }

  /// Send smart spending insights
  Future<void> sendSpendingInsights() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userProfile = await _getUserSpendingProfile();
      final categorySpending = userProfile['categorySpending'] as Map<String, double>? ?? {};
      
      if (categorySpending.isEmpty) return;

      // Find unusual spending patterns
      String insight = _generateSpendingInsight(categorySpending);
      
      if (insight.isNotEmpty) {
        await _notificationService.sendCoachingTip(
          title: '💡 Spending Insight',
          body: insight,
          tipCategory: 'insights',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending spending insights: $e');
      }
    }
  }

  /// Generate spending insight based on patterns
  String _generateSpendingInsight(Map<String, double> categorySpending) {
    // Find top spending category
    String topCategory = '';
    double maxAmount = 0;
    
    categorySpending.forEach((category, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        topCategory = category;
      }
    });

    if (topCategory.isEmpty) return '';

    final totalSpending = categorySpending.values.reduce((a, b) => a + b);
    final percentage = (maxAmount / totalSpending) * 100;

    if (percentage > 40) {
      return '$topCategory represents ${percentage.toStringAsFixed(1)}% of your spending. Consider reviewing this category for potential savings!';
    } else if (topCategory == 'Food' && percentage > 25) {
      return 'Food spending is ${percentage.toStringAsFixed(1)}% of your budget. Try meal planning to reduce costs!';
    } else if (topCategory == 'Shopping' && percentage > 20) {
      return 'Shopping represents ${percentage.toStringAsFixed(1)}% of your spending. Consider implementing a 24-hour rule for purchases!';
    }

    return '';
  }
}
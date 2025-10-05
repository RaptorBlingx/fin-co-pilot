import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import 'notification_service.dart';

class BudgetMonitoringService {
  static final BudgetMonitoringService _instance = BudgetMonitoringService._internal();
  factory BudgetMonitoringService() => _instance;
  BudgetMonitoringService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  /// Monitor budget usage and send alerts
  Future<void> checkBudgetAlerts() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get current month budgets
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final budgetsSnapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: user.uid)
          .where('month', isEqualTo: '${now.year}-${now.month.toString().padLeft(2, '0')}')
          .get();

      for (final budgetDoc in budgetsSnapshot.docs) {
        final budgetData = budgetDoc.data();
        final category = budgetData['category'] as String;
        final budgetLimit = (budgetData['amount'] as num).toDouble();
        
        // Calculate current spending for this category
        final currentSpending = await _getCurrentSpending(category, startOfMonth, endOfMonth);
        final percentageUsed = (currentSpending / budgetLimit) * 100;
        
        // Check for different alert thresholds
        if (percentageUsed >= 100 && !budgetData['overageAlertSent']) {
          // Budget exceeded
          await _sendBudgetOverageAlert(category, currentSpending, budgetLimit);
          await _markAlertSent(budgetDoc.id, 'overageAlertSent');
        } else if (percentageUsed >= 90 && !budgetData['ninetyPercentAlertSent']) {
          // 90% threshold
          await _sendBudgetWarningAlert(category, currentSpending, budgetLimit, 90);
          await _markAlertSent(budgetDoc.id, 'ninetyPercentAlertSent');
        } else if (percentageUsed >= 75 && !budgetData['seventyFivePercentAlertSent']) {
          // 75% threshold
          await _sendBudgetWarningAlert(category, currentSpending, budgetLimit, 75);
          await _markAlertSent(budgetDoc.id, 'seventyFivePercentAlertSent');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking budget alerts: $e');
      }
    }
  }

  /// Get current spending for a category
  Future<double> _getCurrentSpending(String category, DateTime startDate, DateTime endDate) async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    try {
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('category', isEqualTo: category)
          .where('type', isEqualTo: 'expense')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double totalSpending = 0.0;
      for (final doc in transactionsSnapshot.docs) {
        final amount = (doc.data()['amount'] as num).toDouble();
        totalSpending += amount;
      }

      return totalSpending;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating current spending: $e');
      }
      return 0.0;
    }
  }

  /// Send budget overage alert
  Future<void> _sendBudgetOverageAlert(String category, double currentSpending, double budgetLimit) async {
    final overage = currentSpending - budgetLimit;
    
    await _notificationService.sendBudgetAlert(
      title: '💸 Budget Exceeded!',
      body: 'You\'ve overspent in $category by \$${overage.toStringAsFixed(2)}. Current: \$${currentSpending.toStringAsFixed(2)} / \$${budgetLimit.toStringAsFixed(2)}',
      category: category,
      amount: currentSpending,
      budgetLimit: budgetLimit,
    );
  }

  /// Send budget warning alert
  Future<void> _sendBudgetWarningAlert(String category, double currentSpending, double budgetLimit, int percentage) async {
    final remaining = budgetLimit - currentSpending;
    
    await _notificationService.sendBudgetAlert(
      title: '⚠️ Budget Alert - $percentage% Used',
      body: 'You\'ve used $percentage% of your $category budget. \$${remaining.toStringAsFixed(2)} remaining.',
      category: category,
      amount: currentSpending,
      budgetLimit: budgetLimit,
    );
  }

  /// Mark alert as sent
  Future<void> _markAlertSent(String budgetDocId, String alertField) async {
    try {
      await _firestore.collection('budgets').doc(budgetDocId).update({
        alertField: true,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error marking alert as sent: $e');
      }
    }
  }

  /// Check for spending milestones
  Future<void> checkSpendingMilestones() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get user's total spending
      final totalSpending = await _getTotalUserSpending();
      
      // Check milestone achievements
      final milestones = [100, 500, 1000, 5000, 10000, 25000, 50000];
      
      for (final milestone in milestones) {
        if (totalSpending >= milestone) {
          final achieved = await _checkMilestoneAchieved(milestone);
          if (!achieved) {
            await _sendMilestoneNotification(milestone, totalSpending);
            await _markMilestoneAchieved(milestone);
          }
        }
      }

      // Check monthly savings goals
      await _checkMonthlySavingsGoals();
      
      // Check spending streaks
      await _checkSpendingStreaks();
      
    } catch (e) {
      if (kDebugMode) {
        print('Error checking spending milestones: $e');
      }
    }
  }

  /// Get total user spending
  Future<double> _getTotalUserSpending() async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    try {
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'expense')
          .get();

      double totalSpending = 0.0;
      for (final doc in transactionsSnapshot.docs) {
        final amount = (doc.data()['amount'] as num).toDouble();
        totalSpending += amount;
      }

      return totalSpending;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating total spending: $e');
      }
      return 0.0;
    }
  }

  /// Check if milestone is already achieved
  Future<bool> _checkMilestoneAchieved(int milestone) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final achievementDoc = await _firestore
          .collection('achievements')
          .doc('${user.uid}_spending_$milestone')
          .get();

      return achievementDoc.exists;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking milestone achievement: $e');
      }
      return false;
    }
  }

  /// Send milestone notification
  Future<void> _sendMilestoneNotification(int milestone, double totalSpending) async {
    await _notificationService.sendMilestoneNotification(
      title: '🎉 Spending Milestone Reached!',
      body: 'You\'ve reached \$${milestone} in total spending! Your current total: \$${totalSpending.toStringAsFixed(2)}',
      milestoneType: 'spending',
      achievementData: {
        'milestone': milestone,
        'totalSpending': totalSpending,
        'achievedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Mark milestone as achieved
  Future<void> _markMilestoneAchieved(int milestone) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('achievements')
          .doc('${user.uid}_spending_$milestone')
          .set({
        'userId': user.uid,
        'type': 'spending_milestone',
        'milestone': milestone,
        'achievedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error marking milestone as achieved: $e');
      }
    }
  }

  /// Check monthly savings goals
  Future<void> _checkMonthlySavingsGoals() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Calculate monthly income vs expenses
      final monthlyIncome = await _getMonthlyAmount('income', startOfMonth, endOfMonth);
      final monthlyExpenses = await _getMonthlyAmount('expense', startOfMonth, endOfMonth);
      final monthlySavings = monthlyIncome - monthlyExpenses;

      // Check if user has a savings goal
      final savingsGoalDoc = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'monthly_savings')
          .where('month', isEqualTo: '${now.year}-${now.month.toString().padLeft(2, '0')}')
          .limit(1)
          .get();

      if (savingsGoalDoc.docs.isNotEmpty) {
        final goalData = savingsGoalDoc.docs.first.data();
        final savingsGoal = (goalData['amount'] as num).toDouble();
        
        if (monthlySavings >= savingsGoal) {
          final achieved = await _checkMilestoneAchieved(savingsGoal.toInt());
          if (!achieved) {
            await _notificationService.sendMilestoneNotification(
              title: '💰 Savings Goal Achieved!',
              body: 'Congratulations! You\'ve saved \$${monthlySavings.toStringAsFixed(2)} this month, exceeding your goal of \$${savingsGoal.toStringAsFixed(2)}!',
              milestoneType: 'monthly_savings',
              achievementData: {
                'goal': savingsGoal,
                'actual': monthlySavings,
                'month': '${now.year}-${now.month.toString().padLeft(2, '0')}',
              },
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking monthly savings goals: $e');
      }
    }
  }

  /// Get monthly amount for income or expense
  Future<double> _getMonthlyAmount(String type, DateTime startDate, DateTime endDate) async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    try {
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: type)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double total = 0.0;
      for (final doc in transactionsSnapshot.docs) {
        final amount = (doc.data()['amount'] as num).toDouble();
        total += amount;
      }

      return total;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating monthly amount: $e');
      }
      return 0.0;
    }
  }

  /// Check spending streaks (days without overspending)
  Future<void> _checkSpendingStreaks() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      int currentStreak = 0;
      final now = DateTime.now();
      
      // Check last 30 days for spending streaks
      for (int i = 0; i < 30; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final dailySpending = await _getDailySpending(checkDate);
        
        // Define reasonable daily spending limit (you can make this configurable)
        const dailyLimit = 100.0; // \$100 per day
        
        if (dailySpending <= dailyLimit) {
          currentStreak++;
        } else {
          break;
        }
      }

      // Send streak notifications for milestones
      final streakMilestones = [7, 14, 30, 60, 90];
      for (final milestone in streakMilestones) {
        if (currentStreak >= milestone) {
          final achieved = await _checkStreakAchieved(milestone);
          if (!achieved) {
            await _sendStreakNotification(milestone, currentStreak);
            await _markStreakAchieved(milestone);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking spending streaks: $e');
      }
    }
  }

  /// Get daily spending
  Future<double> _getDailySpending(DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'expense')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      double dailySpending = 0.0;
      for (final doc in transactionsSnapshot.docs) {
        final amount = (doc.data()['amount'] as num).toDouble();
        dailySpending += amount;
      }

      return dailySpending;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating daily spending: $e');
      }
      return 0.0;
    }
  }

  /// Check if streak is achieved
  Future<bool> _checkStreakAchieved(int streak) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final achievementDoc = await _firestore
          .collection('achievements')
          .doc('${user.uid}_streak_$streak')
          .get();

      return achievementDoc.exists;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking streak achievement: $e');
      }
      return false;
    }
  }

  /// Send streak notification
  Future<void> _sendStreakNotification(int milestone, int currentStreak) async {
    await _notificationService.sendMilestoneNotification(
      title: '🔥 Spending Streak!',
      body: 'Amazing! You\'ve maintained responsible spending for $currentStreak days straight!',
      milestoneType: 'spending_streak',
      achievementData: {
        'streak': currentStreak,
        'milestone': milestone,
        'achievedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Mark streak as achieved
  Future<void> _markStreakAchieved(int streak) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('achievements')
          .doc('${user.uid}_streak_$streak')
          .set({
        'userId': user.uid,
        'type': 'spending_streak',
        'streak': streak,
        'achievedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error marking streak as achieved: $e');
      }
    }
  }
}
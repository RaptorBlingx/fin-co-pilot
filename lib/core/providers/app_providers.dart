import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction.dart';
import '../../shared/models/spending_insights.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../services/insights_service.dart';

// ── Auth ──────────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final userIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});

// ── Services ─────────────────────────────────────────────────────────────────

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ── Transactions ─────────────────────────────────────────────────────────────

final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(transactionServiceProvider).getTransactions(uid);
});

final currentMonthTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(transactionServiceProvider).getCurrentMonthTransactions(uid);
});

// ── Budgets ──────────────────────────────────────────────────────────────────

final budgetsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return Stream.value([]);

  final now = DateTime.now();
  final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  return ref.watch(firestoreProvider)
      .collection('budgets')
      .where('user_id', isEqualTo: uid)
      .where('month', isEqualTo: month)
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList());
});

// ── Insights ─────────────────────────────────────────────────────────────────

final insightsProvider = Provider<SpendingInsights?>((ref) {
  final transactions = ref.watch(currentMonthTransactionsProvider).valueOrNull;
  if (transactions == null || transactions.isEmpty) return null;
  return InsightsService.generateInsights(transactions);
});

// ── Period-filtered transactions (for Insights screen) ───────────────────────

final selectedPeriodProvider = StateProvider<String>((ref) => 'month');

final periodTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return Stream.value([]);

  final period = ref.watch(selectedPeriodProvider);
  final now = DateTime.now();
  DateTime startDate;
  switch (period) {
    case 'week':
      startDate = now.subtract(const Duration(days: 7));
      break;
    case 'year':
      startDate = DateTime(now.year, 1, 1);
      break;
    case 'month':
    default:
      startDate = DateTime(now.year, now.month, 1);
  }

  return ref.watch(firestoreProvider)
      .collection('transactions')
      .where('user_id', isEqualTo: uid)
      .where('transaction_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('transaction_date', isLessThanOrEqualTo: Timestamp.fromDate(now))
      .orderBy('transaction_date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => Transaction.fromFirestore(doc)).toList());
});

// ── User Currency ────────────────────────────────────────────────────────────

final userCurrencyProvider = StreamProvider<String>((ref) {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return Stream.value('USD');
  return ref.watch(firestoreProvider)
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.data()?['currency'] as String? ?? 'USD');
});

// ── Monthly Budget (aggregate total from monthly_budgets doc) ────────────────

final monthlyBudgetProvider = StreamProvider<double>((ref) {
  final uid = ref.watch(userIdProvider);
  if (uid == null) return Stream.value(0);

  final now = DateTime.now();
  final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  return ref.watch(firestoreProvider)
      .collection('monthly_budgets')
      .doc('${uid}_$month')
      .snapshots()
      .map((snap) {
    if (!snap.exists) return 0.0;
    return (snap.data()?['totalBudget'] as num?)?.toDouble() ?? 0.0;
  });
});

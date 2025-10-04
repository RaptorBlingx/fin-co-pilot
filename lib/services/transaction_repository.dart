import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart' as models;

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'transactions';

  /// Save transaction to Firestore
  Future<String> saveTransaction(models.Transaction transaction) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(transaction.toFirestore());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save transaction: $e');
    }
  }

  /// Get all transactions for a user
  Future<List<models.Transaction>> getUserTransactions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => models.Transaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  /// Get transactions for a specific date range
  Future<List<models.Transaction>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => models.Transaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transactions by date range: $e');
    }
  }

  /// Get transactions by category
  Future<List<models.Transaction>> getTransactionsByCategory(
    String userId,
    String category,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => models.Transaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transactions by category: $e');
    }
  }

  /// Update transaction
  Future<void> updateTransaction(models.Transaction transaction) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(transaction.id)
          .update(transaction.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  /// Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(transactionId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  /// Get transaction by ID
  Future<models.Transaction?> getTransaction(String transactionId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(transactionId)
          .get();

      if (doc.exists) {
        return models.Transaction.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get transaction: $e');
    }
  }

  /// Get spending summary by category for a user
  Future<Map<String, double>> getSpendingByCategory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();
      final transactions = querySnapshot.docs
          .map((doc) => models.Transaction.fromFirestore(doc))
          .toList();

      final categorySpending = <String, double>{};
      for (final transaction in transactions) {
        categorySpending[transaction.category] = 
            (categorySpending[transaction.category] ?? 0) + transaction.amount;
      }

      return categorySpending;
    } catch (e) {
      throw Exception('Failed to get spending by category: $e');
    }
  }

  /// Get total spending for a user
  Future<double> getTotalSpending(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();
      
      double total = 0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception('Failed to get total spending: $e');
    }
  }

  /// Stream of user transactions (real-time updates)
  Stream<List<models.Transaction>> streamUserTransactions(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => models.Transaction.fromFirestore(doc))
            .toList());
  }
}
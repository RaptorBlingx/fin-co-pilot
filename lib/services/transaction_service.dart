import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/models/transaction.dart' as model;
import 'receipt_parser_agent.dart';
import 'transaction_classifier_agent.dart';
import 'dart:io';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReceiptParserAgent _receiptParser = ReceiptParserAgent();
  final TransactionClassifierAgent _classifier = TransactionClassifierAgent();

  /// Add transaction from receipt photo
  Future<Map<String, dynamic>> addTransactionFromReceipt({
    required String userId,
    required File imageFile,
    required String currency,
  }) async {
    try {
      // Parse receipt using AI
      final parseResult = await _receiptParser.parseReceipt(imageFile);
      
      if (!parseResult['success']) {
        return {
          'success': false,
          'error': parseResult['error'],
        };
      }
      
      final receiptData = parseResult['data'];
      
      // Create transaction from receipt data
      final transaction = model.Transaction(
        userId: userId,
        amount: receiptData['total']?.toDouble() ?? 0.0,
        currency: receiptData['currency'] ?? currency,
        category: 'groceries', // Default, can be improved with classification
        merchant: receiptData['merchant'],
        description: 'Receipt from ${receiptData['merchant'] ?? "store"}',
        transactionDate: receiptData['date'] != null
            ? DateTime.parse(receiptData['date'])
            : DateTime.now(),
        createdAt: DateTime.now(),
        inputMethod: 'receipt_photo',
        receiptData: receiptData,
        aiConfidence: receiptData['confidence']?.toDouble(),
        paymentMethod: receiptData['payment_method'] ?? 'cash',
      );
      
      // Save to Firestore
      final docRef = await _firestore
          .collection('transactions')
          .add(transaction.toFirestore());
      
      return {
        'success': true,
        'transaction_id': docRef.id,
        'data': receiptData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to add transaction: ${e.toString()}',
      };
    }
  }

  /// Add transaction from text description
  Future<Map<String, dynamic>> addTransactionFromText({
    required String userId,
    required String description,
    required String currency,
  }) async {
    try {
      // Classify transaction using AI
      final classifyResult = await _classifier.classifyTransaction(description);
      
      if (!classifyResult['success']) {
        return {
          'success': false,
          'error': classifyResult['error'],
        };
      }
      
      final classification = classifyResult['data'];
      
      // Create transaction
      final transaction = model.Transaction(
        userId: userId,
        amount: classification['amount']?.toDouble() ?? 0.0,
        currency: currency,
        category: classification['category'] ?? 'other',
        merchant: classification['merchant'],
        description: classification['description'] ?? description,
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        inputMethod: 'text',
        aiConfidence: classification['confidence']?.toDouble(),
      );
      
      // Save to Firestore
      final docRef = await _firestore
          .collection('transactions')
          .add(transaction.toFirestore());
      
      return {
        'success': true,
        'transaction_id': docRef.id,
        'data': classification,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to add transaction: ${e.toString()}',
      };
    }
  }

  /// Get transactions for a user
  Stream<List<model.Transaction>> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .orderBy('transaction_date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => model.Transaction.fromFirestore(doc))
          .toList();
    });
  }

  /// Get transactions for current month
  Stream<List<model.Transaction>> getCurrentMonthTransactions(String userId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .where('transaction_date', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('transaction_date',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('transaction_date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => model.Transaction.fromFirestore(doc))
          .toList();
    });
  }

  /// Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    await _firestore.collection('transactions').doc(transactionId).delete();
  }

  /// Update transaction
  Future<void> updateTransaction(
    String transactionId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection('transactions').doc(transactionId).update(updates);
  }
}
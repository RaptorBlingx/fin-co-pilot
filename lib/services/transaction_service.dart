import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as model;
import 'receipt_parser_agent.dart';
import 'analytics_service.dart';
import 'dart:convert';
import 'dart:io';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReceiptParserAgent _receiptParser = ReceiptParserAgent();
  late final GenerativeModel _classifier = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.1-flash-lite-preview',
    generationConfig: GenerationConfig(temperature: 0.2, maxOutputTokens: 1024),
  );

  /// Add transaction from receipt photo
  Future<Map<String, dynamic>> addTransactionFromReceipt({
    required String userId,
    required File imageFile,
    required String currency,
  }) async {
    try {
      // Parse receipt using AI
      final parseResult = await _receiptParser.parseReceipt(imageFile);
      
      // Track receipt scanning
      await AnalyticsService.logReceiptScanned(
        success: parseResult['success'],
        errorMessage: parseResult['success'] ? null : parseResult['error'],
      );
      
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

      // Update budget spending
      await _updateBudgetSpending(
        userId: userId,
        category: transaction.category,
        amount: transaction.amount,
        transactionDate: transaction.transactionDate,
      );

      // Track analytics
      await AnalyticsService.logTransactionAdded(
        method: 'receipt',
        category: transaction.category,
        amount: transaction.amount,
        merchant: transaction.merchant,
      );

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
      final prompt = '''Extract transaction details from this text. Return ONLY valid JSON:
{"amount": <number>, "category": "<Groceries|Dining|Transport|Entertainment|Shopping|Health|Bills|Education|Travel|Other>", "merchant": "<name or null>", "description": "<brief>", "confidence": <0.0-1.0>}

Text: "$description"''';
      final response = await _classifier.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final jsonStr = text.contains('{') ? text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1) : '';

      Map<String, dynamic> classification;
      if (jsonStr.isNotEmpty) {
        classification = json.decode(jsonStr) as Map<String, dynamic>;
      } else {
        classification = {
          'amount': 0.0,
          'category': 'Other',
          'merchant': null,
          'description': description,
          'confidence': 0.3,
        };
      }
      
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

      // Update budget spending
      await _updateBudgetSpending(
        userId: userId,
        category: transaction.category,
        amount: transaction.amount,
        transactionDate: transaction.transactionDate,
      );

      // Track analytics
      await AnalyticsService.logTransactionAdded(
        method: 'manual',
        category: transaction.category,
        amount: transaction.amount,
        merchant: transaction.merchant,
      );

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

  /// Get a single transaction by ID
  Future<model.Transaction?> getTransactionById(String transactionId) async {
    try {
      final doc = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .get();
      
      if (doc.exists) {
        return model.Transaction.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
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

  /// Update budget spending when a transaction is added
  Future<void> _updateBudgetSpending({
    required String userId,
    required String category,
    required double amount,
    required DateTime transactionDate,
  }) async {
    try {
      // Get the month of the transaction
      final month = '${transactionDate.year}-${transactionDate.month.toString().padLeft(2, '0')}';

      if (kDebugMode) print('🔍 UPDATE BUDGET: userId=$userId, category=$category, amount=$amount, month=$month');

      // Find the budget for this category and month
      final budgetQuery = await _firestore
          .collection('budgets')
          .where('user_id', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .where('month', isEqualTo: month)
          .limit(1)
          .get();

      if (kDebugMode) print('🔍 BUDGET QUERY: Found ${budgetQuery.docs.length} budgets');

      if (budgetQuery.docs.isNotEmpty) {
        final budgetDoc = budgetQuery.docs.first;
        final currentSpending = (budgetDoc.data()['currentSpending'] as num?)?.toDouble() ?? 0;
        final newSpending = currentSpending + amount;

        if (kDebugMode) print('✅ UPDATING BUDGET: ${budgetDoc.id} from $currentSpending to $newSpending');

        // Update the budget
        await _firestore.collection('budgets').doc(budgetDoc.id).update({
          'currentSpending': newSpending,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        if (kDebugMode) print('✅ BUDGET UPDATED SUCCESSFULLY');
      } else {
        if (kDebugMode) print('⚠️ NO BUDGET FOUND for category: $category in month: $month');
      }
    } catch (e) {
      // Log error but don't fail the transaction
      if (kDebugMode) print('❌ Error updating budget spending: $e');
    }
  }

  /// Public method to update budget spending (for use by other screens)
  Future<void> updateBudgetSpendingPublic({
    required String userId,
    required String category,
    required double amount,
    required DateTime transactionDate,
  }) async {
    await _updateBudgetSpending(
      userId: userId,
      category: category,
      amount: amount,
      transactionDate: transactionDate,
    );
  }
}
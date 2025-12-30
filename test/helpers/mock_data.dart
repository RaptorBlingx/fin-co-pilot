import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fin_copilot/models/transaction.dart' as models;

/// Simplified mock data factories for testing
///
/// Provides basic test data for core models

class MockData {
  static const String testUserId = 'test-user-123';
  static const String testPartnerUserId = 'test-partner-456';

  // =================================================================
  // TRANSACTIONS
  // =================================================================

  static models.Transaction createTransaction({
    String? id,
    String? userId,
    double? amount,
    String? category,
    String? merchant,
    String? description,
    DateTime? date,
    models.TransactionType? type,
  }) {
    return models.Transaction(
      id: id ?? 'txn-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? testUserId,
      amount: amount ?? 50.0,
      currency: 'USD',
      category: category ?? 'Dining',
      type: type ?? models.TransactionType.expense,
      merchant: merchant ?? 'Starbucks',
      description: description ?? 'Coffee',
      date: date ?? DateTime.now(),
      metadata: models.TransactionMetadata(
        source: 'manual',
        confidence: 1.0,
        verified: true,
        edited: false,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static List<models.Transaction> createTransactionList({
    int count = 10,
    String? userId,
    DateTime? startDate,
  }) {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    return List.generate(count, (index) {
      return createTransaction(
        id: 'txn-$index',
        userId: userId,
        amount: 10.0 + (index * 5),
        category: _getRandomCategory(index),
        merchant: _getRandomMerchant(index),
        date: start.add(Duration(days: index)),
      );
    });
  }

  static String _getRandomCategory(int seed) {
    final categories = ['Dining', 'Groceries', 'Transport', 'Entertainment', 'Shopping', 'Bills'];
    return categories[seed % categories.length];
  }

  static String _getRandomMerchant(int seed) {
    final merchants = ['Starbucks', 'Walmart', 'Uber', 'Netflix', 'Amazon', 'Target'];
    return merchants[seed % merchants.length];
  }

  // =================================================================
  // EDGE CASES FOR TESTING
  // =================================================================

  /// Transaction with zero amount
  static models.Transaction createZeroAmountTransaction() {
    return createTransaction(amount: 0.0);
  }

  /// Transaction with very large amount
  static models.Transaction createLargeAmountTransaction() {
    return createTransaction(amount: 999999.99);
  }

  /// Transaction with negative amount (refund)
  static models.Transaction createRefundTransaction() {
    return createTransaction(
      amount: -50.0,
      description: 'Refund',
    );
  }

  /// Transaction with long description
  static models.Transaction createLongDescriptionTransaction() {
    return createTransaction(
      description: 'This is a very long description that should be truncated in the UI to prevent layout issues and ensure proper display across different screen sizes',
    );
  }

  /// Transaction with special characters in merchant name
  static models.Transaction createSpecialCharsTransaction() {
    return createTransaction(
      merchant: 'Café & Brasserie "L\'Ami"',
    );
  }

  /// Transaction from SMS source
  static models.Transaction createSMSTransaction() {
    return models.Transaction(
      id: 'txn-sms-123',
      userId: testUserId,
      amount: 45.99,
      currency: 'USD',
      category: 'Dining',
      type: models.TransactionType.expense,
      merchant: 'Restaurant',
      description: 'Payment via SMS',
      date: DateTime.now(),
      metadata: models.TransactionMetadata(
        source: 'sms',
        confidence: 0.95,
        verified: false,
        edited: false,
        aiAgent: 'gemini-2.5-flash',
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Transaction from receipt OCR
  static models.Transaction createReceiptTransaction() {
    return models.Transaction(
      id: 'txn-receipt-123',
      userId: testUserId,
      amount: 87.50,
      currency: 'USD',
      category: 'Groceries',
      type: models.TransactionType.expense,
      merchant: 'Whole Foods',
      description: 'Grocery shopping',
      date: DateTime.now(),
      receipt: models.ReceiptInfo(
        imageUrl: 'https://example.com/receipt.jpg',
        uploadedAt: DateTime.now(),
      ),
      metadata: models.TransactionMetadata(
        source: 'receipt',
        confidence: 0.98,
        verified: true,
        edited: false,
        aiAgent: 'gemini-2.5-flash',
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // =================================================================
  // TIMESTAMPS
  // =================================================================

  static Timestamp timestamp({DateTime? date}) {
    return Timestamp.fromDate(date ?? DateTime.now());
  }

  static Timestamp timestampDaysAgo(int days) {
    return Timestamp.fromDate(
      DateTime.now().subtract(Duration(days: days)),
    );
  }

  static Timestamp timestampHoursAgo(int hours) {
    return Timestamp.fromDate(
      DateTime.now().subtract(Duration(hours: hours)),
    );
  }

  // =================================================================
  // TEST DATA SETS
  // =================================================================

  /// Get a balanced set of transactions for testing
  static List<models.Transaction> getTestDataSet({String? userId}) {
    return [
      createTransaction(
        userId: userId,
        category: 'Dining',
        amount: 45.50,
        merchant: 'Chipotle',
      ),
      createTransaction(
        userId: userId,
        category: 'Groceries',
        amount: 120.00,
        merchant: 'Walmart',
      ),
      createTransaction(
        userId: userId,
        category: 'Transport',
        amount: 15.75,
        merchant: 'Uber',
      ),
      createTransaction(
        userId: userId,
        category: 'Entertainment',
        amount: 15.99,
        merchant: 'Netflix',
      ),
      createTransaction(
        userId: userId,
        category: 'Shopping',
        amount: 89.99,
        merchant: 'Amazon',
      ),
    ];
  }

  /// Get test data with edge cases
  static List<models.Transaction> getEdgeCaseDataSet() {
    return [
      createZeroAmountTransaction(),
      createLargeAmountTransaction(),
      createRefundTransaction(),
      createLongDescriptionTransaction(),
      createSpecialCharsTransaction(),
      createSMSTransaction(),
      createReceiptTransaction(),
    ];
  }
}

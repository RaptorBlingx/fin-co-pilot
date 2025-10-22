import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
// TODO: Replace telephony with sms_advanced or similar - telephony is discontinued
// import 'package:telephony/telephony.dart';
import 'bank_sms_patterns.dart';
import '../notification_service.dart';
import '../../models/sms_transaction.dart';

/// SMS Listener Service for automatic transaction capture
/// 
/// IMPORTANT: Temporarily disabled - telephony package discontinued
/// TODO: Migrate to sms_advanced or alternative SMS package
///
/// Week 2 Killer Feature: SMS Auto-Parsing
/// - Monitors incoming SMS messages
/// - Detects bank transaction alerts
/// - Parses transaction details (95%+ accuracy)
/// - Sends one-tap confirmation notifications
/// - Target: 80% automatic capture, <2 sec processing
///
/// Background Service: Runs even when app is closed
class SmsListenerService {
  static final SmsListenerService _instance = SmsListenerService._internal();
  factory SmsListenerService() => _instance;
  SmsListenerService._internal();

  // final Telephony _telephony = Telephony.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  bool _isListening = false;
  String? _currentUserId;

  /// Initialize SMS listener
  Future<bool> initialize(String userId) async {
    // TODO: Implement with new SMS package
    _currentUserId = userId;
    return false;
    /*
    _currentUserId = userId;

    try {
      // Request SMS permissions
      final permissionsGranted = await _telephony.requestSmsPermissions;
      if (permissionsGranted == false) {
        return false;
      }

      // Start listening for incoming SMS
      await _startListening();

      return true;
    } catch (e) {
      print('SMS listener initialization failed: $e');
      return false;
    }
    */
  }

  /// Start listening for SMS
  Future<void> _startListening() async {
    /*
    if (_isListening) return;

    // Listen for incoming SMS
    _telephony.listenIncomingSms(
      onNewMessage: _onNewMessage,
      onBackgroundMessage: _onBackgroundMessage,
      listenInBackground: true,
    );

    _isListening = true;
    */
  }

  /// Stop listening for SMS
  Future<void> stopListening() async {
    // Note: telephony package doesn't have explicit stop method
    // Listener is managed by the system
    _isListening = false;
    _currentUserId = null;
  }

  /// Handle incoming SMS (foreground)
  Future<void> _onNewMessage(dynamic message) async {
    // await _processMessage(message);
  }

  /// Handle incoming SMS (background)
  static Future<void> _onBackgroundMessage(dynamic message) async {
    /*
    // Background handler must be static
    // Process the message
    final service = SmsListenerService();
    await service._processMessage(message);
    */
  }

  /// Process SMS message
  Future<void> _processMessage(dynamic message) async {
    /*
    try {
      final sender = message.address ?? 'Unknown';
      final body = message.body ?? '';
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        message.date ?? DateTime.now().millisecondsSinceEpoch,
      );

      // Skip if user ID not set
      if (_currentUserId == null) return;

      // Check if SMS is from a bank
      if (!BankSmsPatterns.isFromBank(sender)) {
        return;
      }

      // Check if SMS looks like a transaction
      if (!BankSmsPatterns.looksLikeTransaction(body)) {
        return;
      }

      // Parse transaction details
      final parsed = BankSmsPatterns.parseTransaction(sender, body);
      if (parsed == null) {
        return;
      }

      // Only process if confidence is high enough (>= 0.6)
      final confidence = parsed['confidence'] as double;
      if (confidence < 0.6) {
        return;
      }

      // Create SmsTransaction object
      final smsTransaction = SmsTransaction(
        id: '', // Will be set by Firestore
        userId: _currentUserId!,
        smsBody: body,
        sender: sender,
        parsed: SmsTransactionParsed(
          amount: (parsed['amount'] as num).abs().toDouble(),
          merchant: parsed['merchant'] as String,
          date: timestamp,
          cardLast4: parsed['cardLast4'] as String?,
          confidence: confidence,
          suggestedCategory: _suggestCategory(parsed['merchant'] as String),
        ),
        status: SmsTransactionStatus.pending,
        receivedAt: timestamp,
        expiresAt: timestamp.add(const Duration(hours: 48)),
        confirmedAt: null,
        savedTransactionId: null,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection('sms_transactions')
          .add(smsTransaction.toFirestore());

      // Send confirmation notification
      await _sendConfirmationNotification(
        docRef.id,
        smsTransaction,
      );

      print('SMS transaction saved: ${docRef.id}');
      print('Amount: \$${smsTransaction.parsed.amount}, Merchant: ${smsTransaction.parsed.merchant}');
    } catch (e) {
      print('Error processing SMS: $e');
    }
    */
  }

  /// Send one-tap confirmation notification
  Future<void> _sendConfirmationNotification(
    String smsTransactionId,
    SmsTransaction transaction,
  ) async {
    final amount = transaction.parsed.amount;
    final merchant = transaction.parsed.merchant;
    final category = transaction.parsed.suggestedCategory;

    // Get category emoji
    final emoji = _getCategoryEmoji(category);

    // Create notification
    await _notificationService.showSmsConfirmation(
      id: smsTransactionId.hashCode,
      title: 'New Transaction Detected',
      body: '$emoji \$$amount at $merchant - $category?',
      smsTransactionId: smsTransactionId,
    );
  }

  /// Suggest category based on merchant
  String _suggestCategory(String merchant) {
    final lowerMerchant = merchant.toLowerCase();

    // Food & Dining
    if (_containsAny(lowerMerchant, [
      'restaurant',
      'cafe',
      'coffee',
      'starbucks',
      'mcdonald',
      'chipotle',
      'subway',
      'pizza',
      'burger',
      'grocery',
      'whole foods',
      'trader joe',
      'safeway',
      'kroger',
    ])) {
      return 'Food & Dining';
    }

    // Shopping
    if (_containsAny(lowerMerchant, [
      'amazon',
      'walmart',
      'target',
      'costco',
      'best buy',
      'mall',
      'store',
    ])) {
      return 'Shopping';
    }

    // Transportation
    if (_containsAny(lowerMerchant, [
      'uber',
      'lyft',
      'gas',
      'shell',
      'chevron',
      'parking',
      'toll',
    ])) {
      return 'Transportation';
    }

    // Entertainment
    if (_containsAny(lowerMerchant, [
      'netflix',
      'spotify',
      'hulu',
      'cinema',
      'theater',
      'movie',
    ])) {
      return 'Entertainment';
    }

    // Bills & Utilities
    if (_containsAny(lowerMerchant, [
      'electric',
      'water',
      'internet',
      'phone',
      'verizon',
      'at&t',
      't-mobile',
    ])) {
      return 'Bills & Utilities';
    }

    return 'Other';
  }

  /// Get category emoji
  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Food & Dining':
        return '🍽️';
      case 'Shopping':
        return '🛍️';
      case 'Transportation':
        return '🚗';
      case 'Entertainment':
        return '🎬';
      case 'Bills & Utilities':
        return '💡';
      case 'Health & Medical':
        return '⚕️';
      case 'Travel':
        return '✈️';
      case 'Education':
        return '📚';
      default:
        return '💳';
    }
  }

  /// Check if string contains any of the keywords
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Confirm SMS transaction (called when user taps YES)
  Future<bool> confirmTransaction(String smsTransactionId) async {
    try {
      // Get SMS transaction
      final doc = await _firestore
          .collection('sms_transactions')
          .doc(smsTransactionId)
          .get();

      if (!doc.exists) return false;

      final smsTransaction = SmsTransaction.fromFirestore(doc);

      // Create actual transaction
      final transaction = {
        'userId': smsTransaction.userId,
        'amount': smsTransaction.parsed.amount,
        'currency': 'USD',
        'category': smsTransaction.parsed.suggestedCategory,
        'type': 'expense',
        'merchant': smsTransaction.parsed.merchant,
        'description': 'Auto-captured from SMS',
        'date': Timestamp.fromDate(smsTransaction.parsed.date),
        'paymentMethod': 'card',
        'paymentDetails': smsTransaction.parsed.cardLast4 != null
            ? {'cardLast4': smsTransaction.parsed.cardLast4}
            : null,
        'metadata': {
          'source': 'sms',
          'confidence': smsTransaction.parsed.confidence,
          'verified': true,
          'edited': false,
          'aiAgent': 'financial_copilot',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save transaction
      final transactionRef =
          await _firestore.collection('transactions').add(transaction);

      // Update SMS transaction status
      await _firestore
          .collection('sms_transactions')
          .doc(smsTransactionId)
          .update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
        'savedTransactionId': transactionRef.id,
      });

      // Show success notification
      await _notificationService.showTransactionSaved(
        merchant: smsTransaction.parsed.merchant,
        amount: smsTransaction.parsed.amount,
      );

      return true;
    } catch (e) {
      print('Error confirming SMS transaction: $e');
      return false;
    }
  }

  /// Reject SMS transaction (called when user taps NO)
  Future<bool> rejectTransaction(String smsTransactionId) async {
    try {
      await _firestore
          .collection('sms_transactions')
          .doc(smsTransactionId)
          .update({
        'status': 'rejected',
      });

      return true;
    } catch (e) {
      print('Error rejecting SMS transaction: $e');
      return false;
    }
  }

  /// Get pending SMS transactions
  Future<List<SmsTransaction>> getPendingTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('sms_transactions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt', descending: false)
          .orderBy('receivedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SmsTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting pending transactions: $e');
      return [];
    }
  }

  /// Check if SMS permissions are granted
  Future<bool> hasPermissions() async {
    // TODO: Implement with new SMS package
    return false;
    // final permissionsGranted = await _telephony.requestSmsPermissions;
    // return permissionsGranted ?? false;
  }
}

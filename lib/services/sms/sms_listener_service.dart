import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/sms_transaction.dart';

/// SMS Listener Service - DISABLED
class SmsListenerService {
  static final SmsListenerService _instance = SmsListenerService._internal();
  factory SmsListenerService() => _instance;
  SmsListenerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> initialize(String userId) async {
    print('SMS listener disabled');
    return false;
  }

  Future<void> stopListening() async {}

  Future<bool> confirmTransaction(String smsTransactionId) async {
    return false;
  }

  Future<bool> rejectTransaction(String smsTransactionId) async {
    return false;
  }

  Future<List<SmsTransaction>> getPendingTransactions(String userId) async {
    return [];
  }

  Future<bool> hasPermissions() async {
    return false;
  }
}

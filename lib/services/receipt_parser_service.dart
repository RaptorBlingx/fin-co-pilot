import 'dart:io';
import '../models/transaction.dart';

class ReceiptParserService {

  /// Parse receipt image and extract transaction data
  /// For now, returns mock data - will implement actual image parsing later
  Future<Map<String, dynamic>> parseReceiptImage(File imageFile) async {
    try {
      // TODO: Implement actual image parsing with Gemini Vision
      // For now, return mock data for testing
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing
      
      return {
        'merchant': 'Sample Store',
        'amount': 25.99,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'description': 'Sample receipt purchase',
        'items': [
          {'name': 'Sample Item 1', 'price': 15.99, 'quantity': 1},
          {'name': 'Sample Item 2', 'price': 10.00, 'quantity': 1},
        ],
        'category': 'Shopping',
        'tax': 2.08,
        'tip': 0.0,
        'paymentMethod': 'Card',
        'confidence': 0.8,
      };
      
    } catch (e) {
      print('Receipt parsing error: $e');
      return {
        'error': 'Failed to parse receipt: $e',
        'merchant': null,
        'amount': 0.0,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'description': 'Receipt parsing failed',
        'items': <Map<String, dynamic>>[],
        'category': 'Other',
        'tax': 0.0,
        'tip': 0.0,
        'paymentMethod': null,
        'confidence': 0.0,
      };
    }
  }

  /// Create Transaction from parsed receipt data
  Transaction createTransactionFromReceipt(
    Map<String, dynamic> receiptData,
    String userId,
    String? receiptImageUrl,
  ) {
    final amount = _parseAmount(receiptData['amount']);
    final dateStr = receiptData['date'] as String?;
    final date = _parseDate(dateStr);
    
    return Transaction.create(
      userId: userId,
      amount: amount,
      description: _buildDescription(receiptData),
      category: receiptData['category'] ?? 'Other',
      merchant: receiptData['merchant'] ?? 'Unknown Merchant',
      date: date,
      receiptImageUrl: receiptImageUrl,
      notes: _buildNotes(receiptData),
      metadata: {
        'parsedData': receiptData,
        'confidence': receiptData['confidence'] ?? 0.0,
        'items': receiptData['items'] ?? [],
        'tax': receiptData['tax'] ?? 0.0,
        'tip': receiptData['tip'] ?? 0.0,
        'paymentMethod': receiptData['paymentMethod'],
      },
    );
  }

  /// Validate and clean parsed data
  Map<String, dynamic> _validateAndCleanData(Map<String, dynamic> data) {
    return {
      'merchant': data['merchant']?.toString(),
      'amount': _parseAmount(data['amount']),
      'date': _validateDateString(data['date']),
      'description': data['description']?.toString() ?? 'Receipt purchase',
      'items': _validateItems(data['items']),
      'category': _validateCategory(data['category']),
      'tax': _parseAmount(data['tax']),
      'tip': _parseAmount(data['tip']),
      'paymentMethod': data['paymentMethod']?.toString(),
      'confidence': _parseConfidence(data['confidence']),
    };
  }

  /// Parse amount to double
  double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) {
      // Remove currency symbols and parse
      final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanAmount) ?? 0.0;
    }
    return 0.0;
  }

  /// Parse date string
  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      // Try parsing different formats
      final formats = [
        RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
        RegExp(r'(\d{2})/(\d{2})/(\d{4})'),
        RegExp(r'(\d{2})-(\d{2})-(\d{4})'),
      ];
      
      for (final format in formats) {
        final match = format.firstMatch(dateStr);
        if (match != null) {
          try {
            if (dateStr.contains('-') && dateStr.length == 10) {
              return DateTime.parse(dateStr);
            } else if (dateStr.contains('/')) {
              final parts = dateStr.split('/');
              if (parts.length == 3) {
                final month = int.parse(parts[0]);
                final day = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                return DateTime(year, month, day);
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
      
      return DateTime.now();
    }
  }

  /// Validate date string format
  String _validateDateString(dynamic date) {
    if (date == null) return DateTime.now().toIso8601String().split('T')[0];
    
    final parsedDate = _parseDate(date.toString());
    return parsedDate.toIso8601String().split('T')[0];
  }

  /// Validate items array
  List<Map<String, dynamic>> _validateItems(dynamic items) {
    if (items == null || items is! List) return [];
    
    return items.map((item) {
      if (item is! Map<String, dynamic>) return <String, dynamic>{};
      
      return {
        'name': item['name']?.toString() ?? 'Unknown Item',
        'price': _parseAmount(item['price']),
        'quantity': _parseQuantity(item['quantity']),
      };
    }).toList();
  }

  /// Parse quantity
  int _parseQuantity(dynamic quantity) {
    if (quantity == null) return 1;
    if (quantity is int) return quantity;
    if (quantity is double) return quantity.round();
    if (quantity is String) {
      return int.tryParse(quantity) ?? 1;
    }
    return 1;
  }

  /// Validate category
  String _validateCategory(dynamic category) {
    final categoryStr = category?.toString() ?? 'Other';
    
    if (TransactionCategories.categories.contains(categoryStr)) {
      return categoryStr;
    }
    
    return 'Other';
  }

  /// Parse confidence score
  double _parseConfidence(dynamic confidence) {
    final conf = _parseAmount(confidence);
    return conf.clamp(0.0, 1.0);
  }

  /// Build transaction description from receipt data
  String _buildDescription(Map<String, dynamic> data) {
    final merchant = data['merchant']?.toString();
    final items = data['items'] as List<Map<String, dynamic>>? ?? [];
    
    if (merchant != null && merchant.isNotEmpty) {
      if (items.isNotEmpty && items.length <= 3) {
        final itemNames = items.map((item) => item['name']).join(', ');
        return '$merchant: $itemNames';
      }
      return 'Purchase at $merchant';
    }
    
    if (items.isNotEmpty) {
      final itemNames = items.take(3).map((item) => item['name']).join(', ');
      return items.length > 3 ? '$itemNames and more' : itemNames;
    }
    
    return data['description']?.toString() ?? 'Receipt purchase';
  }

  /// Build notes from receipt data
  String? _buildNotes(Map<String, dynamic> data) {
    final notes = <String>[];
    
    final confidence = data['confidence'] as double? ?? 0.0;
    if (confidence < 0.8) {
      notes.add('Low confidence parsing (${(confidence * 100).toStringAsFixed(0)}%)');
    }
    
    final tax = _parseAmount(data['tax']);
    final tip = _parseAmount(data['tip']);
    
    if (tax > 0) notes.add('Tax: \$${tax.toStringAsFixed(2)}');
    if (tip > 0) notes.add('Tip: \$${tip.toStringAsFixed(2)}');
    
    final paymentMethod = data['paymentMethod']?.toString();
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      notes.add('Payment: $paymentMethod');
    }
    
    return notes.isNotEmpty ? notes.join(' • ') : null;
  }
}
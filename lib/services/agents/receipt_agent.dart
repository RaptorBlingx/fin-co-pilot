import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'dart:typed_data';
import 'dart:convert';

/// Agent 5: Receipt Agent
/// OCR from receipt photos and extracts ALL items with prices
/// This is THE MOAT - enables item-level tracking and price intelligence
class ReceiptAgent {
  late final GenerativeModel _visionModel;

  ReceiptAgent() {
    // Use Gemini 2.5 Flash-Lite for fast, cost-effective receipt OCR
    // Gemini 2.5 Flash-Lite: Optimized for low-latency, high-volume OCR tasks
    // Supports image analysis with text extraction at lower cost
    // ignore: deprecated_member_use
    _visionModel = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash-lite',
    );
  }

  /// Extract transaction data from receipt photo
  Future<ReceiptExtractionResult> extractFromReceipt({
    required Uint8List imageBytes,
  }) async {
    try {
      // Build vision prompt
      final prompt = _buildReceiptExtractionPrompt();

      // Create content with image and text
      final response = await _visionModel.generateContent([
        Content.multi([
          TextPart(prompt),
          InlineDataPart('image/jpeg', imageBytes),
        ])
      ]);

      final responseText = response.text ?? '';

      // Parse structured receipt data
      final receiptData = _parseReceiptResponse(responseText);

      return receiptData;
    } catch (e) {
      print('Receipt Agent Error: $e');
      return ReceiptExtractionResult(
        success: false,
        errorMessage: 'Failed to process receipt: ${e.toString()}',
      );
    }
  }

  /// Build receipt extraction prompt
  String _buildReceiptExtractionPrompt() {
    return '''
You are a receipt OCR specialist. Extract ALL information from this receipt.

Extract:
1. Merchant/Store name
2. Date and time of purchase
3. ALL individual items with prices
4. Subtotal, tax, total
5. Payment method (if visible)
6. Location/address (if visible)

For each item, extract:
- Item name/description
- Quantity (if shown)
- Unit price
- Total price for that item
- Category inference (Produce, Dairy, Meat, Bakery, etc.)

IMPORTANT:
- Extract EVERY item, no matter how small
- Include discounts/coupons as negative amounts
- Preserve exact item names from receipt
- If quantity not shown, assume 1

Response format (JSON only):
{
  "merchant": "Store Name",
  "date": "2025-10-17T14:30:00",
  "location": "City, State",
  "items": [
    {
      "name": "Organic Milk 1 Gal",
      "quantity": 1,
      "unit_price": 4.99,
      "total_price": 4.99,
      "category": "Dairy"
    },
    {
      "name": "Eggs Large 12ct",
      "quantity": 2,
      "unit_price": 3.49,
      "total_price": 6.98,
      "category": "Dairy"
    }
  ],
  "subtotal": 47.23,
  "tax": 3.78,
  "total": 50.01,
  "payment_method": "Credit Card",
  "confidence": 0.95
}

Extract all data and respond with JSON only:
''';
  }

  /// Parse receipt extraction response
  ReceiptExtractionResult _parseReceiptResponse(String responseText) {
    try {
      // Clean JSON
      String cleanedJson = responseText.trim()
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Find JSON boundaries
      final jsonStart = cleanedJson.indexOf('{');
      final jsonEnd = cleanedJson.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        cleanedJson = cleanedJson.substring(jsonStart, jsonEnd + 1);
      }

      // Parse JSON
      final Map<String, dynamic> json = jsonDecode(cleanedJson);

      // Extract items
      final List<ReceiptItem> items = [];
      if (json['items'] is List) {
        for (final itemJson in json['items']) {
          items.add(ReceiptItem(
            name: itemJson['name']?.toString() ?? 'Unknown Item',
            quantity: itemJson['quantity'] ?? 1,
            unitPrice: _parseDouble(itemJson['unit_price']) ?? 0.0,
            totalPrice: _parseDouble(itemJson['total_price']) ?? 0.0,
            category: itemJson['category']?.toString(),
          ));
        }
      }

      return ReceiptExtractionResult(
        success: true,
        merchant: json['merchant']?.toString(),
        date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
        location: json['location']?.toString(),
        items: items,
        subtotal: _parseDouble(json['subtotal']),
        tax: _parseDouble(json['tax']),
        total: _parseDouble(json['total']) ?? 0.0,
        paymentMethod: json['payment_method']?.toString(),
        confidence: _parseDouble(json['confidence']) ?? 0.0,
      );
    } catch (e) {
      print('Receipt parsing error: $e');
      return ReceiptExtractionResult(
        success: false,
        errorMessage: 'Failed to parse receipt data',
      );
    }
  }

  /// Parse double value
  double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Receipt extraction result
class ReceiptExtractionResult {
  final bool success;
  final String? merchant;
  final DateTime? date;
  final String? location;
  final List<ReceiptItem> items;
  final double? subtotal;
  final double? tax;
  final double total;
  final String? paymentMethod;
  final double confidence;
  final String? errorMessage;

  ReceiptExtractionResult({
    required this.success,
    this.merchant,
    this.date,
    this.location,
    List<ReceiptItem>? items,
    this.subtotal,
    this.tax,
    double? total,
    this.paymentMethod,
    double? confidence,
    this.errorMessage,
  })  : items = items ?? [],
        total = total ?? 0.0,
        confidence = confidence ?? 0.0;

  /// Get main transaction category based on items
  String get primaryCategory {
    if (items.isEmpty) return 'Other';

    // Count categories
    final Map<String, int> categoryCount = {};
    for (final item in items) {
      if (item.category != null) {
        categoryCount[item.category!] = (categoryCount[item.category!] ?? 0) + 1;
      }
    }

    // Return most common category
    if (categoryCount.isEmpty) return 'Groceries';

    final sortedEntries = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.first.key;
  }

  /// Get summary description
  String get summaryDescription {
    if (items.isEmpty) return 'Purchase';
    if (items.length == 1) return items.first.name;
    return '${items.length} items';
  }
}

/// Individual receipt item
class ReceiptItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? category;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.category,
  });

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'category': category,
    };
  }
}

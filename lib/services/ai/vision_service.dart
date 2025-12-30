import 'package:firebase_ai/firebase_ai.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

/// Vision Agent - Receipt OCR only (15% of interactions)
///
/// Per Knowledge Base: AI_AGENTS_SPECIFICATION.md
/// - Model: Gemini 2.5 Flash-Lite
/// - Temperature: 0.2 (low for accuracy)
/// - MaxTokens: 2048
///
/// Purpose:
/// - Extract items, prices, merchant, date from receipt images
/// - High accuracy OCR (90%+ target)
/// - Pass to Financial Copilot for price analysis
class VisionService {
  final GenerativeModel _model;

  // System prompt from Knowledge Base: AI_AGENTS_SPECIFICATION.md
  static const String _systemPrompt = '''
You are a Vision Agent specialized in receipt OCR for a financial wellness app.

YOUR ONLY JOB:
Extract all information from receipt images with maximum accuracy.

WHAT TO EXTRACT:
1. Merchant name
2. Purchase date (format: YYYY-MM-DD)
3. All items purchased (name, quantity, unit price, total price)
4. Subtotal
5. Tax amount
6. Tip amount (if present)
7. Total amount
8. Payment method (if visible: cash, card, etc.)
9. Card last 4 digits (if visible)

EXTRACTION RULES:
- Extract EVERY item, even if the list is long
- Preserve exact item names (don't simplify)
- All amounts in decimal format (e.g., 5.50, not \$5.50)
- Date must be YYYY-MM-DD format
- If something is unclear, mark confidence as lower
- Don't make assumptions - only extract what you see

OUTPUT FORMAT:
Return ONLY valid JSON (no markdown, no extra text):
{
  "merchant": "Store Name",
  "date": "YYYY-MM-DD",
  "items": [
    {
      "name": "Item name",
      "quantity": 1,
      "unitPrice": 0.00,
      "totalPrice": 0.00
    }
  ],
  "subtotal": 0.00,
  "tax": 0.00,
  "tip": 0.00,
  "total": 0.00,
  "paymentMethod": "card|cash|null",
  "cardLast4": "1234|null",
  "confidence": 0.0-1.0
}

ACCURACY IS CRITICAL:
- 90%+ accuracy target
- Double-check numbers
- Verify totals match (subtotal + tax + tip = total)
- If receipt is blurry/unclear, lower confidence score
''';

  VisionService()
      : _model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.5-flash-lite', // Optimized for OCR
        );

  /// Scan receipt and extract all data
  ///
  /// Target: <5 sec processing, 90%+ accuracy
  Future<Map<String, dynamic>> scanReceipt(File imageFile) async {
    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Create content with image and prompt
      final prompt = '''
$_systemPrompt

Analyze this receipt image and extract all information.
Return ONLY the JSON response, no additional text.
''';

      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          InlineDataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final responseText = response.text ?? '';

      // Parse JSON from response
      final extracted = _parseReceiptData(responseText);

      return {
        'success': true,
        'data': extracted,
      };
    } catch (e) {
      print('VisionService error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Scan receipt from bytes (for camera captures)
  Future<Map<String, dynamic>> scanReceiptFromBytes(
      Uint8List imageBytes) async {
    try {
      final prompt = '''
$_systemPrompt

Analyze this receipt image and extract all information.
Return ONLY the JSON response, no additional text.
''';

      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          InlineDataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final responseText = response.text ?? '';

      // Parse JSON from response
      final extracted = _parseReceiptData(responseText);

      return {
        'success': true,
        'data': extracted,
      };
    } catch (e) {
      print('VisionService error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Parse receipt data from AI response
  Map<String, dynamic> _parseReceiptData(String responseText) {
    try {
      // Extract JSON from response (may be wrapped in markdown)
      final jsonMatch =
          RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(responseText);
      final jsonString = jsonMatch?.group(1) ?? responseText;

      // Find JSON object
      final objectMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonString);
      if (objectMatch == null) {
        throw Exception('No JSON found in response');
      }

      final parsed = json.decode(objectMatch.group(0)!);

      // Validate required fields
      if (!parsed.containsKey('merchant') || !parsed.containsKey('total')) {
        throw Exception('Missing required fields in parsed data');
      }

      // Ensure items is a list
      if (parsed['items'] == null) {
        parsed['items'] = [];
      }

      // Ensure numeric fields are doubles
      parsed['subtotal'] = (parsed['subtotal'] ?? 0).toDouble();
      parsed['tax'] = (parsed['tax'] ?? 0).toDouble();
      parsed['tip'] = (parsed['tip'] ?? 0).toDouble();
      parsed['total'] = (parsed['total'] ?? 0).toDouble();
      parsed['confidence'] = (parsed['confidence'] ?? 0.85).toDouble();

      // Process items
      final items = parsed['items'] as List;
      parsed['items'] = items.map((item) {
        return {
          'name': item['name'] ?? '',
          'quantity': (item['quantity'] ?? 1).toInt(),
          'unitPrice': (item['unitPrice'] ?? 0).toDouble(),
          'totalPrice': (item['totalPrice'] ?? 0).toDouble(),
        };
      }).toList();

      return parsed;
    } catch (e) {
      print('Error parsing receipt data: $e');
      // Return empty receipt data
      return {
        'merchant': 'Unknown',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'items': [],
        'subtotal': 0.0,
        'tax': 0.0,
        'tip': 0.0,
        'total': 0.0,
        'paymentMethod': null,
        'cardLast4': null,
        'confidence': 0.0,
        'error': e.toString(),
      };
    }
  }

  /// Validate receipt data quality
  bool validateReceipt(Map<String, dynamic> receiptData) {
    try {
      // Check confidence threshold
      final confidence = receiptData['confidence'] ?? 0.0;
      if (confidence < 0.7) {
        return false;
      }

      // Check if total matches calculation
      final subtotal = receiptData['subtotal'] ?? 0.0;
      final tax = receiptData['tax'] ?? 0.0;
      final tip = receiptData['tip'] ?? 0.0;
      final total = receiptData['total'] ?? 0.0;

      final calculatedTotal = subtotal + tax + tip;
      final difference = (calculatedTotal - total).abs();

      // Allow 1 cent difference for rounding
      if (difference > 0.01) {
        print('Total mismatch: calculated=$calculatedTotal, actual=$total');
        return false;
      }

      // Check if items exist
      final items = receiptData['items'] as List? ?? [];
      if (items.isEmpty && total > 0) {
        print('No items found but total > 0');
        return false;
      }

      return true;
    } catch (e) {
      print('Error validating receipt: $e');
      return false;
    }
  }

  /// Get receipt summary for display
  String getReceiptSummary(Map<String, dynamic> receiptData) {
    final merchant = receiptData['merchant'] ?? 'Unknown store';
    final date = receiptData['date'] ?? 'Unknown date';
    final total = receiptData['total'] ?? 0.0;
    final itemCount = (receiptData['items'] as List?)?.length ?? 0;

    return '$merchant - $date\n$itemCount items, Total: \$${total.toStringAsFixed(2)}';
  }

  /// Calculate price comparison data
  ///
  /// This prepares data for Financial Copilot to analyze
  Map<String, dynamic> preparePriceAnalysis(Map<String, dynamic> receiptData) {
    final items = receiptData['items'] as List? ?? [];

    return {
      'merchant': receiptData['merchant'],
      'date': receiptData['date'],
      'itemCount': items.length,
      'total': receiptData['total'],
      'items': items.map((item) {
        return {
          'name': item['name'],
          'price': item['totalPrice'],
          'quantity': item['quantity'],
          'unitPrice': item['unitPrice'],
        };
      }).toList(),
      'readyForAnalysis': true,
    };
  }
}

/// Receipt data model for easier handling
class ReceiptData {
  final String merchant;
  final String date;
  final List<ReceiptItem> items;
  final double subtotal;
  final double tax;
  final double tip;
  final double total;
  final String? paymentMethod;
  final String? cardLast4;
  final double confidence;

  ReceiptData({
    required this.merchant,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.tip,
    required this.total,
    this.paymentMethod,
    this.cardLast4,
    required this.confidence,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];

    return ReceiptData(
      merchant: json['merchant'] ?? 'Unknown',
      date: json['date'] ?? DateTime.now().toIso8601String().split('T')[0],
      items: itemsList
          .map((item) => ReceiptItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      tip: (json['tip'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'],
      cardLast4: json['cardLast4'],
      confidence: (json['confidence'] ?? 0.85).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant': merchant,
      'date': date,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'tip': tip,
      'total': total,
      'paymentMethod': paymentMethod,
      'cardLast4': cardLast4,
      'confidence': confidence,
    };
  }
}

/// Receipt item model
class ReceiptItem {
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] ?? '',
      quantity: (json['quantity'] ?? 1).toInt(),
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

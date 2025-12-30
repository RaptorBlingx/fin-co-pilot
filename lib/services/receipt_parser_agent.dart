import 'package:firebase_ai/firebase_ai.dart';
import 'dart:convert';
import 'dart:io';

class ReceiptParserAgent {
  late final GenerativeModel _model;

  ReceiptParserAgent() {
    // Use Gemini 2.5 Flash-Lite for cost-effective receipt OCR
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-lite',
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 2048,
      ),
    );
  }
  
  /// Parse receipt image and extract structured data
  Future<Map<String, dynamic>> parseReceipt(File imageFile) async {
    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();
      
      // Create enhanced prompt for receipt parsing with examples
      final prompt = '''
You are an expert receipt parser. Analyze this receipt image and extract structured data.

CRITICAL RULES:
1. Extract ONLY what you can clearly see - use null for unclear fields
2. Total amount is the MOST IMPORTANT field - be very careful
3. Currency: Look for dollar, euro, pound, yen symbols or text like "USD", "EUR"
4. Date: Parse various formats (MM/DD/YYYY, DD-MM-YYYY, etc.) to YYYY-MM-DD
5. Merchant: Extract the business name, not the location
6. Items: Include ALL line items with accurate prices

EXAMPLES OF GOOD EXTRACTION:

Example 1 - Clear receipt:
Starbucks
123 Main St
Coffee - Grande         \$4.50
Croissant               \$3.25
Tax                     \$0.62
Total                   \$8.37
Card ending 1234

Result:
{
  "merchant": "Starbucks",
  "total": 8.37,
  "currency": "USD",
  "date": "2025-12-30",
  "items": [
    {"name": "Coffee - Grande", "price": 4.50, "quantity": 1},
    {"name": "Croissant", "price": 3.25, "quantity": 1}
  ],
  "tax": 0.62,
  "payment_method": "credit_card",
  "confidence": 0.95
}

Example 2 - Blurry receipt (low confidence):
[Blurry image where only total is clear: \$25.50]

Result:
{
  "merchant": null,
  "total": 25.50,
  "currency": "USD",
  "date": null,
  "items": [],
  "tax": null,
  "payment_method": null,
  "confidence": 0.4
}

Example 3 - Grocery receipt with multiple items:
Whole Foods Market
Bananas (3 @ \$0.59)    \$1.77
Milk                    \$4.99
Bread                   \$3.49
Eggs                    \$5.99
Subtotal               \$16.24
Tax                     \$0.81
Total                  \$17.05

Result:
{
  "merchant": "Whole Foods Market",
  "total": 17.05,
  "currency": "USD",
  "date": "2025-12-30",
  "items": [
    {"name": "Bananas", "price": 1.77, "quantity": 3},
    {"name": "Milk", "price": 4.99, "quantity": 1},
    {"name": "Bread", "price": 3.49, "quantity": 1},
    {"name": "Eggs", "price": 5.99, "quantity": 1}
  ],
  "tax": 0.81,
  "payment_method": null,
  "confidence": 0.90
}

REQUIRED OUTPUT FORMAT (JSON only, no markdown):
{
  "merchant": "Store Name or null",
  "total": 0.00,
  "currency": "USD",
  "date": "YYYY-MM-DD or null",
  "items": [{"name": "Item", "price": 0.00, "quantity": 1}],
  "tax": 0.00,
  "payment_method": "cash|credit_card|debit_card or null",
  "confidence": 0.0
}

CONFIDENCE SCORING:
- 0.9-1.0: All fields clear, high quality image
- 0.7-0.9: Most fields clear, some minor blur
- 0.5-0.7: Key fields (total, merchant) clear, others unclear
- 0.3-0.5: Only total or merchant clear
- 0.0-0.3: Very blurry, minimal information

Now analyze the provided receipt image and respond with ONLY the JSON (no markdown, no explanation):
''';

      // Send image to Gemini
      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          // Use InlineDataPart instead of DataPart
          InlineDataPart('image/jpeg', imageBytes),
        ])
      ]);
      
      final responseText = response.text ?? '';
      
      // Parse JSON response
      try {
        String cleanedJson = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final Map<String, dynamic> receiptData = jsonDecode(cleanedJson);
        
        // Task 2.5: Validate and handle edge cases
        final validated = _validateReceiptData(receiptData);
        
        return {
          'success': true,
          'data': validated['data'],
          'warnings': validated['warnings'],
        };
      } catch (e) {
        print('Receipt parsing error: $e');
        print('Response was: $responseText');
        
        return {
          'success': false,
          'error': 'Failed to parse receipt data',
          'raw_response': responseText,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Receipt parsing failed: ${e.toString()}',
      };
    }
  }
  
  /// Task 2.5: Validate receipt data and handle edge cases
  Map<String, dynamic> _validateReceiptData(Map<String, dynamic> data) {
    final warnings = <String>[];
    final validated = Map<String, dynamic>.from(data);
    
    // Edge Case 1: Blurry images (low confidence)
    final confidence = data['confidence'] as double? ?? 0.0;
    if (confidence < 0.5) {
      warnings.add('Low confidence parse - image may be blurry. Please verify all details.');
    }
    
    // Edge Case 2: Missing total (CRITICAL)
    if (data['total'] == null || data['total'] == 0) {
      warnings.add('CRITICAL: Could not extract total amount. Please enter manually.');
      validated['requires_manual_total'] = true;
    }
    
    // Edge Case 3: Non-receipt image detection
    if (data['merchant'] == null && data['total'] == null && confidence < 0.3) {
      warnings.add('This may not be a receipt. Please try again with a clear receipt photo.');
      validated['likely_not_receipt'] = true;
    }
    
    // Edge Case 4: Multiple items handling
    final items = data['items'] as List? ?? [];
    if (items.length > 10) {
      warnings.add('Large receipt with ${items.length} items. Creating summary transaction.');
      validated['is_bulk_transaction'] = true;
    }
    
    // Edge Case 5: Currency validation
    final currency = data['currency'] as String?;
    if (currency == null || currency.isEmpty) {
      validated['currency'] = 'USD'; // Default to USD
      warnings.add('Currency not detected, defaulting to USD');
    }
    
    // Edge Case 6: Date validation
    final dateStr = data['date'] as String?;
    if (dateStr != null) {
      try {
        final date = DateTime.parse(dateStr);
        // Check if date is in the future (likely OCR error)
        if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
          warnings.add('Date appears to be in the future. Please verify.');
          validated['date'] = DateTime.now().toIso8601String().split('T')[0];
        }
        // Check if date is too old (>1 year)
        if (date.isBefore(DateTime.now().subtract(const Duration(days: 365)))) {
          warnings.add('Receipt is over 1 year old. Please verify date.');
        }
      } catch (e) {
        warnings.add('Invalid date format detected.');
      }
    }
    
    // Edge Case 7: Validate total matches items sum
    if (items.isNotEmpty && data['total'] != null) {
      final itemsSum = items.fold<double>(
        0.0,
        (sum, item) => sum + ((item['price'] as num?)?.toDouble() ?? 0.0) * ((item['quantity'] as num?)?.toDouble() ?? 1.0),
      );
      final tax = (data['tax'] as num?)?.toDouble() ?? 0.0;
      final total = (data['total'] as num).toDouble();
      
      final expectedTotal = itemsSum + tax;
      final diff = (total - expectedTotal).abs();
      
      if (diff > 0.50) {
        warnings.add('Total (\$$total) doesn\'t match items+tax (\$${expectedTotal.toStringAsFixed(2)}). Please verify.');
      }
    }
    
    return {
      'data': validated,
      'warnings': warnings,
    };
  }
}
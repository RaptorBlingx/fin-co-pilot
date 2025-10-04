import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'dart:convert';
import 'dart:io';

class ReceiptParserAgent {
  late final GenerativeModel _model;
  
  ReceiptParserAgent() {
    // Use Gemini 2.5 Flash for receipt OCR
    // In production, you'd use Flash-Lite for cost savings
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',
    );
  }
  
  /// Parse receipt image and extract structured data
  Future<Map<String, dynamic>> parseReceipt(File imageFile) async {
    try {
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();
      
      // Create prompt for receipt parsing
      final prompt = '''
You are a receipt parser. Analyze this receipt image and extract the following information.

Extract these fields:
- merchant: Store/business name
- total: Total amount (number only, no currency symbol)
- currency: Currency code (USD, EUR, etc.) - infer from receipt
- date: Purchase date (YYYY-MM-DD format)
- items: List of items purchased with prices
- tax: Tax amount if visible
- payment_method: Payment method if visible (cash, credit, debit)

Respond with ONLY valid JSON in this exact format:
{
  "merchant": "Store Name",
  "total": 123.45,
  "currency": "USD",
  "date": "2025-10-04",
  "items": [
    {"name": "Item 1", "price": 10.00, "quantity": 1},
    {"name": "Item 2", "price": 5.50, "quantity": 2}
  ],
  "tax": 12.34,
  "payment_method": "credit_card",
  "confidence": 0.95
}

If you cannot read certain fields, use null. Set confidence between 0-1 based on image quality.
Respond with ONLY the JSON, no markdown formatting, no other text.
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
        
        return {
          'success': true,
          'data': receiptData,
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
}
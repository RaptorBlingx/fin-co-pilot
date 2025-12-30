import 'package:firebase_ai/firebase_ai.dart';
import '../../features/add_transaction/models/transaction_data.dart';

/// TransactionParserService - Simplified single-turn transaction parser
/// 
/// Replaces complex multi-turn conversation with simple parse + confirm approach
/// Uses Firebase AI (Gemini 2.5 Flash) with structured output
class TransactionParserService {
  late final GenerativeModel _model;

  TransactionParserService() {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
    );
  }

  /// Parse natural language input into structured transaction data
  /// 
  /// Examples:
  /// - "Spent $50 on groceries" → {amount: 50, category: "Groceries"}
  /// - "Coffee from Starbucks 4.50" → {amount: 4.50, category: "Food & Dining", merchant: "Starbucks"}
  /// - "Got paid $2000" → {amount: 2000, category: "Income"}
  Future<TransactionParseResult> parseNaturalLanguage(String input) async {
    try {
      final prompt = '''
Parse this transaction and extract structured data:
"$input"

Extract the following fields:
- amount (required, number only, no currency symbol)
- category (required, one of: Food & Dining, Groceries, Transport, Shopping, Bills, Entertainment, Healthcare, Income, Transfer, Other)
- merchant (optional, business name if mentioned)
- description (optional, brief description)
- date (optional, default to "today" if not mentioned)
- payment_method (optional, e.g., cash, credit, debit)

Return JSON in this exact format:
{
  "amount": 0.0,
  "category": "Category Name",
  "merchant": "Merchant Name or null",
  "description": "Brief description or null",
  "date": "today",
  "payment_method": "payment method or null",
  "confidence": 0.95
}

Important:
- If amount is unclear, set amount to null and confidence to 0.5
- If category is unclear, use "Other" and reduce confidence
- Always include confidence score (0.0 to 1.0)
- For income transactions, use category "Income"
- For transfers, use category "Transfer"
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        return TransactionParseResult.error('No response from AI');
      }

      // Parse JSON response
      final parsedData = _parseJSONResponse(responseText);
      
      return TransactionParseResult(
        success: true,
        amount: parsedData['amount'],
        category: parsedData['category'],
        merchant: parsedData['merchant'],
        description: parsedData['description'] ?? input,
        date: parsedData['date'] ?? 'today',
        paymentMethod: parsedData['payment_method'],
        confidence: parsedData['confidence'] ?? 0.8,
        rawResponse: responseText,
      );

    } catch (e) {
      return TransactionParseResult.error('Failed to parse transaction: $e');
    }
  }

  /// Parse JSON from AI response (handles code blocks and plain JSON)
  Map<String, dynamic> _parseJSONResponse(String responseText) {
    try {
      // Remove markdown code blocks if present
      String jsonText = responseText.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      } else if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      // Parse JSON
      final parsed = _parseJSON(jsonText);
      return parsed;
    } catch (e) {
      // Fallback: try to extract data manually
      return _extractDataManually(responseText);
    }
  }

  /// Simple JSON parser (avoiding dart:convert dependency)
  Map<String, dynamic> _parseJSON(String json) {
    // This is a simplified parser - in production, use dart:convert
    final Map<String, dynamic> result = {};
    
    // Extract amount
    final amountMatch = RegExp(r'"amount":\s*([0-9.]+)').firstMatch(json);
    if (amountMatch != null) {
      result['amount'] = double.tryParse(amountMatch.group(1)!);
    }
    
    // Extract category
    final categoryMatch = RegExp(r'"category":\s*"([^"]+)"').firstMatch(json);
    if (categoryMatch != null) {
      result['category'] = categoryMatch.group(1);
    }
    
    // Extract merchant
    final merchantMatch = RegExp(r'"merchant":\s*"([^"]+)"').firstMatch(json);
    if (merchantMatch != null) {
      result['merchant'] = merchantMatch.group(1);
    }
    
    // Extract description
    final descMatch = RegExp(r'"description":\s*"([^"]+)"').firstMatch(json);
    if (descMatch != null) {
      result['description'] = descMatch.group(1);
    }
    
    // Extract confidence
    final confMatch = RegExp(r'"confidence":\s*([0-9.]+)').firstMatch(json);
    if (confMatch != null) {
      result['confidence'] = double.tryParse(confMatch.group(1)!) ?? 0.8;
    }
    
    return result;
  }

  /// Manual extraction fallback
  Map<String, dynamic> _extractDataManually(String text) {
    final Map<String, dynamic> result = {};
    
    // Try to find amount
    final amountPattern = RegExp(r'[\$€£¥]?\s*([0-9]+\.?[0-9]*)|([0-9]+\.?[0-9]*)\s*[\$€£¥]');
    final amountMatch = amountPattern.firstMatch(text);
    if (amountMatch != null) {
      final amountStr = amountMatch.group(1) ?? amountMatch.group(2);
      result['amount'] = double.tryParse(amountStr ?? '0');
    }
    
    // Default values
    result['category'] = 'Other';
    result['confidence'] = 0.5;
    
    return result;
  }
}

/// Result of parsing a transaction from natural language
class TransactionParseResult {
  final bool success;
  final double? amount;
  final String? category;
  final String? merchant;
  final String? description;
  final String? date;
  final String? paymentMethod;
  final double confidence;
  final String? error;
  final String? rawResponse;

  TransactionParseResult({
    required this.success,
    this.amount,
    this.category,
    this.merchant,
    this.description,
    this.date,
    this.paymentMethod,
    this.confidence = 0.0,
    this.error,
    this.rawResponse,
  });

  factory TransactionParseResult.error(String errorMessage) {
    return TransactionParseResult(
      success: false,
      error: errorMessage,
    );
  }

  /// Convert to TransactionData for confirmation screen
  TransactionData toTransactionData() {
    return TransactionData(
      amount: amount,
      category: category,
      merchant: merchant,
      description: description,
      date: _parseDate(date),
      paymentMethod: paymentMethod,
    );
  }

  /// Parse date string to DateTime
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    
    final lower = dateStr.toLowerCase();
    if (lower == 'today') return DateTime.now();
    if (lower == 'yesterday') return DateTime.now().subtract(const Duration(days: 1));
    if (lower == 'tomorrow') return DateTime.now().add(const Duration(days: 1));
    
    // Try to parse date string
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Check if result has minimum required fields
  bool get hasRequiredFields => amount != null && category != null;

  /// Check if confidence is high enough
  bool get isHighConfidence => confidence >= 0.7;
}

import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'dart:convert';
import '../../features/add_transaction/models/transaction_data.dart';

/// Agent 2: Extractor Agent
/// Specialized in parsing natural language and extracting transaction fields
class ExtractorAgent {
  late final GenerativeModel _model;

  ExtractorAgent() {
    // ignore: deprecated_member_use
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',
    );
  }

  /// Extract transaction data from user message
  Future<ExtractionResult> extract({
    required String userMessage,
    required TransactionData currentData,
  }) async {
    try {
      // Build extraction prompt
      final prompt = _buildExtractionPrompt(userMessage, currentData);

      // Call AI
      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      // Parse JSON response
      final extractedData = _parseExtractionResponse(responseText);

      return ExtractionResult(
        data: extractedData,
        confidence: _calculateConfidence(extractedData),
      );
    } catch (e) {
      print('Extractor Agent Error: $e');
      // Fallback to regex extraction
      return ExtractionResult(
        data: _fallbackExtraction(userMessage),
        confidence: 0.5,
      );
    }
  }

  /// Build extraction prompt
  String _buildExtractionPrompt(String userMessage, TransactionData currentData) {
    return '''
You are a specialized data extraction agent for financial transactions.

Your ONLY job: Extract transaction fields from user input.

User input: "$userMessage"

Current data:
- Amount: ${currentData.amount ?? "unknown"}
- Item: ${currentData.item ?? "unknown"}
- Category: ${currentData.category ?? "unknown"}
- Merchant: ${currentData.merchant ?? "unknown"}

Extract these fields:
- amount: number (e.g., 5.50)
- item: string (what was bought)
- category: one of [Coffee, Dining, Groceries, Transport, Entertainment, Shopping, Health, Bills, Education, Travel, Other]
- merchant: string (store/restaurant name)
- description: string (additional details)

IMPORTANT:
- Extract ONLY what is explicitly mentioned
- Do NOT invent or assume data
- Return null for fields not found
- Infer category from context (e.g., "Starbucks" → "Coffee")
- Handle various formats: \$5, 5 dollars, 5.50, etc.

Response format (JSON only, no markdown):
{
  "amount": 5.50 or null,
  "item": "Coffee" or null,
  "category": "Coffee" or null,
  "merchant": "Starbucks" or null,
  "description": null
}

Respond with ONLY JSON:
''';
  }

  /// Parse AI extraction response
  TransactionData _parseExtractionResponse(String responseText) {
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

      return TransactionData(
        amount: _parseDouble(json['amount']),
        item: json['item']?.toString(),
        category: json['category']?.toString(),
        merchant: json['merchant']?.toString(),
        description: json['description']?.toString(),
      );
    } catch (e) {
      print('Extraction parsing error: $e');
      return const TransactionData();
    }
  }

  /// Fallback regex extraction
  TransactionData _fallbackExtraction(String input) {
    return TransactionData(
      amount: _extractAmount(input),
      item: _extractItem(input),
      category: _inferCategory(input),
      merchant: _extractMerchant(input),
    );
  }

  /// Extract amount from text
  double? _extractAmount(String input) {
    final patterns = [
      RegExp(r'\$\s*(\d+(?:[.,]\d{1,2})?)', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:dollars?|bucks?)', caseSensitive: false),
      RegExp(r'(?:cost|price|paid|spent?)\s+\$?(\d+(?:[.,]\d{1,2})?)', caseSensitive: false),
      RegExp(r'for\s+\$?(\d+(?:[.,]\d{1,2})?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        String amountStr = match.group(1)!.replaceAll(',', '.');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) return amount;
      }
    }
    return null;
  }

  /// Extract item from text
  String? _extractItem(String input) {
    final itemPatterns = [
      RegExp(r'\b(coffee|latte|cappuccino|espresso|mocha)\b', caseSensitive: false),
      RegExp(r'\b(lunch|dinner|breakfast|meal|food)\b', caseSensitive: false),
      RegExp(r'\b(groceries|grocery)\b', caseSensitive: false),
      RegExp(r'\b(gas|fuel|gasoline)\b', caseSensitive: false),
      RegExp(r'\b(uber|lyft|taxi|ride)\b', caseSensitive: false),
      RegExp(r'\b(movie|cinema|netflix)\b', caseSensitive: false),
    ];

    for (final pattern in itemPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) return _capitalize(match.group(1)!);
    }
    return null;
  }

  /// Infer category from text
  String? _inferCategory(String input) {
    final lower = input.toLowerCase();

    final categoryMap = {
      'Coffee': ['coffee', 'latte', 'cappuccino', 'espresso', 'starbucks', 'café'],
      'Dining': ['lunch', 'dinner', 'breakfast', 'meal', 'restaurant', 'mcdonald', 'burger'],
      'Groceries': ['groceries', 'grocery', 'supermarket', 'costco', 'walmart'],
      'Transport': ['uber', 'lyft', 'taxi', 'gas', 'fuel', 'parking', 'bus'],
      'Entertainment': ['movie', 'cinema', 'netflix', 'spotify', 'game'],
      'Health': ['doctor', 'pharmacy', 'medicine', 'hospital'],
      'Bills': ['bill', 'rent', 'utility', 'electricity', 'internet'],
      'Shopping': ['shopping', 'clothes', 'amazon', 'store'],
    };

    for (final entry in categoryMap.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) return entry.key;
      }
    }
    return null;
  }

  /// Extract merchant from text
  String? _extractMerchant(String input) {
    final merchantPattern = RegExp(
      r'\b(?:at|from)\s+([A-Z][a-zA-Z\s&\-]{2,20})',
      caseSensitive: false,
    );
    final match = merchantPattern.firstMatch(input);
    if (match != null) {
      return _capitalizeWords(match.group(1)!.trim());
    }

    final commonMerchants = [
      'Starbucks', 'McDonald\'s', 'Costco', 'Walmart',
      'Target', 'Uber', 'Lyft', 'Netflix', 'Amazon'
    ];
    for (final merchant in commonMerchants) {
      if (input.toLowerCase().contains(merchant.toLowerCase())) {
        return merchant;
      }
    }
    return null;
  }

  /// Calculate confidence based on extracted fields
  double _calculateConfidence(TransactionData data) {
    int score = 0;
    int total = 3; // Required fields

    if (data.amount != null) score++;
    if (data.item != null && data.item!.isNotEmpty) score++;
    if (data.category != null && data.category!.isNotEmpty) score++;

    return score / total;
  }

  /// Parse double
  double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Capitalize first letter
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitalize all words
  String _capitalizeWords(String text) {
    return text.split(' ').map((word) => _capitalize(word)).join(' ');
  }
}

/// Extraction result
class ExtractionResult {
  final TransactionData data;
  final double confidence;

  ExtractionResult({
    required this.data,
    required this.confidence,
  });
}

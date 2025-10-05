import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'dart:convert';

class TransactionClassifierAgent {
  late final GenerativeModel _model;
  
  TransactionClassifierAgent() {
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash-lite',
      generationConfig: GenerationConfig(
        temperature: 0.1,
        maxOutputTokens: 1024,
      ),
    );
  }
  
  /// Classify transaction and extract entities from natural language
  Future<Map<String, dynamic>> classifyTransaction(String description) async {
    try {
      final prompt = '''
You are a transaction classifier for a personal finance app.

Analyze this transaction description and extract information.

Transaction: "$description"

Categories available:
- groceries: Food shopping, supermarkets
- dining: Restaurants, cafes, food delivery
- transport: Gas, public transit, ride-sharing, parking
- entertainment: Movies, games, subscriptions (Netflix, Spotify)
- shopping: Clothing, electronics, general retail
- health: Medical, pharmacy, fitness, wellness
- bills: Utilities, rent, phone, internet
- education: Books, courses, tuition
- travel: Hotels, flights, vacation
- other: Anything that doesn't fit above

Extract these fields:
- category: Primary category from list above
- amount: Numeric amount if mentioned (without currency symbol)
- merchant: Business name if mentioned
- description: Clean description of the transaction
- confidence: How confident you are (0-1)

Respond with ONLY valid JSON in this format:
{
  "category": "groceries",
  "amount": 50.00,
  "merchant": "Costco",
  "description": "Weekly grocery shopping",
  "confidence": 0.95
}

If amount/merchant not mentioned, use null.
Respond with ONLY the JSON, no markdown, no other text.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';
      
      // Parse JSON
      try {
        String cleanedJson = responseText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final Map<String, dynamic> classification = jsonDecode(cleanedJson);
        
        return {
          'success': true,
          'data': classification,
        };
      } catch (e) {
        print('Classification parsing error: $e');
        
        return {
          'success': false,
          'error': 'Failed to classify transaction',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Classification failed: ${e.toString()}',
      };
    }
  }
}
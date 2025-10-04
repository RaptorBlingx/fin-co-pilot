import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'dart:convert';

class GeminiOrchestratorService {
  late final GenerativeModel _model;
  
  GeminiOrchestratorService() {
    // Initialize Gemini 2.5 Flash using Firebase AI Logic
    // No API key needed - uses Firebase app credentials
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',
    );
  }
  
  /// Main orchestrator method - determines intent and routes to appropriate agent
  Future<Map<String, dynamic>> processUserInput(String userInput) async {
    try {
      // Step 1: Determine intent using Gemini
      final intent = await _determineIntent(userInput);
      
      // Step 2: Route to appropriate specialist agent based on intent
      switch (intent['type']) {
        case 'add_transaction':
          return await _routeToTransactionClassifier(userInput, intent);
        
        case 'get_insights':
          return await _routeToFinancialAnalyst(userInput, intent);
        
        case 'price_search':
          return await _routeToPriceIntelligence(userInput, intent);
        
        case 'general_query':
          return await _handleGeneralQuery(userInput);
        
        default:
          return {
            'success': false,
            'error': 'Unknown intent: ${intent['type']}',
          };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Orchestrator error: ${e.toString()}',
      };
    }
  }
  
  /// Determine user intent from natural language input
  Future<Map<String, dynamic>> _determineIntent(String userInput) async {
    final prompt = '''
You are an intent classifier for a personal finance app called Fin Co-Pilot.

Analyze the user's input and determine their intent. Respond ONLY with valid JSON.

User input: "$userInput"

Intent types:
- add_transaction: User wants to log an expense (e.g., "I spent \$50 on groceries", "bought coffee for \$5")
- get_insights: User wants financial analysis (e.g., "how much did I spend this month?", "show my spending breakdown")
- price_search: User wants to find best prices (e.g., "best price for iPhone 16", "where to buy cheap milk")
- general_query: General questions about the app or finances (e.g., "how do I add a transaction?", "what is a budget?")

Required JSON format:
{
  "type": "intent_type",
  "confidence": 0.95,
  "entities": {
    "amount": null,
    "category": null,
    "merchant": null,
    "product": null,
    "query": null
  }
}

Extract relevant entities based on intent type:
- For add_transaction: amount, category, merchant
- For price_search: product, query
- For get_insights: query

Respond with ONLY the JSON object, no markdown formatting, no other text.
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final responseText = response.text ?? '';
    
    // Parse JSON response
    try {
      // Remove markdown code blocks if present
      String cleanedJson = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      
      // Parse JSON
      final Map<String, dynamic> intent = jsonDecode(cleanedJson);
      
      return intent;
    } catch (e) {
      print('Intent parsing error: $e');
      print('Response was: $responseText');
      
      // Fallback to general query if parsing fails
      return {
        'type': 'general_query',
        'confidence': 0.5,
        'entities': {'query': userInput},
      };
    }
  }
  
  /// Route to Transaction Classifier Agent (placeholder for M4)
  Future<Map<String, dynamic>> _routeToTransactionClassifier(
    String userInput, 
    Map<String, dynamic> intent,
  ) async {
    // Placeholder - will implement in M4
    return {
      'success': true,
      'agent': 'transaction_classifier',
      'message': 'Transaction: ${intent['entities']['amount']} at ${intent['entities']['merchant'] ?? 'unknown merchant'}',
      'intent': intent,
    };
  }
  
  /// Route to Financial Analyst Agent (placeholder for M5)
  Future<Map<String, dynamic>> _routeToFinancialAnalyst(
    String userInput, 
    Map<String, dynamic> intent,
  ) async {
    // Placeholder - will implement in M5
    return {
      'success': true,
      'agent': 'financial_analyst',
      'message': 'Financial analysis coming in M5!',
      'intent': intent,
    };
  }
  
  /// Route to Price Intelligence Agent (placeholder for M6)
  Future<Map<String, dynamic>> _routeToPriceIntelligence(
    String userInput, 
    Map<String, dynamic> intent,
  ) async {
    // Placeholder - will implement in M6
    return {
      'success': true,
      'agent': 'price_intelligence',
      'message': 'Price search coming in M6!',
      'intent': intent,
    };
  }
  
  /// Handle general queries directly
  Future<Map<String, dynamic>> _handleGeneralQuery(String userInput) async {
    final prompt = '''
You are Fin Co-Pilot, a helpful AI financial assistant.

User question: "$userInput"

Provide a helpful, concise answer (2-3 sentences max).
Be friendly and professional.
Focus on personal finance topics.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      
      return {
        'success': true,
        'agent': 'orchestrator',
        'message': response.text ?? 'I can help you with that!',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to generate response: ${e.toString()}',
      };
    }
  }
}
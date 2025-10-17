import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../models/transaction_data.dart';
import '../../../services/agents/orchestrator_agent.dart';
import '../../../services/agents/extractor_agent.dart';
import '../../../services/agents/validator_agent.dart';
import '../../../services/agents/context_agent.dart';

/// Robust AI Service with Agent Swarm Architecture
/// Uses specialized agents for extraction, validation, and context analysis
class RobustAIService {
  late final GenerativeModel _model;
  final List<String> _conversationHistory = [];

  // Agent Swarm
  late final OrchestratorAgent _orchestrator;
  late final ExtractorAgent _extractor;
  late final ValidatorAgent _validator;
  late final ContextAgent _context;

  final bool _useAgentSwarm;

  RobustAIService({bool useAgentSwarm = true}) : _useAgentSwarm = useAgentSwarm {
    // Initialize Gemini 2.5 Flash using Firebase Vertex AI
    // ignore: deprecated_member_use
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',
    );

    if (_useAgentSwarm) {
      // Initialize agent swarm
      _extractor = ExtractorAgent();
      _validator = ValidatorAgent();
      _context = ContextAgent();
      _orchestrator = OrchestratorAgent(
        extractorAgent: _extractor,
        validatorAgent: _validator,
        contextAgent: _context,
      );
    }
  }

  /// Process user message and return structured AI response
  Future<AIResponse> processMessage({
    required String userMessage,
    required TransactionData currentData,
  }) async {
    try {
      // Add user message to history
      _conversationHistory.add('User: $userMessage');

      AIResponse aiResponse;

      if (_useAgentSwarm) {
        // Use Agent Swarm Architecture
        aiResponse = await _processWithAgentSwarm(
          userMessage: userMessage,
          currentData: currentData,
        );
      } else {
        // Use single AI model (fallback)
        aiResponse = await _processWithSingleModel(
          userMessage: userMessage,
          currentData: currentData,
        );
      }

      // Add AI response to history
      _conversationHistory.add('AI: ${aiResponse.message}');

      return aiResponse;
    } catch (e) {
      print('RobustAIService Error: $e');
      // Return intelligent fallback
      return _createFallbackResponse(userMessage, currentData);
    }
  }

  /// Process with Agent Swarm
  Future<AIResponse> _processWithAgentSwarm({
    required String userMessage,
    required TransactionData currentData,
  }) async {
    // Use orchestrator to coordinate agents
    final orchestratorResponse = await _orchestrator.orchestrate(
      userMessage: userMessage,
      currentData: currentData,
      conversationHistory: _conversationHistory,
    );

    return AIResponse(
      message: orchestratorResponse.message,
      extractedData: orchestratorResponse.extractedData,
      missingRequired: orchestratorResponse.missingFields,
      nextQuestion: orchestratorResponse.nextQuestion,
      readyToSave: orchestratorResponse.isComplete,
      confidence: orchestratorResponse.confidence,
      shouldSuggestReceipt: orchestratorResponse.shouldSuggestReceipt,
      contextRichness: orchestratorResponse.contextRichness,
    );
  }

  /// Process with single model (original implementation)
  Future<AIResponse> _processWithSingleModel({
    required String userMessage,
    required TransactionData currentData,
  }) async {
    // Build the complete system prompt
    final systemPrompt = _buildSystemPrompt(userMessage, currentData);

    // Call Gemini AI
    final response = await _model.generateContent([
      Content.text(systemPrompt),
    ]);

    final responseText = response.text ?? '';

    // Parse the JSON response
    return _parseAIResponse(responseText, userMessage, currentData);
  }

  /// Build the system prompt with conversation context
  String _buildSystemPrompt(String userMessage, TransactionData currentData) {
    final prompt = StringBuffer();

    // Master system instructions
    prompt.writeln('''
You are FinCoPilot, an intelligent financial assistant helping users log expenses.

REQUIRED FIELDS (must collect before saving):
- amount: The cost (number, e.g., 4.50)
- item: What was bought (string, e.g., "Coffee", "Lunch")
- category: Expense type (one of: Coffee, Dining, Groceries, Transport, Entertainment, Shopping, Health, Bills, Education, Travel, Other)

ENCOURAGED FIELDS (strongly suggest):
- merchant: Where bought (e.g., "Starbucks")
- description: Additional context
- date: When bought (default: now)

RULES:
1. Extract as much information as possible from each user message
2. NEVER save a transaction without all required fields
3. Ask ONE targeted question at a time for missing required fields
4. Be conversational, friendly, brief (max 2 sentences per message)
5. Use emojis sparingly (max 1 per message)
6. When all required fields are collected, set ready_to_save: true

RESPONSE FORMAT (always return valid JSON, no markdown):
{
  "message": "Your conversational response",
  "extracted_fields": {
    "amount": 4.50 or null,
    "item": "Coffee" or null,
    "category": "Coffee" or null,
    "merchant": "Starbucks" or null,
    "description": null
  },
  "missing_required": ["amount"] or [],
  "next_question": "How much did it cost?" or null,
  "ready_to_save": false or true,
  "confidence": 0.95
}
''');

    // Add conversation history context
    if (_conversationHistory.isNotEmpty) {
      prompt.writeln('\nCONVERSATION HISTORY:');
      for (final msg in _conversationHistory.take(5)) {
        prompt.writeln(msg);
      }
    }

    // Add current transaction state
    prompt.writeln('\nCURRENT TRANSACTION STATE:');
    prompt.writeln('Amount: ${currentData.amount ?? "not provided"}');
    prompt.writeln('Item: ${currentData.item ?? "not provided"}');
    prompt.writeln('Category: ${currentData.category ?? "not provided"}');
    prompt.writeln('Merchant: ${currentData.merchant ?? "not provided"}');
    prompt.writeln('Missing required: ${currentData.missingRequiredFields.join(", ")}');

    // Add user's new message
    prompt.writeln('\nUSER\'S NEW MESSAGE: "$userMessage"');

    // Add specific instruction based on state
    if (currentData.hasRequiredFields) {
      prompt.writeln('\nINSTRUCTION: All required fields are complete. Set ready_to_save: true and show confirmation message.');
    } else if (currentData.missingRequiredFields.length == 1) {
      prompt.writeln('\nINSTRUCTION: Only ${currentData.missingRequiredFields.first} is missing. Ask for it specifically.');
    } else {
      prompt.writeln('\nINSTRUCTION: Extract what you can and ask for the most important missing field.');
    }

    prompt.writeln('\nRespond with ONLY the JSON object. No markdown formatting. No other text.');

    return prompt.toString();
  }

  /// Parse AI response into structured AIResponse object
  AIResponse _parseAIResponse(String responseText, String userMessage, TransactionData currentData) {
    try {
      // Clean the response text
      String cleanedJson = responseText.trim();

      // Remove markdown code blocks if present
      cleanedJson = cleanedJson
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Find JSON object boundaries
      final jsonStart = cleanedJson.indexOf('{');
      final jsonEnd = cleanedJson.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        cleanedJson = cleanedJson.substring(jsonStart, jsonEnd + 1);
      }

      // Parse JSON
      final Map<String, dynamic> jsonResponse = jsonDecode(cleanedJson);

      // Extract fields
      final message = jsonResponse['message']?.toString() ?? 'I understand.';
      final extractedFieldsMap = jsonResponse['extracted_fields'] as Map<String, dynamic>? ?? {};
      final missingRequired = List<String>.from(jsonResponse['missing_required'] ?? []);
      final nextQuestion = jsonResponse['next_question']?.toString();
      final readyToSave = jsonResponse['ready_to_save'] == true;
      final confidence = (jsonResponse['confidence'] as num?)?.toDouble() ?? 0.8;

      // Build extracted data
      final extractedData = TransactionData(
        amount: _parseDouble(extractedFieldsMap['amount']),
        item: extractedFieldsMap['item']?.toString(),
        category: extractedFieldsMap['category']?.toString(),
        merchant: extractedFieldsMap['merchant']?.toString(),
        description: extractedFieldsMap['description']?.toString(),
        date: currentData.date, // Preserve existing date
        currency: currentData.currency ?? 'USD',
      );

      // Merge with current data
      final mergedData = currentData.mergeWith(extractedData);

      return AIResponse(
        message: message,
        extractedData: mergedData,
        missingRequired: missingRequired,
        nextQuestion: nextQuestion,
        readyToSave: readyToSave && mergedData.hasRequiredFields,
        confidence: confidence,
      );
    } catch (e) {
      print('JSON parsing error: $e');
      print('Response was: $responseText');
      // Fallback to regex extraction
      return _createFallbackResponse(userMessage, currentData);
    }
  }

  /// Create intelligent fallback response when AI fails
  AIResponse _createFallbackResponse(String userMessage, TransactionData currentData) {
    // Use smart extraction as fallback
    final extractedData = _extractFromUserInput(userMessage);
    final mergedData = currentData.mergeWith(extractedData);

    String message;
    String? nextQuestion;

    if (mergedData.hasRequiredFields) {
      message = 'Perfect! I\'ve got all the details. ✓';
      nextQuestion = null;
    } else {
      final missing = mergedData.missingRequiredFields;
      if (missing.contains('amount')) {
        message = mergedData.item != null
            ? 'Got ${mergedData.item}! How much did it cost? 💰'
            : 'How much did you spend? 💰';
        nextQuestion = 'How much did it cost?';
      } else if (missing.contains('item')) {
        message = mergedData.amount != null
            ? 'What did you buy for \$${mergedData.amount}? 🛍️'
            : 'What did you buy? 🛍️';
        nextQuestion = 'What did you buy?';
      } else if (missing.contains('category')) {
        message = 'What category is this expense?';
        nextQuestion = 'What category?';
      } else {
        message = 'Could you tell me what you bought and how much it cost?';
        nextQuestion = 'What did you buy and how much?';
      }
    }

    return AIResponse(
      message: message,
      extractedData: mergedData,
      missingRequired: mergedData.missingRequiredFields,
      nextQuestion: nextQuestion,
      readyToSave: mergedData.hasRequiredFields,
      confidence: 0.6,
    );
  }

  /// Basic extraction from user input (fallback)
  TransactionData _extractFromUserInput(String input) {
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
      RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*\$', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:usd|dollars?)', caseSensitive: false),
      RegExp(r'(?:cost|price|paid|spend|spent)\s+\$?(\d+(?:[.,]\d{1,2})?)', caseSensitive: false),
      RegExp(r'for\s+\$?(\d+(?:[.,]\d{1,2})?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        String amountStr = match.group(1)!.replaceAll(',', '.');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0 && amount < 1000000) {
          return amount;
        }
      }
    }
    return null;
  }

  /// Extract item from text
  String? _extractItem(String input) {
    final itemPatterns = [
      RegExp(r'\b(coffee|latte|cappuccino|espresso)\b', caseSensitive: false),
      RegExp(r'\b(lunch|dinner|breakfast|meal)\b', caseSensitive: false),
      RegExp(r'\b(groceries|grocery)\b', caseSensitive: false),
      RegExp(r'\b(gas|fuel)\b', caseSensitive: false),
      RegExp(r'\b(uber|taxi|ride)\b', caseSensitive: false),
    ];

    for (final pattern in itemPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        return _capitalize(match.group(1)!);
      }
    }
    return null;
  }

  /// Infer category from text
  String? _inferCategory(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('coffee') || lower.contains('latte') || lower.contains('starbucks')) {
      return 'Coffee';
    }
    if (lower.contains('lunch') || lower.contains('dinner') || lower.contains('restaurant')) {
      return 'Dining';
    }
    if (lower.contains('groceries') || lower.contains('grocery')) {
      return 'Groceries';
    }
    if (lower.contains('uber') || lower.contains('taxi') || lower.contains('gas')) {
      return 'Transport';
    }
    return 'Other';
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

    // Check for common merchants
    final commonMerchants = ['Starbucks', 'McDonald\'s', 'Costco', 'Walmart', 'Uber'];
    for (final merchant in commonMerchants) {
      if (input.toLowerCase().contains(merchant.toLowerCase())) {
        return merchant;
      }
    }
    return null;
  }

  /// Parse double from dynamic value
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

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
  }
}

/// Structured AI response
class AIResponse {
  final String message;
  final TransactionData extractedData;
  final List<String> missingRequired;
  final String? nextQuestion;
  final bool readyToSave;
  final double confidence;
  final bool shouldSuggestReceipt;
  final String contextRichness;

  AIResponse({
    required this.message,
    required this.extractedData,
    required this.missingRequired,
    this.nextQuestion,
    required this.readyToSave,
    required this.confidence,
    this.shouldSuggestReceipt = false,
    this.contextRichness = 'low',
  });
}

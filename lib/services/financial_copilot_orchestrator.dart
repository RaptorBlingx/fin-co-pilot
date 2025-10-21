import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Financial Copilot Orchestrator
/// Routes user requests to appropriate specialized agents based on intent
class FinancialCopilotOrchestrator {
  static final FinancialCopilotOrchestrator _instance = FinancialCopilotOrchestrator._internal();
  factory FinancialCopilotOrchestrator() => _instance;
  FinancialCopilotOrchestrator._internal();

  // ignore: deprecated_member_use
  final GenerativeModel _model = FirebaseVertexAI.instance.generativeModel(
    model: 'gemini-2.0-flash-exp',
  );

  /// Classify user intent and route to appropriate handler
  Future<Map<String, dynamic>> processUserMessage({
    required String message,
    required String userId,
    required Map<String, dynamic> userContext,
  }) async {
    try {
      // First, classify the intent
      final intent = await _classifyIntent(message, userContext);

      if (kDebugMode) {
        print('Classified intent: ${intent['intent']} (confidence: ${intent['confidence']})');
      }

      // Route to appropriate handler based on intent
      switch (intent['intent']) {
        case 'add_transaction':
          return {
            'type': 'add_transaction',
            'intent': intent,
            'data': await _extractTransactionData(message),
          };

        case 'financial_advice':
          return {
            'type': 'financial_advice',
            'intent': intent,
            'data': await _getFinancialAdvice(message, userContext),
          };

        case 'price_comparison':
          return {
            'type': 'price_comparison',
            'intent': intent,
            'data': await _findPrices(message),
          };

        case 'budget_analysis':
          return {
            'type': 'budget_analysis',
            'intent': intent,
            'data': await _analyzeBudget(message, userContext),
          };

        case 'spending_insights':
          return {
            'type': 'spending_insights',
            'intent': intent,
            'data': await _generateInsights(userContext),
          };

        case 'generate_report':
          return {
            'type': 'generate_report',
            'intent': intent,
            'data': await _generateReport(message, userContext),
          };

        default:
          return {
            'type': 'general_conversation',
            'intent': intent,
            'data': await _handleGeneralQuery(message, userContext),
          };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in orchestrator: $e');
      }
      return {
        'type': 'error',
        'error': e.toString(),
        'data': {
          'response': 'I apologize, but I encountered an issue. Could you please rephrase your request?',
        },
      };
    }
  }

  /// Classify user intent using AI
  Future<Map<String, dynamic>> _classifyIntent(String message, Map<String, dynamic> context) async {
    final prompt = '''
You are an intent classifier for a financial copilot app. Classify the user's message into ONE of these intents:

INTENTS:
- add_transaction: User wants to add/record an expense, purchase, or income
- financial_advice: User asks for financial advice, tips, or recommendations
- price_comparison: User wants to compare prices or find the best deal for a product
- budget_analysis: User asks about their budget, spending limits, or budget status
- spending_insights: User wants to know about their spending patterns, trends, or analytics
- generate_report: User requests a financial report, summary, or export
- general_conversation: General questions, greetings, or other financial queries

USER MESSAGE: "$message"

CONTEXT:
${context.isNotEmpty ? jsonEncode(context) : 'No context available'}

Respond with ONLY a JSON object:
{
  "intent": "intent_name",
  "confidence": 0.95,
  "reasoning": "Brief explanation"
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      // Clean the response
      String cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final result = jsonDecode(cleaned) as Map<String, dynamic>;
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Intent classification error: $e');
      }
      // Default to general conversation
      return {
        'intent': 'general_conversation',
        'confidence': 0.5,
        'reasoning': 'Fallback due to classification error',
      };
    }
  }

  /// Extract transaction data from natural language
  Future<Map<String, dynamic>> _extractTransactionData(String message) async {
    final prompt = '''
Extract transaction details from this message: "$message"

Extract:
- amount: The monetary amount (number only)
- merchant: Store/merchant name
- category: One of [groceries, dining, transport, entertainment, shopping, health, bills, education, travel, other]
- description: Brief description
- payment_method: One of [cash, credit_card, debit_card, bank_transfer, digital_wallet]

If information is missing, use null.

Respond with ONLY JSON:
{
  "amount": 50.00,
  "merchant": "Walmart",
  "category": "groceries",
  "description": "Weekly groceries",
  "payment_method": "credit_card",
  "confidence": 0.9
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      String cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      return {
        'error': 'Could not extract transaction data',
        'raw_message': message,
      };
    }
  }

  /// Get financial advice based on user query
  Future<Map<String, dynamic>> _getFinancialAdvice(String message, Map<String, dynamic> context) async {
    final prompt = '''
You are a professional financial advisor. Answer this user's question with helpful, practical advice:

USER QUESTION: "$message"

USER CONTEXT:
${context.isNotEmpty ? jsonEncode(context) : 'Limited context available'}

Provide:
1. A clear, concise answer (2-3 sentences)
2. An actionable tip (1 sentence)
3. If relevant, suggest a specific action they can take in the app

Respond with JSON:
{
  "answer": "Your main advice here",
  "tip": "Quick actionable tip",
  "action": {
    "label": "View Budget",
    "type": "navigate_budget"
  },
  "tone": "friendly"
}

If no specific action is needed, set action to null.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      String cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      return {
        'answer': 'I\'d be happy to help with financial advice. Could you please provide more details about what you\'d like to know?',
        'tip': 'Feel free to ask me about budgeting, saving, or spending strategies!',
        'action': null,
        'tone': 'helpful',
      };
    }
  }

  /// Find and compare prices for products
  Future<Map<String, dynamic>> _findPrices(String message) async {
    final prompt = '''
Extract product information for price comparison:

USER REQUEST: "$message"

Extract:
- product_name: The product name
- product_category: Category of product
- suggested_stores: List of 3-5 stores to check

Respond with JSON:
{
  "product_name": "iPhone 15 Pro",
  "product_category": "electronics",
  "suggested_stores": ["Best Buy", "Amazon", "Apple Store", "Walmart"],
  "response": "I'll help you find the best price for [product]. Let me check current prices across multiple stores."
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      String cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      return {
        'product_name': null,
        'response': 'I can help you find the best prices. What product are you looking for?',
      };
    }
  }

  /// Analyze user's budget status
  Future<Map<String, dynamic>> _analyzeBudget(String message, Map<String, dynamic> context) async {
    final prompt = '''
Analyze the user's budget question and provide insights:

USER QUESTION: "$message"

USER CONTEXT (spending data):
${context.isNotEmpty ? jsonEncode(context) : 'No budget data available'}

Provide a helpful response about their budget status, suggestions, and any warnings.

Respond with JSON:
{
  "response": "Your budget analysis response",
  "status": "on_track" | "warning" | "over_budget",
  "suggestion": "A specific suggestion",
  "action": {
    "label": "View Budget Details",
    "type": "navigate_budget"
  }
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      String cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      return {
        'response': 'I can help you understand your budget better. You can view your budget details and set spending limits for different categories.',
        'status': 'unknown',
        'suggestion': 'Set up category budgets to track your spending effectively.',
        'action': {
          'label': 'Open Budget Manager',
          'type': 'navigate_budget',
        },
      };
    }
  }

  /// Generate spending insights
  Future<Map<String, dynamic>> _generateInsights(Map<String, dynamic> context) async {
    final prompt = '''
Generate spending insights based on user data:

USER DATA:
${jsonEncode(context)}

Provide 2-3 key insights about their spending patterns.

Respond with JSON:
{
  "insights": [
    "Insight 1",
    "Insight 2",
    "Insight 3"
  ],
  "highlight": "Most important insight",
  "action": {
    "label": "View Full Insights",
    "type": "navigate_insights"
  }
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      String cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      return {
        'insights': [
          'Track your expenses regularly for better insights',
          'Set budgets for each spending category',
          'Review your insights page for detailed analytics',
        ],
        'highlight': 'Start tracking expenses to see personalized insights',
        'action': {
          'label': 'View Insights',
          'type': 'navigate_insights',
        },
      };
    }
  }

  /// Generate financial report
  Future<Map<String, dynamic>> _generateReport(String message, Map<String, dynamic> context) async {
    return {
      'response': 'I can generate a financial report for you. What time period would you like: weekly, monthly, or yearly?',
      'report_type': null,
      'action': {
        'label': 'Open Reports',
        'type': 'navigate_reports',
      },
    };
  }

  /// Handle general queries
  Future<Map<String, dynamic>> _handleGeneralQuery(String message, Map<String, dynamic> context) async {
    final prompt = '''
You are Fin Copilot, a friendly and professional financial assistant. Answer this question:

USER: "$message"

Respond naturally and helpfully. If you can suggest a specific feature or action in the app, include it.

Respond with JSON:
{
  "response": "Your friendly response",
  "action": {
    "label": "Suggested action label",
    "type": "action_type"
  }
}

If no action is needed, set action to null.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';

      String cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      return {
        'response': 'I\'m here to help with your finances! You can ask me to add expenses, analyze your spending, find prices, or get financial advice.',
        'action': null,
      };
    }
  }

  /// Get personalized greeting for user
  Future<Map<String, dynamic>> getGreeting({
    required String userName,
    required Map<String, dynamic> userContext,
  }) async {
    final timeOfDay = _getTimeOfDay();
    final firstName = userName.split(' ').first;

    // Analyze user context for personalized greeting
    final hasTransactions = ((userContext['transactionCount'] as int?) ?? 0) > 0;
    final hasBudget = (userContext['hasBudget'] as bool?) ?? false;

    String greeting;
    List<Map<String, String>> quickActions;

    if (!hasTransactions) {
      greeting = '$timeOfDay, $firstName! 👋\n\nI\'m your Financial Copilot. Let\'s start tracking your expenses and building better financial habits together.';
      quickActions = [
        {'label': '➕ Add Expense', 'action': 'add_transaction', 'icon': 'add_circle'},
        {'label': '💡 Get Tips', 'action': 'financial_advice', 'icon': 'lightbulb'},
        {'label': '📊 Set Budget', 'action': 'navigate_budget', 'icon': 'account_balance_wallet'},
      ];
    } else if (!hasBudget) {
      greeting = '$timeOfDay, $firstName! 💰\n\nYou\'re tracking expenses nicely! Ready to set budgets and get deeper insights?';
      quickActions = [
        {'label': '💰 Set Budget', 'action': 'navigate_budget', 'icon': 'account_balance_wallet'},
        {'label': '➕ Add Expense', 'action': 'add_transaction', 'icon': 'add_circle'},
        {'label': '📈 View Insights', 'action': 'navigate_insights', 'icon': 'insights'},
        {'label': '🔍 Find Prices', 'action': 'price_comparison', 'icon': 'search'},
      ];
    } else {
      greeting = '$timeOfDay, $firstName! ✨\n\nWhat can I help you with today?';
      quickActions = [
        {'label': '➕ Add Expense', 'action': 'add_transaction', 'icon': 'add_circle'},
        {'label': '📊 Budget Status', 'action': 'budget_analysis', 'icon': 'pie_chart'},
        {'label': '📈 Insights', 'action': 'navigate_insights', 'icon': 'trending_up'},
        {'label': '🔍 Price Finder', 'action': 'price_comparison', 'icon': 'shopping_cart'},
        {'label': '💡 Get Advice', 'action': 'financial_advice', 'icon': 'psychology'},
        {'label': '📄 Reports', 'action': 'navigate_reports', 'icon': 'description'},
      ];
    }

    return {
      'greeting': greeting,
      'quickActions': quickActions,
      'userName': firstName,
      'timeOfDay': timeOfDay,
    };
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

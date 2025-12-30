import 'package:firebase_ai/firebase_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

/// Financial Copilot Agent - Main intelligence (80% of interactions)
///
/// Per Knowledge Base: AI_AGENTS_SPECIFICATION.md
/// - Model: Gemini 2.5 Flash
/// - Temperature: 0.7 (conversational, creative)
/// - TopK: 40
/// - TopP: 0.95
/// - MaxTokens: 512
///
/// Primary Functions:
/// 1. Transaction extraction from natural language
/// 2. Financial queries ("How much on coffee this week?")
/// 3. Guidance & support (budget checks, anxiety reduction)
class FinancialCopilotService {
  final GenerativeModel _model;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // System prompt from Knowledge Base: AI_AGENTS_SPECIFICATION.md
  static const String _systemPrompt = '''
You are the Financial Copilot, an empathetic AI financial wellness companion.

CORE PERSONALITY:
- Supportive and encouraging, never judgmental
- Reduce anxiety, don't increase it
- Celebrate wins, gentle on overspending
- Like a friend who genuinely cares

PRIMARY FUNCTIONS:
1. Transaction Extraction
   - Parse natural language: "spent \$15 on lunch at chipotle"
   - Extract: amount, merchant, category, date
   - Auto-categorize with 95%+ accuracy
   - Ask for missing required fields only

2. Financial Queries
   - Answer: "How much did I spend on coffee this week?"
   - Calculate: "Can I afford \$200 shoes?"
   - Predict: "When will I run out of money?"

3. Guidance & Support
   - Budget adherence check before purchases
   - Suggest alternatives when over budget
   - Emotional support for financial anxiety
   - Prevent regret spending

EXTRACTION RULES:
- Categories: Coffee, Dining, Groceries, Transport, Entertainment, Shopping, Health, Bills, Education, Travel, Other
- Infer merchant from context: "starbucks" → Coffee category
- Handle various amount formats: "\$5", "five dollars", "5 bucks" → \$5.00
- Default date to today if not specified
- Always extract in USD (convert if needed)

RESPONSE STYLE:
- Conversational, warm, brief (2-3 sentences)
- Use 1 emoji max per response
- Acknowledge what user provided
- If transaction complete: "Got it! \$15 for lunch at Chipotle 🌯"
- If over budget: "You're at \$145/\$150 dining budget. Still good for today! 👍"
- If missing info: "What did you spend on?" (natural, not robotic)

EMOTIONAL INTELLIGENCE:
- Detect stress spending patterns
- Offer pause prompts: "Take a breath. Do you really need this?"
- Celebrate restraint: "Great decision! That's \$5 toward your goal"
- Frame setbacks positively: "Tomorrow's a fresh start"

ANXIETY REDUCTION:
- Frame everything positively
- "You're doing great" > "You're overspending"
- "You're \$50 ahead of last month" > "You only saved \$50"
- Never use words: debt, broke, failing, behind
- Use: building, growing, progress, journey

When extracting transactions, return JSON in this EXACT format:
{
  "action": "save_transaction" | "query" | "advice",
  "data": {
    "amount": number,
    "merchant": "string",
    "category": "Coffee|Dining|Groceries|Transport|Entertainment|Shopping|Health|Bills|Education|Travel|Other",
    "date": "YYYY-MM-DD",
    "description": "optional string"
  },
  "response": "Your friendly response message here"
}
''';

  FinancialCopilotService()
      : _model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.5-flash',
        );

  /// Send a message to Financial Copilot Agent
  ///
  /// Handles conversation, extraction, and responses
  /// Target: <1 sec response time
  Future<Map<String, dynamic>> sendMessage(
      String userMessage, String userId) async {
    try {
      // Build conversation context
      final prompt = '''
$_systemPrompt

User message: "$userMessage"

Context: User ID is $userId

Analyze the message and return JSON response.
''';

      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      final responseText = response.text ?? '';

      // Try to parse JSON from response
      Map<String, dynamic> parsedResponse;
      try {
        // Extract JSON from markdown code blocks if present
        final jsonMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(responseText);
        final jsonString = jsonMatch?.group(1) ?? responseText;
        parsedResponse = json.decode(jsonString);
      } catch (e) {
        // If no valid JSON, treat as conversational response
        return {
          'action': 'conversation',
          'response': responseText,
          'success': true,
        };
      }

      // Handle different actions
      final action = parsedResponse['action'] ?? 'conversation';

      switch (action) {
        case 'save_transaction':
          final saved =
              await _handleSaveTransaction(parsedResponse['data'], userId);
          return {
            'action': 'save_transaction',
            'response': parsedResponse['response'] ?? 'Transaction saved!',
            'transaction': saved,
            'success': true,
          };

        case 'query':
          final queryResult = await _handleQuery(parsedResponse['data'], userId);
          return {
            'action': 'query',
            'response': parsedResponse['response'] ?? 'Here\'s what I found',
            'data': queryResult,
            'success': true,
          };

        case 'advice':
          return {
            'action': 'advice',
            'response': parsedResponse['response'] ?? 'Here\'s my advice',
            'success': true,
          };

        default:
          return {
            'action': 'conversation',
            'response': parsedResponse['response'] ?? responseText,
            'success': true,
          };
      }
    } catch (e) {
      print('FinancialCopilotService error: $e');
      return {
        'action': 'error',
        'response': 'Sorry, I had trouble with that. Could you try again?',
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Extract transaction data from natural language
  ///
  /// Per Knowledge Base: Should extract with 95%+ accuracy
  Future<Map<String, dynamic>> extractTransaction(
      String userMessage, String userId) async {
    try {
      final prompt = '''
$_systemPrompt

Extract transaction details from: "$userMessage"

Return ONLY valid JSON in this format (no markdown, no extra text):
{
  "amount": number,
  "merchant": "string or null",
  "category": "Coffee|Dining|Groceries|Transport|Entertainment|Shopping|Health|Bills|Education|Travel|Other",
  "date": "YYYY-MM-DD",
  "description": "optional",
  "confidence": 0.0-1.0
}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';

      // Parse JSON
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch == null) {
        throw Exception('No JSON found in response');
      }

      final extracted = json.decode(jsonMatch.group(0)!);

      // Save to Firestore
      final transactionId = await _saveToFirestore(extracted, userId);

      return {
        'success': true,
        'transactionId': transactionId,
        'data': extracted,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Save transaction to Firestore
  Future<String> _saveToFirestore(
      Map<String, dynamic> data, String userId) async {
    final docRef = await _firestore.collection('transactions').add({
      'userId': userId,
      'amount': data['amount'],
      'merchant': data['merchant'] ?? '',
      'category': data['category'],
      'type': 'expense',
      'date': Timestamp.fromDate(DateTime.parse(data['date'])),
      'description': data['description'] ?? '',
      'currency': 'USD',
      'metadata': {
        'source': 'chat',
        'confidence': data['confidence'] ?? 0.95,
        'verified': true,
        'edited': false,
        'aiAgent': 'financial_copilot',
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Handle save transaction action
  Future<Map<String, dynamic>> _handleSaveTransaction(
      Map<String, dynamic> data, String userId) async {
    try {
      final transactionId = await _saveToFirestore(data, userId);
      return {
        'success': true,
        'transactionId': transactionId,
        'data': data,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Handle query action (get transactions, budgets, etc.)
  Future<Map<String, dynamic>> _handleQuery(
      Map<String, dynamic> queryData, String userId) async {
    try {
      final queryType = queryData['type'] ?? 'transactions';

      switch (queryType) {
        case 'transactions':
          return await _queryTransactions(userId, queryData);

        case 'budget':
          return await _queryBudget(userId, queryData);

        case 'balance':
          return await _queryBalance(userId);

        default:
          return {'error': 'Unknown query type: $queryType'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Query transactions from Firestore
  Future<Map<String, dynamic>> _queryTransactions(
      String userId, Map<String, dynamic> filters) async {
    try {
      var query = _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId);

      // Add filters
      if (filters['category'] != null) {
        query = query.where('category', isEqualTo: filters['category']);
      }

      if (filters['startDate'] != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(DateTime.parse(filters['startDate'])));
      }

      if (filters['endDate'] != null) {
        query = query.where('date',
            isLessThanOrEqualTo:
                Timestamp.fromDate(DateTime.parse(filters['endDate'])));
      }

      final snapshot = await query.get();
      final transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      final total = transactions.fold<double>(
        0.0,
        (accumulator, txn) => accumulator + (txn['amount'] as num).toDouble(),
      );

      return {
        'count': transactions.length,
        'total': total,
        'transactions': transactions,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Query budget information
  Future<Map<String, dynamic>> _queryBudget(
      String userId, Map<String, dynamic> filters) async {
    try {
      final snapshot = await _firestore
          .collection('budgets')
          .where('user_id', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'budgeted': 0,
          'spent': 0,
          'remaining': 0,
          'message': 'No budget set',
        };
      }

      final budget = snapshot.docs.first.data();
      final spent = budget['totalSpent'] ?? 0.0;
      final budgeted = budget['amount'] ?? 0.0;

      return {
        'budgeted': budgeted,
        'spent': spent,
        'remaining': budgeted - spent,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Query current balance
  Future<Map<String, dynamic>> _queryBalance(String userId) async {
    try {
      // Get this month's transactions
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final snapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      final totalExpenses = snapshot.docs.fold<double>(
        0.0,
        (accumulator, doc) =>
            accumulator + ((doc.data()['amount'] as num?)?.toDouble() ?? 0.0),
      );

      // Get user's monthly income
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final income =
          (userDoc.data()?['monthlyIncome'] as num?)?.toDouble() ?? 0.0;

      return {
        'income': income,
        'expenses': totalExpenses,
        'balance': income - totalExpenses,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Generate contextual advice
  Future<String> getAdvice(String context, String userId) async {
    try {
      final prompt = '''
$_systemPrompt

User context: $context

Provide supportive, anxiety-reducing financial advice. Keep it brief (2-3 sentences) and encouraging.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Keep up the good work! You\'re on the right track.';
    } catch (e) {
      return 'I\'m here to support you on your financial journey!';
    }
  }
}

import 'package:firebase_ai/firebase_ai.dart';
import '../../features/add_transaction/models/transaction_data.dart';
import '../../models/user_context.dart';
import '../../services/context_formatter.dart';

/// Agent 3: Validator Agent
/// Checks required fields and generates smart follow-up questions
class ValidatorAgent {
  late GenerativeModel _model;
  String _currencySymbol = '\$';

  ValidatorAgent() {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.1-flash-lite-preview',
    );
  }

  /// Update the model with user-specific system instructions.
  void updateContext(UserContext ctx) {
    _currencySymbol = ctx.currencySymbol;
    final systemText = '''
You are a validation assistant that generates follow-up questions to collect missing transaction data.

${ContextFormatter.formatCoreRules(ctx)}
''';
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.1-flash-lite-preview',
      systemInstruction: Content.text(systemText),
    );
  }

  /// Validate transaction data completeness
  Future<ValidationResult> validate({
    required TransactionData transactionData,
  }) async {
    // Check required fields
    final missingRequired = transactionData.missingRequiredFields;
    final isComplete = transactionData.hasRequiredFields;

    if (isComplete) {
      return ValidationResult(
        isComplete: true,
        missingRequired: [],
        nextQuestion: null,
        confidence: 1.0,
      );
    }

    // Generate smart follow-up question
    final nextQuestion = await _generateFollowUpQuestion(
      transactionData: transactionData,
      missingFields: missingRequired,
    );

    return ValidationResult(
      isComplete: false,
      missingRequired: missingRequired,
      nextQuestion: nextQuestion,
      confidence: _calculateCompleteness(transactionData),
    );
  }

  /// Generate contextual follow-up question
  Future<String> _generateFollowUpQuestion({
    required TransactionData transactionData,
    required List<String> missingFields,
  }) async {
    try {
      final prompt = _buildQuestionPrompt(transactionData, missingFields);
      final response = await _model.generateContent([Content.text(prompt)]);
      final question = response.text?.trim() ?? _getDefaultQuestion(missingFields.first);

      return question;
    } catch (e) {
      print('Validator Agent Error: $e');
      return _getDefaultQuestion(missingFields.first);
    }
  }

  /// Build prompt for generating follow-up question
  String _buildQuestionPrompt(TransactionData data, List<String> missing) {
    return '''
You are a validation assistant. Generate a follow-up question to collect missing data.

Current transaction data:
- Amount: ${data.amount != null ? '$_currencySymbol${data.amount}' : 'missing'}
- Item: ${data.item ?? 'missing'}
- Category: ${data.category ?? 'missing'}
- Merchant: ${data.merchant ?? 'missing'}

Missing required fields: ${missing.join(', ')}

Generate ONE specific question to ask for the MOST important missing field.

Rules:
- Be conversational and friendly
- Use 1 emoji maximum
- Acknowledge what they provided first
- Keep it brief (1 sentence)
- Ask for the most critical missing field

Examples:
- If amount missing: "Got your ${data.item}! How much did it cost? 💰"
- If item missing: "What did you buy for $_currencySymbol${data.amount}? 🛍️"
- If both missing: "What did you buy and how much did it cost?"

Generate question:
''';
  }

  /// Get default question for missing field
  String _getDefaultQuestion(String missingField) {
    switch (missingField) {
      case 'amount':
        return 'How much did it cost? 💰';
      case 'item':
        return 'What did you buy? 🛍️';
      case 'category':
        return 'What category is this expense?';
      default:
        return 'Could you provide more details?';
    }
  }

  /// Calculate completeness percentage
  double _calculateCompleteness(TransactionData data) {
    const requiredCount = 3; // amount, item, category
    int completeCount = 0;

    if (data.amount != null) completeCount++;
    if (data.item != null && data.item!.isNotEmpty) completeCount++;
    if (data.category != null && data.category!.isNotEmpty) completeCount++;

    return completeCount / requiredCount;
  }
}

/// Validation result
class ValidationResult {
  final bool isComplete;
  final List<String> missingRequired;
  final String? nextQuestion;
  final double confidence;

  ValidationResult({
    required this.isComplete,
    required this.missingRequired,
    this.nextQuestion,
    required this.confidence,
  });
}

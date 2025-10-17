import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../../features/add_transaction/models/transaction_data.dart';
import 'validator_agent.dart';

/// Agent 4: Context Agent ⭐ KEY DIFFERENTIATOR
/// Analyzes transaction completeness and suggests receipt uploads
/// This is the competitive moat - encourages rich context naturally
class ContextAgent {
  late final GenerativeModel _model;

  ContextAgent() {
    // ignore: deprecated_member_use
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',
    );
  }

  /// Analyze context and provide suggestions
  Future<ContextResult> analyzeContext({
    required TransactionData transactionData,
    required ValidationResult validationResult,
  }) async {
    // Calculate context richness
    final richnessLevel = _calculateRichness(transactionData);

    // Determine if receipt upload should be suggested
    final shouldSuggestReceipt = _shouldSuggestReceipt(
      transactionData: transactionData,
      richnessLevel: richnessLevel,
    );

    // Generate contextual suggestion if needed
    String? suggestion;
    if (shouldSuggestReceipt) {
      suggestion = await _generateReceiptSuggestion(transactionData);
    }

    return ContextResult(
      richnessLevel: richnessLevel,
      shouldSuggestReceipt: shouldSuggestReceipt,
      suggestion: suggestion,
      optionalFieldsToEncourage: _getOptionalFieldsToEncourage(transactionData),
    );
  }

  /// Calculate context richness level
  String _calculateRichness(TransactionData data) {
    int score = 0;

    // Required fields
    if (data.amount != null) score++;
    if (data.item != null && data.item!.isNotEmpty) score++;
    if (data.category != null && data.category!.isNotEmpty) score++;

    // Optional but valuable fields
    if (data.merchant != null && data.merchant!.isNotEmpty) score++;
    if (data.description != null && data.description!.isNotEmpty) score++;
    if (data.location != null && data.location!.isNotEmpty) score++;

    // Richness levels
    if (score >= 6) return 'very_high'; // All fields
    if (score >= 5) return 'high';      // Required + 2 optional
    if (score >= 4) return 'medium';    // Required + 1 optional
    if (score >= 3) return 'low';       // Only required
    return 'minimal';                   // Incomplete
  }

  /// Determine if receipt upload should be suggested
  bool _shouldSuggestReceipt({
    required TransactionData transactionData,
    required String richnessLevel,
  }) {
    // Don't suggest if already rich context
    if (richnessLevel == 'very_high' || richnessLevel == 'high') {
      return false;
    }

    // Check if category benefits from itemization
    final category = transactionData.category?.toLowerCase();
    if (category == null) return false;

    // Categories that benefit from receipt uploads
    const receiptBeneficialCategories = [
      'groceries',
      'shopping',
      'dining',
      'health',
      'bills',
    ];

    return receiptBeneficialCategories.contains(category);
  }

  /// Generate receipt suggestion message
  Future<String> _generateReceiptSuggestion(TransactionData data) async {
    try {
      final prompt = '''
Generate a friendly suggestion to upload a receipt for better tracking.

Transaction: ${data.item} - \$${data.amount} (${data.category})

Rules:
- Be casual and encouraging, not pushy
- Explain the benefit (detailed item tracking)
- Keep it brief (1 sentence)
- Use 1 emoji maximum

Examples:
- "Want to snap a photo of your receipt? I can break down the items for smarter tracking! 📸"
- "Got a receipt? Upload it for item-by-item insights! 🧾"
- "Snap your receipt for detailed tracking - helps you see what you're really spending on! 📷"

Generate suggestion:
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'Want to upload your receipt for detailed tracking? 📸';
    } catch (e) {
      print('Context Agent Error: $e');
      return 'Want to upload your receipt for detailed tracking? 📸';
    }
  }

  /// Get optional fields that should be encouraged
  List<String> _getOptionalFieldsToEncourage(TransactionData data) {
    final encourage = <String>[];

    if (data.merchant == null || data.merchant!.isEmpty) {
      encourage.add('merchant');
    }
    if (data.description == null || data.description!.isEmpty) {
      encourage.add('description');
    }
    if (data.location == null || data.location!.isEmpty) {
      encourage.add('location');
    }

    // Prioritize merchant as most valuable
    if (encourage.length > 1 && encourage.contains('merchant')) {
      encourage.remove('merchant');
      encourage.insert(0, 'merchant');
    }

    return encourage;
  }
}

/// Context analysis result
class ContextResult {
  final String richnessLevel; // 'minimal', 'low', 'medium', 'high', 'very_high'
  final bool shouldSuggestReceipt;
  final String? suggestion;
  final List<String> optionalFieldsToEncourage;

  ContextResult({
    required this.richnessLevel,
    required this.shouldSuggestReceipt,
    this.suggestion,
    required this.optionalFieldsToEncourage,
  });
}

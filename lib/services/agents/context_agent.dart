import 'package:firebase_ai/firebase_ai.dart';
import '../../features/add_transaction/models/transaction_data.dart';
import '../../models/user_context.dart';
import '../../services/context_formatter.dart';
import 'validator_agent.dart';

/// Agent 4: Context Agent ⭐ KEY DIFFERENTIATOR
/// Analyzes transaction completeness and suggests receipt uploads
/// This is the competitive moat - encourages rich context naturally
class ContextAgent {
  late GenerativeModel _model;
  String _currencySymbol = '\$';

  ContextAgent() {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.1-flash-lite-preview',
    );
  }

  /// Update the model with user-specific system instructions.
  void updateContext(UserContext ctx) {
    _currencySymbol = ctx.currencySymbol;
    final systemText = '''
You are a context quality agent that encourages users to provide richer transaction details.

${ContextFormatter.formatCoreRules(ctx)}
''';
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.1-flash-lite-preview',
      systemInstruction: Content.text(systemText),
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

Transaction: ${data.item} - $_currencySymbol${data.amount} (${data.category})

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

  // ============================================================================
  // PHASE 2 ENHANCEMENTS: Transaction Evaluation Methods
  // ============================================================================

  /// Evaluate how much context we have about a transaction (Map version)
  /// Returns: 'rich', 'adequate', 'minimal'
  /// 
  /// This method works with raw transaction maps from Firestore.
  /// Use this for evaluating existing transactions.
  String evaluateTransactionRichness(Map<String, dynamic> transaction) {
    int score = 0;
    
    // Core fields (required)
    if (transaction['amount'] != null && transaction['amount'] > 0) score++;
    if (transaction['category'] != null && transaction['category'].toString().isNotEmpty) score++;
    
    // Enhanced fields (good to have)
    if (transaction['merchant'] != null && transaction['merchant'].toString().isNotEmpty) score++;
    if (transaction['items'] != null && (transaction['items'] as List).isNotEmpty) score += 2;
    if (transaction['notes'] != null && transaction['notes'].toString().isNotEmpty) score++;
    if (transaction['receipt_image_url'] != null) score += 2;
    
    // Metadata (nice to have)
    if (transaction['payment_method'] != null) score++;
    if (transaction['subcategory'] != null) score++;
    
    // Rich: 7+ points (has items, receipt, or detailed info)
    if (score >= 7) return 'rich';
    
    // Adequate: 4-6 points (has merchant and category at minimum)
    if (score >= 4) return 'adequate';
    
    // Minimal: < 4 points (missing key details)
    return 'minimal';
  }
  
  /// Determine what additional context should be requested
  /// 
  /// Use this to identify which fields are missing from a transaction.
  List<String> suggestMissingFields(Map<String, dynamic> transaction) {
    final missing = <String>[];
    
    if (transaction['merchant'] == null || transaction['merchant'].toString().isEmpty) {
      missing.add('merchant');
    }
    
    if (transaction['category'] == null || transaction['category'].toString().isEmpty) {
      missing.add('category');
    }
    
    if (transaction['items'] == null || (transaction['items'] as List?)?.isEmpty == true) {
      missing.add('items');
    }
    
    if (transaction['payment_method'] == null) {
      missing.add('payment_method');
    }
    
    return missing;
  }
  
  /// Generate a follow-up question to enrich context
  /// 
  /// Use this to prompt users for missing information.
  /// Returns empty string if transaction is already rich.
  String generateFollowUpQuestion(Map<String, dynamic> transaction) {
    final richness = evaluateTransactionRichness(transaction);
    
    if (richness == 'rich') {
      return ''; // No follow-up needed
    }
    
    final missing = suggestMissingFields(transaction);
    
    if (missing.contains('merchant')) {
      return 'Where did you make this purchase?';
    }
    
    if (missing.contains('items')) {
      final merchant = transaction['merchant'] ?? 'the store';
      return 'What did you buy at $merchant?';
    }
    
    if (missing.contains('category')) {
      return 'What category should this be? (Groceries, Dining, Transport, etc.)';
    }
    
    if (missing.contains('payment_method')) {
      return 'How did you pay? (Card, Cash, Digital wallet)';
    }
    
    return ''; // No more questions
  }
  
  /// Check if transaction has enough context for insights
  /// 
  /// Use this to determine if a transaction can be used for analytics.
  bool hasEnoughContextForInsights(Map<String, dynamic> transaction) {
    final richness = evaluateTransactionRichness(transaction);
    return richness == 'rich' || richness == 'adequate';
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

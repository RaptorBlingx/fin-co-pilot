import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../../features/add_transaction/models/transaction_data.dart';
import 'extractor_agent.dart';
import 'validator_agent.dart';
import 'context_agent.dart';

/// Agent 1: Orchestrator Agent
/// Routes requests to specialist agents and synthesizes responses
class OrchestratorAgent {
  late final GenerativeModel _model;
  final ExtractorAgent _extractorAgent;
  final ValidatorAgent _validatorAgent;
  final ContextAgent _contextAgent;

  OrchestratorAgent({
    required ExtractorAgent extractorAgent,
    required ValidatorAgent validatorAgent,
    required ContextAgent contextAgent,
  })  : _extractorAgent = extractorAgent,
        _validatorAgent = validatorAgent,
        _contextAgent = contextAgent {
    // ignore: deprecated_member_use
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',
    );
  }

  /// Main orchestration method
  Future<OrchestratorResponse> orchestrate({
    required String userMessage,
    required TransactionData currentData,
    required List<String> conversationHistory,
  }) async {
    try {
      // Step 1: Extract data using Extractor Agent
      final extractionResult = await _extractorAgent.extract(
        userMessage: userMessage,
        currentData: currentData,
      );

      // Merge extracted data with current data
      final updatedData = currentData.mergeWith(extractionResult.data);

      // Step 2: Validate completeness using Validator Agent
      final validationResult = await _validatorAgent.validate(
        transactionData: updatedData,
      );

      // Step 3: Get contextual suggestions using Context Agent
      final contextResult = await _contextAgent.analyzeContext(
        transactionData: updatedData,
        validationResult: validationResult,
      );

      // Step 4: Generate conversational response
      final conversationalResponse = await _generateConversationalResponse(
        userMessage: userMessage,
        extractedData: updatedData,
        validationResult: validationResult,
        contextResult: contextResult,
        conversationHistory: conversationHistory,
      );

      return OrchestratorResponse(
        message: conversationalResponse,
        extractedData: updatedData,
        isComplete: validationResult.isComplete,
        missingFields: validationResult.missingRequired,
        nextQuestion: validationResult.nextQuestion,
        shouldSuggestReceipt: contextResult.shouldSuggestReceipt,
        contextRichness: contextResult.richnessLevel,
        confidence: extractionResult.confidence * validationResult.confidence,
      );
    } catch (e) {
      print('Orchestrator Agent Error: $e');
      rethrow;
    }
  }

  /// Generate natural conversational response
  Future<String> _generateConversationalResponse({
    required String userMessage,
    required TransactionData extractedData,
    required ValidationResult validationResult,
    required ContextResult contextResult,
    required List<String> conversationHistory,
  }) async {
    // Build prompt for conversational response
    final prompt = StringBuffer();
    prompt.writeln('You are FinCoPilot, a friendly financial assistant.');
    prompt.writeln('Generate a conversational response based on this context:');
    prompt.writeln();

    // Add recent conversation
    if (conversationHistory.isNotEmpty) {
      prompt.writeln('Recent conversation:');
      for (final msg in conversationHistory.takeLast(3)) {
        prompt.writeln('- $msg');
      }
      prompt.writeln();
    }

    // Add extraction context
    prompt.writeln('User just said: "$userMessage"');
    prompt.writeln('Extracted: ${extractedData.completeFields.join(", ")}');
    prompt.writeln();

    // Add validation status
    if (validationResult.isComplete) {
      prompt.writeln('Status: All required fields complete! ✓');
      prompt.writeln('Instruction: Confirm completion positively. Be encouraging.');
    } else {
      prompt.writeln('Status: Missing ${validationResult.missingRequired.join(", ")}');
      prompt.writeln('Instruction: Ask for missing field: ${validationResult.nextQuestion}');
    }

    // Add context suggestions
    if (contextResult.shouldSuggestReceipt) {
      prompt.writeln();
      prompt.writeln('Optional: Suggest receipt upload after confirming basics.');
      prompt.writeln('Say something like: "Want to snap a receipt for detailed tracking?"');
    }

    prompt.writeln();
    prompt.writeln('Rules:');
    prompt.writeln('- Be conversational and friendly (2 sentences max)');
    prompt.writeln('- Use 1 relevant emoji maximum');
    prompt.writeln('- Acknowledge what user provided before asking for more');
    prompt.writeln('- If complete, celebrate briefly then move to confirmation');
    prompt.writeln();
    prompt.writeln('Respond naturally:');

    try {
      final response = await _model.generateContent([Content.text(prompt.toString())]);
      return response.text?.trim() ?? validationResult.nextQuestion ?? 'Got it!';
    } catch (e) {
      // Fallback to validation question
      if (validationResult.isComplete) {
        return 'Perfect! I\'ve got all the details. ✓';
      } else {
        return validationResult.nextQuestion ?? 'What else can you tell me?';
      }
    }
  }
}

/// Orchestrator response
class OrchestratorResponse {
  final String message;
  final TransactionData extractedData;
  final bool isComplete;
  final List<String> missingFields;
  final String? nextQuestion;
  final bool shouldSuggestReceipt;
  final String contextRichness; // 'low', 'medium', 'high', 'very_high'
  final double confidence;

  OrchestratorResponse({
    required this.message,
    required this.extractedData,
    required this.isComplete,
    required this.missingFields,
    this.nextQuestion,
    required this.shouldSuggestReceipt,
    required this.contextRichness,
    required this.confidence,
  });
}

// Extension for better list handling
extension IterableExtension<E> on Iterable<E> {
  Iterable<E> takeLast(int count) {
    if (count >= length) return this;
    return skip(length - count);
  }
}

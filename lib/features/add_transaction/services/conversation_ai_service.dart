import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/transaction_data.dart';
import 'robust_ai_service.dart';

/// Enhanced AI conversation response
class ConversationResponse {
  final ChatMessage message;
  final TransactionData extractedData;
  final String nextAction; // 'ask_for_missing', 'show_preview', 'encourage_optional'
  final List<String> missingFields;
  final String? followUpQuestion;
  final double confidence;

  ConversationResponse({
    required this.message,
    required this.extractedData,
    required this.nextAction,
    required this.missingFields,
    this.followUpQuestion,
    this.confidence = 1.0,
  });
}

class ConversationAIService {
  final RobustAIService _aiService;

  ConversationAIService(this._aiService);

  /// Process user message with enhanced AI integration
  Future<ConversationResponse> processUserMessage({
    required String userMessage,
    required TransactionData currentData,
  }) async {
    try {
      // Call the RobustAIService to get structured response
      final aiResponse = await _aiService.processMessage(
        userMessage: userMessage,
        currentData: currentData,
      );

      // Create appropriate chat message based on AI response
      ChatMessage chatMessage;

      if (aiResponse.readyToSave && aiResponse.extractedData.hasRequiredFields) {
        // All required fields collected - show transaction preview
        chatMessage = ChatMessage.transactionPreview(
          preview: TransactionPreview(
            amount: aiResponse.extractedData.amount!,
            currency: aiResponse.extractedData.currency ?? 'USD',
            description: aiResponse.extractedData.item ?? 'Purchase',
            category: aiResponse.extractedData.category ?? 'Other',
            merchant: aiResponse.extractedData.merchant,
            date: aiResponse.extractedData.date ?? DateTime.now(),
          ),
        );
      } else {
        // Still collecting data - show text message
        chatMessage = ChatMessage.text(
          sender: MessageSender.ai,
          text: aiResponse.message,
        );
      }

      return ConversationResponse(
        message: chatMessage,
        extractedData: aiResponse.extractedData,
        nextAction: aiResponse.readyToSave ? 'show_preview' : 'ask_for_missing',
        missingFields: aiResponse.missingRequired,
        followUpQuestion: aiResponse.nextQuestion,
        confidence: aiResponse.confidence,
      );
    } catch (e) {
      print('AI Service Error: $e');
      // Enhanced fallback
      return _createFallbackResponse(userMessage, currentData);
    }
  }

  /// Create intelligent fallback response when AI fails
  ConversationResponse _createFallbackResponse(String userMessage, TransactionData currentData) {
    // Generate smart response based on what's missing
    String responseText;
    final missingFields = currentData.missingRequiredFields;

    if (currentData.hasRequiredFields) {
      // Complete transaction - show preview
      final chatMessage = ChatMessage.transactionPreview(
        preview: TransactionPreview(
          amount: currentData.amount!,
          currency: currentData.currency ?? 'USD',
          description: currentData.item ?? 'Purchase',
          category: currentData.category ?? 'Other',
          merchant: currentData.merchant,
          date: currentData.date ?? DateTime.now(),
        ),
      );

      return ConversationResponse(
        message: chatMessage,
        extractedData: currentData,
        nextAction: 'show_preview',
        missingFields: [],
      );
    } else {
      // Missing required fields - ask for them
      if (missingFields.contains('amount')) {
        responseText = currentData.item != null
            ? 'Got ${currentData.item}! How much did it cost? 💰'
            : 'How much did you spend? 💰';
      } else if (missingFields.contains('item')) {
        responseText = currentData.amount != null
            ? 'What did you buy for \$${currentData.amount}? 🛍️'
            : 'What did you buy? 🛍️';
      } else {
        responseText = 'I didn\'t catch that. Could you tell me what you bought and how much it cost?';
      }

      final chatMessage = ChatMessage.text(
        sender: MessageSender.ai,
        text: responseText,
      );

      return ConversationResponse(
        message: chatMessage,
        extractedData: currentData,
        nextAction: 'ask_for_missing',
        missingFields: missingFields,
      );
    }
  }

  /// Clear conversation history
  void clearHistory() {
    _aiService.clearHistory();
  }
}

/// Enhanced conversation response types
enum ConversationAction {
  askForMissing,
  showPreview,
  encourageOptional,
  clarifyInput,
}

// Provider
final conversationAIServiceProvider = Provider<ConversationAIService>((ref) {
  // Create the RobustAIService instance
  final robustAI = RobustAIService();
  return ConversationAIService(robustAI);
});


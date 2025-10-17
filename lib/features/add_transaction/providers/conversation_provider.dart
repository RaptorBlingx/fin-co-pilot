import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/transaction_data.dart';
import '../services/conversation_ai_service.dart';

enum ConversationState {
  initial,
  collecting,
  confirming,
  completed,
}

class ConversationNotifier extends StateNotifier<ConversationData> {
  final ConversationAIService _aiService;
  
  ConversationNotifier(this._aiService) : super(ConversationData()) {
    _startConversation();
  }

  void _startConversation() {
    // Add initial AI greeting
    _addMessage(ChatMessage.text(
      sender: MessageSender.ai,
      text: "Hi! What did you buy? 💰",
    ));
  }

  void handleUserMessage(String text) async {
    // Add user message
    _addMessage(ChatMessage.text(
      sender: MessageSender.user,
      text: text,
    ));

    // Show loading
    _addMessage(ChatMessage.loading());

    try {
      // Process with enhanced AI service
      final response = await _aiService.processUserMessage(
        userMessage: text,
        currentData: state.transactionData,
      );
      
      // Remove loading message
      _removeLoadingMessage();
      
      // Add AI response
      _addMessage(response.message);
      
      // Update transaction data and state
      state = state.copyWith(
        transactionData: response.extractedData,
        conversationState: response.extractedData.hasRequiredFields 
            ? ConversationState.confirming 
            : ConversationState.collecting,
      );
      
    } catch (e) {
      _removeLoadingMessage();
      _addMessage(ChatMessage.text(
        sender: MessageSender.ai,
        text: "I'm having trouble processing that. Could you try rephrasing?",
      ));
    }
  }

  // Helper methods

  // All conversation logic now handled by enhanced AI service

  void _addMessage(ChatMessage message) {
    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }

  void _removeLoadingMessage() {
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != 'loading').toList(),
    );
  }

  void reset() {
    state = ConversationData();
    _startConversation();
  }
}

// State class
class ConversationData {
  final List<ChatMessage> messages;
  final ConversationState conversationState;
  final TransactionData transactionData;

  ConversationData({
    List<ChatMessage>? messages,
    ConversationState? conversationState,
    TransactionData? transactionData,
  })  : messages = messages ?? [],
        conversationState = conversationState ?? ConversationState.initial,
        transactionData = transactionData ?? const TransactionData();

  ConversationData copyWith({
    List<ChatMessage>? messages,
    ConversationState? conversationState,
    TransactionData? transactionData,
  }) {
    return ConversationData(
      messages: messages ?? this.messages,
      conversationState: conversationState ?? this.conversationState,
      transactionData: transactionData ?? this.transactionData,
    );
  }
}

// Provider
final conversationProvider = StateNotifierProvider<ConversationNotifier, ConversationData>(
  (ref) {
    final aiService = ref.watch(conversationAIServiceProvider);
    return ConversationNotifier(aiService);
  },
);
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../providers/conversation_provider.dart';
import '../services/voice_input_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/agents/receipt_agent.dart';
import 'receipt_review_screen.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _handleSendMessage(String text) {
    ref.read(conversationProvider.notifier).handleUserMessage(text);
    _scrollToBottom();
  }

  void _handleCameraPressed() {
    // TODO: Implement camera/receipt photo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera feature coming in Step 5.7')),
    );
  }

  void _handleVoicePressed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceInputBottomSheet(
        onComplete: (text) {
          // Process the voice input
          _handleSendMessage(text);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(conversationProvider);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Expense'),
        actions: [
          // Reset conversation
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(conversationProvider.notifier).reset();
            },
            tooltip: 'Start over',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: conversation.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: conversation.messages.length,
                    itemBuilder: (context, index) {
                      final message = conversation.messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ChatBubble(message: message),
                      );
                    },
                  ),
          ),
          
          // Message input bar
          MessageInputBar(
            onSendMessage: _handleSendMessage,
            onCameraPressed: _handleCameraPressed,
            onVoicePressed: _handleVoicePressed,
            enabled: conversation.conversationState != ConversationState.completed,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Let\'s add an expense',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Just tell me what you bought',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 24),
          // Quick examples
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Try saying:',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 12),
                _buildExampleChip('Coffee \$5.45'),
                const SizedBox(height: 8),
                _buildExampleChip('Lunch 20'),
                const SizedBox(height: 8),
                _buildExampleChip('Groceries at Costco'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryIndigo.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: AppTheme.primaryIndigo,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.primaryIndigo,
            ),
          ),
        ],
      ),
    );
  }
}
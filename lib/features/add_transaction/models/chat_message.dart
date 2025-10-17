import 'package:flutter/material.dart';

enum MessageSender {
  user,
  ai,
}

enum MessageType {
  text,
  transactionPreview,
  quickActions,
  loading,
}

class ChatMessage {
  final String id;
  final MessageSender sender;
  final MessageType type;
  final String? text;
  final DateTime timestamp;
  final TransactionPreview? transactionPreview;
  final List<QuickAction>? quickActions;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.type,
    this.text,
    DateTime? timestamp,
    this.transactionPreview,
    this.quickActions,
  }) : timestamp = timestamp ?? DateTime.now();

  // Factory for text message
  factory ChatMessage.text({
    required MessageSender sender,
    required String text,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: sender,
      type: MessageType.text,
      text: text,
    );
  }

  // Factory for transaction preview
  factory ChatMessage.transactionPreview({
    required TransactionPreview preview,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.ai,
      type: MessageType.transactionPreview,
      transactionPreview: preview,
    );
  }

  // Factory for quick actions
  factory ChatMessage.quickActions({
    required List<QuickAction> actions,
    String? text,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.ai,
      type: MessageType.quickActions,
      text: text,
      quickActions: actions,
    );
  }

  // Factory for loading message
  factory ChatMessage.loading() {
    return ChatMessage(
      id: 'loading',
      sender: MessageSender.ai,
      type: MessageType.loading,
    );
  }
}

// Transaction preview data
class TransactionPreview {
  final double amount;
  final String currency;
  final String? merchant;
  final String category;
  final String? description;
  final DateTime date;
  final String? categoryEmoji;

  TransactionPreview({
    required this.amount,
    required this.currency,
    this.merchant,
    required this.category,
    this.description,
    DateTime? date,
    this.categoryEmoji,
  }) : date = date ?? DateTime.now();
}

// Quick action button
class QuickAction {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  QuickAction({
    required this.label,
    this.icon,
    required this.onTap,
  });
}
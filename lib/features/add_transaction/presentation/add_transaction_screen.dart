import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:typed_data';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../providers/conversation_provider.dart';
import '../services/voice_input_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/agents/receipt_agent.dart';
import '../../../services/agents/item_tracker_agent.dart';
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

  void _handleCameraPressed() async {
    // Show options: Camera or Gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      // Pick image
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show processing dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing receipt...\nThis may take a few seconds'),
                ],
              ),
            ),
          ),
        ),
      );

      // Read image bytes
      final Uint8List imageBytes = await File(image.path).readAsBytes();

      // Process with Receipt Agent
      final receiptAgent = ReceiptAgent();
      final receiptData = await receiptAgent.extractFromReceipt(
        imageBytes: imageBytes,
      );

      // Dismiss processing dialog
      if (!mounted) return;
      Navigator.pop(context);

      // Show receipt review screen
      if (!mounted) return;
      final confirmedReceipt = await Navigator.push<ReceiptExtractionResult>(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptReviewScreen(
            receiptData: receiptData,
          ),
        ),
      );

      // If user confirmed, process the receipt
      if (confirmedReceipt != null && mounted) {
        _processConfirmedReceipt(confirmedReceipt);
      }
    } catch (e) {
      // Dismiss processing dialog if open
      if (mounted) Navigator.pop(context);

      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process receipt: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _processConfirmedReceipt(ReceiptExtractionResult receipt) async {
    final itemCount = receipt.items.length;
    final total = receipt.total;
    final merchant = receipt.merchant ?? 'Unknown Store';

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Save items using Item Tracker Agent
      if (receipt.items.isNotEmpty) {
        final itemTracker = ItemTrackerAgent();

        // Generate a temporary transaction ID (will be replaced when full transaction is saved)
        final tempTransactionId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

        await itemTracker.trackItems(
          userId: user.uid,
          transactionId: tempTransactionId,
          items: receipt.items,
          purchaseDate: receipt.date ?? DateTime.now(),
          merchant: receipt.merchant,
        );
      }

      // Create message summary for conversation
      final summary = 'Receipt from $merchant: $itemCount items, total \$${total.toStringAsFixed(2)}';

      // Send to conversation AI
      _handleSendMessage(summary);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt processed! $itemCount items tracked 📊'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error saving items: $e');
      // Still send summary to conversation even if item tracking fails
      final summary = 'Receipt from $merchant: $itemCount items, total \$${total.toStringAsFixed(2)}';
      _handleSendMessage(summary);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt processed (item tracking failed: $e)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../providers/conversation_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../services/agents/receipt_agent.dart';
import '../../../services/agents/item_tracker_agent.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
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
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: DesignTokens.durationNormal,
            curve: DesignTokens.curveDecelerate,
          );
        }
      });
    }
  }

  void _handleSendMessage(String text) {
    ref.read(conversationProvider.notifier).handleUserMessage(text);
    _scrollToBottom();
  }

  void _handleCameraPressed() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DesignTokens.radiusXL),
            topRight: Radius.circular(DesignTokens.radiusXL),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: DesignTokens.space8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: DesignTokens.space16),
              ListTile(
                leading: Icon(PhosphorIcons.camera(),
                    color: AppTheme.primaryIndigo),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(PhosphorIcons.images(),
                    color: AppTheme.primaryIndigo),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: DesignTokens.space8),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show processing overlay
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: GlassCard(
            padding: const EdgeInsets.all(DesignTokens.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.primaryIndigo,
                  ),
                ),
                const SizedBox(height: DesignTokens.space16),
                Text(
                  'Scanning receipt…',
                  style: context.textTheme.bodyMedium,
                ),
                const SizedBox(height: DesignTokens.space4),
                Text(
                  'This may take a few seconds',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final Uint8List imageBytes = await File(image.path).readAsBytes();

      final receiptAgent = ReceiptAgent();
      final receiptData = await receiptAgent.extractFromReceipt(
        imageBytes: imageBytes,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (!mounted) return;
      _processConfirmedReceipt(receiptData);
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (!mounted) return;
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Couldn\'t process receipt: ${e.toString()}'),
          backgroundColor: AppTheme.rose500,
        ),
      );
    }
  }

  void _processConfirmedReceipt(ReceiptExtractionResult receipt) async {
    final itemCount = receipt.items.length;
    final total = receipt.total;
    final merchant = receipt.merchant ?? 'Unknown Store';

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (receipt.items.isNotEmpty) {
        final itemTracker = ItemTrackerAgent();
        final tempTransactionId =
            'temp_${DateTime.now().millisecondsSinceEpoch}';

        await itemTracker.trackItems(
          userId: user.uid,
          transactionId: tempTransactionId,
          items: receipt.items,
          purchaseDate: receipt.date ?? DateTime.now(),
          merchant: receipt.merchant,
        );
      }

      final summary =
          'Receipt from $merchant: $itemCount items, total \$${total.toStringAsFixed(2)}';
      _handleSendMessage(summary);

      if (mounted) {
        HapticUtils.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt processed! $itemCount items tracked'),
            backgroundColor: AppTheme.accentEmerald,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      final summary =
          'Receipt from $merchant: $itemCount items, total \$${total.toStringAsFixed(2)}';
      _handleSendMessage(summary);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt processed (item tracking failed)'),
            backgroundColor: AppTheme.amber500,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(conversationProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Custom header ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space16,
                vertical: DesignTokens.space12,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticUtils.light();
                      Navigator.pop(context);
                    },
                    child: Icon(PhosphorIcons.x(),
                        size: DesignTokens.iconMD),
                  ),
                  const SizedBox(width: DesignTokens.space12),
                  Expanded(
                    child: Text('Add Expense',
                        style: context.textTheme.titleMedium),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticUtils.light();
                      ref.read(conversationProvider.notifier).reset();
                    },
                    child: Icon(PhosphorIcons.arrowCounterClockwise(),
                        size: DesignTokens.iconMD,
                        color: context.colors.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ),

          // ── Chat messages ──
          Expanded(
            child: conversation.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(DesignTokens.space16),
                    itemCount: conversation.messages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: DesignTokens.space8),
                        child: ChatBubble(
                            message: conversation.messages[index]),
                      );
                    },
                  ),
          ),

          // ── Input bar ──
          MessageInputBar(
            onSendMessage: _handleSendMessage,
            onCameraPressed: _handleCameraPressed,
            enabled: conversation.conversationState !=
                ConversationState.completed,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: DesignTokens.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.chatCircle(PhosphorIconsStyle.fill),
                size: 32,
                color: Colors.white,
              ),
            )
                .animate()
                .fadeIn(duration: DesignTokens.durationNormal)
                .scaleXY(begin: 0.8, end: 1.0),
            const SizedBox(height: DesignTokens.space24),
            Text(
              'Let\'s add an expense',
              style: context.textTheme.titleLarge,
            )
                .animate()
                .fadeIn(
                  delay: const Duration(milliseconds: 100),
                  duration: DesignTokens.durationNormal,
                )
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: DesignTokens.space8),
            Text(
              'Just tell me what you bought',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface.withOpacity(0.5),
              ),
            )
                .animate()
                .fadeIn(
                  delay: const Duration(milliseconds: 200),
                  duration: DesignTokens.durationNormal,
                )
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: DesignTokens.space32),
            // Quick examples
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Try saying:',
                    style: context.textTheme.labelMedium?.copyWith(
                      color:
                          context.colors.onSurface.withOpacity(0.5),
                    )),
                const SizedBox(height: DesignTokens.space12),
                _ExampleChip(
                  text: 'Coffee \$5.45',
                  delay: 300,
                  onTap: () => _handleSendMessage('Coffee \$5.45'),
                ),
                const SizedBox(height: DesignTokens.space8),
                _ExampleChip(
                  text: 'Lunch 20',
                  delay: 400,
                  onTap: () => _handleSendMessage('Lunch 20'),
                ),
                const SizedBox(height: DesignTokens.space8),
                _ExampleChip(
                  text: 'Groceries at Costco',
                  delay: 500,
                  onTap: () =>
                      _handleSendMessage('Groceries at Costco'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String text;
  final int delay;
  final VoidCallback onTap;

  const _ExampleChip({
    required this.text,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticUtils.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16,
          vertical: DesignTokens.space8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryIndigo.withOpacity(0.06),
          borderRadius:
              BorderRadius.circular(DesignTokens.radiusSM),
          border: Border.all(
            color: AppTheme.primaryIndigo.withOpacity(0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.lightbulb(),
              size: 16,
              color: AppTheme.primaryIndigo,
            ),
            const SizedBox(width: DesignTokens.space8),
            Text(
              text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryIndigo,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: DesignTokens.durationNormal,
        )
        .slideX(begin: -0.05, end: 0);
  }
}
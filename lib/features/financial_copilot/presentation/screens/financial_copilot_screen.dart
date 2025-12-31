import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/transaction_service.dart';
import '../../../../services/financial_copilot_orchestrator.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../services/preferences_service.dart';
import '../../../../shared/models/transaction.dart' as model;
import '../../../budget/presentation/screens/budget_screen.dart';
import '../../../insights/presentation/screens/insights_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../price_intelligence/presentation/price_intelligence_screen.dart';

class FinancialCopilotScreen extends StatefulWidget {
  const FinancialCopilotScreen({super.key});

  @override
  State<FinancialCopilotScreen> createState() => _FinancialCopilotScreenState();
}

class _FinancialCopilotScreenState extends State<FinancialCopilotScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final FinancialCopilotOrchestrator _orchestrator = FinancialCopilotOrchestrator();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService _transactionService = TransactionService();

  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCopilot();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeCopilot() async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Get user context
    final userContext = await _getUserContext();

    // Get personalized greeting
    final greeting = await _orchestrator.getGreeting(
      userName: user.displayName ?? 'there',
      userContext: userContext,
    );

    setState(() {
      _messages.add(ChatMessage(
        text: greeting['greeting'],
        isUser: false,
        timestamp: DateTime.now(),
        quickActions: (greeting['quickActions'] as List?)
            ?.map((e) => QuickAction.fromMap(e as Map<String, dynamic>))
            .toList(),
      ));
      _isInitialized = true;
    });

    _scrollToBottom();
  }

  Future<Map<String, dynamic>> _getUserContext() async {
    final user = _authService.currentUser;
    if (user == null) return {};

    try {
      // Get real transaction count
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: user.uid)
          .limit(1)
          .get();
      final transactionCount = transactionsSnapshot.docs.length;

      // Check if user has budget
      final now = DateTime.now();
      final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final budgetsSnapshot = await _firestore
          .collection('budgets')
          .where('user_id', isEqualTo: user.uid)
          .where('month', isEqualTo: currentMonth)
          .limit(1)
          .get();
      final hasBudget = budgetsSnapshot.docs.isNotEmpty;

      return {
        'userId': user.uid,
        'transactionCount': transactionCount,
        'hasBudget': hasBudget,
      };
    } catch (e) {
      return {
        'userId': user.uid,
        'transactionCount': 0,
        'hasBudget': false,
      };
    }
  }

  Future<void> _handleUserMessage(String message) async {
    if (message.trim().isEmpty) return;

    HapticUtils.light();

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isProcessing = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Get user context
      final userContext = await _getUserContext();

      // Process message through orchestrator
      final response = await _orchestrator.processUserMessage(
        message: message,
        userId: _authService.currentUser!.uid,
        userContext: userContext,
      );

      // Handle response based on type
      await _handleOrchestratorResponse(response);
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'I apologize, but I encountered an issue. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _handleOrchestratorResponse(Map<String, dynamic> response) async {
    final type = response['type'];
    final data = response['data'] as Map<String, dynamic>;

    String responseText;
    List<QuickAction>? actions;

    switch (type) {
      case 'add_transaction':
        responseText = _buildTransactionResponse(data);
        actions = [
          QuickAction(label: '✓ Confirm', action: 'confirm_transaction', data: data),
          QuickAction(label: '✎ Edit', action: 'edit_transaction', data: data),
        ];
        break;

      case 'financial_advice':
        responseText = data['answer'] ?? 'Here\'s my advice...';
        if (data['tip'] != null) {
          responseText += '\n\n💡 Tip: ${data['tip']}';
        }
        if (data['action'] != null) {
          final action = data['action'] as Map<String, dynamic>;
          actions = [
            QuickAction(
              label: action['label'] ?? 'Take Action',
              action: action['type'] ?? 'general',
            ),
          ];
        }
        break;

      case 'price_comparison':
        responseText = data['response'] ?? 'Let me help you find prices...';
        actions = [
          QuickAction(label: '🔍 Search Prices', action: 'navigate_price_intelligence'),
        ];
        break;

      case 'budget_analysis':
        responseText = data['response'] ?? 'Here\'s your budget analysis...';
        if (data['suggestion'] != null) {
          responseText += '\n\n💡 ${data['suggestion']}';
        }
        if (data['action'] != null) {
          final action = data['action'] as Map<String, dynamic>;
          actions = [
            QuickAction(
              label: action['label'] ?? 'View Budget',
              action: action['type'] ?? 'navigate_budget',
            ),
          ];
        }
        break;

      case 'spending_insights':
        final insights = data['insights'] as List?;
        if (insights != null && insights.isNotEmpty) {
          responseText = 'Here are your key insights:\n\n';
          for (int i = 0; i < insights.length; i++) {
            responseText += '${i + 1}. ${insights[i]}\n';
          }
        } else {
          responseText = 'Start tracking expenses to see personalized insights.';
        }
        actions = [
          QuickAction(label: '📊 View Full Insights', action: 'navigate_insights'),
        ];
        break;

      case 'generate_report':
        responseText = data['response'] ?? 'I can generate a report for you.';
        actions = [
          QuickAction(label: '📄 Open Reports', action: 'navigate_reports'),
        ];
        break;

      default:
        responseText = data['response'] ?? 'I\'m here to help!';
        if (data['action'] != null) {
          final action = data['action'] as Map<String, dynamic>;
          actions = [
            QuickAction(
              label: action['label'] ?? 'Take Action',
              action: action['type'] ?? 'general',
            ),
          ];
        }
    }

    setState(() {
      _messages.add(ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
        quickActions: actions,
      ));
    });
  }

  String _buildTransactionResponse(Map<String, dynamic> data) {
    if (data['error'] != null) {
      return 'I\'d be happy to help you add a transaction. Could you tell me:\n• How much did you spend?\n• Where did you shop?\n• What category (groceries, dining, etc.)?';
    }

    final amount = data['amount'];
    final merchant = data['merchant'];
    final category = data['category'];
    final description = data['description'];

    String response = 'I\'ll add this transaction:\n\n';
    if (amount != null) response += '💵 Amount: \$${amount}\n';
    if (merchant != null) response += '🏪 Merchant: $merchant\n';
    if (category != null) response += '📁 Category: $category\n';
    if (description != null) response += '📝 Description: $description\n';
    response += '\nDoes this look correct?';

    return response;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveTransaction(Map<String, dynamic>? data) async {
    if (data == null) return;

    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final transaction = model.Transaction(
        userId: user.uid,
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        currency: PreferencesService.getCurrency() ?? 'USD',
        category: (data['category'] as String?) ?? 'other',
        merchant: data['merchant'] as String?,
        description: (data['description'] as String?) ?? 'Transaction',
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        inputMethod: 'chat',
        paymentMethod: (data['payment_method'] as String?) ?? 'cash',
      );

      await _firestore.collection('transactions').add(transaction.toFirestore());

      // Update budget spending
      await _transactionService.updateBudgetSpendingPublic(
        userId: user.uid,
        category: transaction.category,
        amount: transaction.amount,
        transactionDate: transaction.transactionDate,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '✓ Transaction saved successfully! Your ${data['category']} expense of ${CurrencyUtils.formatAmount(data['amount'], transaction.currency)} has been recorded.',
            isUser: false,
            timestamp: DateTime.now(),
            quickActions: [
              QuickAction(label: '📊 View Insights', action: 'navigate_insights'),
              QuickAction(label: '💰 Check Budget', action: 'navigate_budget'),
            ],
          ));
        });
        _scrollToBottom();
        HapticUtils.success();
      }
    } catch (e, stackTrace) {
      print('ERROR saving transaction: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '❌ Sorry, I couldn\'t save the transaction. Error: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _showEditTransactionDialog(Map<String, dynamic>? data) {
    if (data == null) return;

    final amountController = TextEditingController(
      text: data['amount']?.toString() ?? '',
    );
    final merchantController = TextEditingController(
      text: data['merchant'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: data['description'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Transaction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: merchantController,
                decoration: const InputDecoration(
                  labelText: 'Merchant',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final updatedData = {
                ...data,
                'amount': double.tryParse(amountController.text) ?? data['amount'],
                'merchant': merchantController.text,
                'description': descriptionController.text,
              };
              Navigator.pop(context);
              _handleQuickAction(QuickAction(
                label: 'Confirm',
                action: 'confirm_transaction',
                data: updatedData,
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleQuickAction(QuickAction action) async {
    HapticUtils.medium();

    switch (action.action) {
      case 'add_transaction':
        _messageController.text = 'I want to add an expense';
        _handleUserMessage(_messageController.text);
        break;

      case 'financial_advice':
        _messageController.text = 'Give me some financial advice';
        _handleUserMessage(_messageController.text);
        break;

      case 'price_comparison':
        _messageController.text = 'Help me find the best price';
        _handleUserMessage(_messageController.text);
        break;

      case 'budget_analysis':
        _messageController.text = 'How\'s my budget looking?';
        _handleUserMessage(_messageController.text);
        break;

      case 'navigate_budget':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BudgetScreen()),
        );
        break;

      case 'navigate_insights':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InsightsScreen()),
        );
        break;

      case 'navigate_reports':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReportsScreen()),
        );
        break;

      case 'navigate_price_intelligence':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PriceIntelligenceScreen()),
        );
        break;

      case 'confirm_transaction':
        await _saveTransaction(action.data);
        break;

      case 'edit_transaction':
        _showEditTransactionDialog(action.data);
        break;

      default:
        _handleUserMessage(action.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text('Fin Copilot'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: !_isInitialized
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isProcessing ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isProcessing) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about your finances...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: _handleUserMessage,
                    enabled: !_isProcessing,
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _handleUserMessage(_messageController.text),
                  mini: true,
                  child: _isProcessing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      topLeft: message.isUser ? null : const Radius.circular(4),
                      topRight: message.isUser ? const Radius.circular(4) : null,
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
          if (message.quickActions != null && message.quickActions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.quickActions!
                    .map((action) => _buildQuickActionChip(action))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(QuickAction action) {
    return ActionChip(
      label: Text(action.label),
      avatar: const Icon(Icons.touch_app, size: 16),
      onPressed: () => _handleQuickAction(action),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
      side: BorderSide(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20).copyWith(
                topLeft: const Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 6),
                _buildDot(1),
                const SizedBox(width: 6),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final delay = index * 0.2;
        final adjustedValue = (value - delay).clamp(0.0, 1.0);
        final opacity = (adjustedValue * 2).clamp(0.3, 1.0);

        return Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {}); // Restart animation
        }
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<QuickAction>? quickActions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickActions,
  });
}

class QuickAction {
  final String label;
  final String action;
  final Map<String, dynamic>? data;

  QuickAction({
    required this.label,
    required this.action,
    this.data,
  });

  factory QuickAction.fromMap(Map<String, dynamic> map) {
    return QuickAction(
      label: map['label'] as String,
      action: map['action'] as String,
      data: map['data'] as Map<String, dynamic>?,
    );
  }
}

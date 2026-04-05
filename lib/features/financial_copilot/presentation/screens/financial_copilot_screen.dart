import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/navigation/page_transitions.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/transaction_service.dart';
import '../../../../services/financial_copilot_orchestrator.dart';
import '../../../../services/user_context_builder.dart';
import '../../../../services/connectivity_service.dart';
import '../../../../models/user_context.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../services/preferences_service.dart';
import '../../../../models/transaction.dart' as model;
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../shared/widgets/markdown_text.dart';
import '../../../../services/agents/receipt_agent.dart';
import '../../../../services/agents/item_tracker_agent.dart';
import '../../../../services/file_analysis_service.dart';
import '../../../../services/memory_service.dart';
import '../../../../services/nudge_service.dart';
import '../../../../services/conversation_memory_service.dart';
import '../../../../services/chat_history_service.dart';
import '../../../../services/premium_gate_service.dart';
import '../../../../models/chat_session.dart';
import '../widgets/chat_history_drawer.dart';
import '../../../add_transaction/widgets/message_input_bar.dart';
import '../../../budget/presentation/screens/budget_screen.dart';
import '../../../insights/presentation/screens/insights_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../price_intelligence/presentation/price_intelligence_screen.dart';
import '../../../transactions/presentation/screens/manual_transaction_screen.dart';

class FinancialCopilotScreen extends StatefulWidget {
  const FinancialCopilotScreen({super.key});

  @override
  State<FinancialCopilotScreen> createState() => _FinancialCopilotScreenState();
}

class _FinancialCopilotScreenState extends State<FinancialCopilotScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final FinancialCopilotOrchestrator _orchestrator =
      FinancialCopilotOrchestrator();
  final UserContextBuilder _contextBuilder = UserContextBuilder();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService _transactionService = TransactionService();
  final MemoryService _memoryService = MemoryService();
  final NudgeService _nudgeService = NudgeService();
  final ConversationMemoryService _conversationMemory = ConversationMemoryService();
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  final GlobalKey<MessageInputBarState> _inputBarKey = GlobalKey<MessageInputBarState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;
  bool _isInitialized = false;
  bool _showScrollToBottom = false;
  bool _hasText = false;
  bool _isStreaming = false;
  bool _isOffline = false;
  String? _currentSessionId;
  bool _sessionTitleSet = false;
  UserContext? _cachedRichContext;

  // Live processing timer
  final Stopwatch _liveStopwatch = Stopwatch();
  Timer? _liveTimerTick;
  int _liveElapsedMs = 0;

  // Thinking text state
  String _thinkingText = 'Thinking';
  Timer? _thinkingTimer;
  int _thinkingPhaseIndex = 0;
  List<String> _thinkingPhrases = const ['Thinking'];

  static const _defaultPhrases = [
    'Thinking',
    'Analyzing',
    'Processing',
    'Understanding your request',
    'Working on it',
    'Almost there',
    'Putting it together',
    'Just a moment',
  ];

  static const _transactionPhrases = [
    'Reading your message',
    'Extracting details',
    'Identifying the amount',
    'Detecting the merchant',
    'Categorizing expense',
    'Preparing transaction',
    'Double-checking details',
    'Finalizing entry',
  ];

  static const _budgetPhrases = [
    'Checking your budgets',
    'Pulling spending data',
    'Comparing against limits',
    'Crunching the numbers',
    'Analyzing categories',
    'Spotting trends',
    'Calculating remaining budget',
    'Preparing summary',
  ];

  static const _advicePhrases = [
    'Reviewing your finances',
    'Analyzing your habits',
    'Finding insights',
    'Considering your goals',
    'Researching strategies',
    'Crafting personalized tips',
    'Building recommendations',
    'Polishing advice',
  ];

  static const _pricePhrases = [
    'Searching prices',
    'Scanning retailers',
    'Comparing deals',
    'Checking availability',
    'Evaluating options',
    'Finding best value',
    'Ranking results',
    'Preparing comparison',
  ];

  static const _insightPhrases = [
    'Analyzing patterns',
    'Reviewing transactions',
    'Spotting anomalies',
    'Calculating averages',
    'Comparing periods',
    'Identifying trends',
    'Summarizing findings',
    'Generating insights',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    ConnectivityService().isOnline.addListener(_onConnectivityChanged);
    _isOffline = !ConnectivityService().isOnline.value;
    _initializeCopilot();
  }

  @override
  void dispose() {
    ConnectivityService().isOnline.removeListener(_onConnectivityChanged);
    WidgetsBinding.instance.removeObserver(this);
    _saveConversationMemory();
    _thinkingTimer?.cancel();
    _liveTimerTick?.cancel();
    _messageController.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (!mounted) return;
    setState(() => _isOffline = !ConnectivityService().isOnline.value);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveConversationMemory();
    }
  }

  void _saveConversationMemory() {
    final user = _authService.currentUser;
    if (user == null || _messages.length < 3) return;
    final snapshots = _messages
        .map((m) => MessageSnapshot(text: m.text, isUser: m.isUser))
        .toList();
    // Fire-and-forget
    _conversationMemory.summarizeAndStore(
      userId: user.uid,
      messages: snapshots,
    );
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset <
        _scrollController.position.maxScrollExtent - 200;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }
  }

  // ── Camera / Voice / Attach handlers ──

  void _handleCameraPressed() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusXL),
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
      if (!mounted) return;

      final Uint8List imageBytes = await File(image.path).readAsBytes();
      final fileName = image.name.isNotEmpty ? image.name : 'photo.jpg';

      // Set as pending attachment — user can add context before sending
      _inputBarKey.currentState?.setPendingAttachment(
        PendingAttachment(
          type: AttachmentType.image,
          fileName: fileName,
          sizeBytes: imageBytes.length,
          imageBytes: imageBytes,
          imagePath: image.path,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Couldn\'t load image: ${e.toString()}'),
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
      _handleUserMessage(summary);

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
      _handleUserMessage(summary);

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

  void _handleAttachPressed() async {
    HapticUtils.light();

    final fileService = FileAnalysisService();

    // Pick file
    final file = await fileService.pickFile();
    if (file == null) return;

    // Validate
    final error = fileService.validateFile(file);
    if (error != null) {
      if (!mounted) return;
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.rose500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
        ),
      );
      return;
    }

    // Set as pending attachment — user can add a message before sending
    _inputBarKey.currentState?.setPendingAttachment(
      PendingAttachment(
        type: AttachmentType.file,
        fileName: file.name,
        sizeBytes: file.size,
        platformFile: file,
      ),
    );
  }

  /// Handle send with an attachment (file or image) + optional user message.
  Future<void> _handleSendWithAttachment(String message, PendingAttachment attachment) async {
    if (attachment.type == AttachmentType.image) {
      await _handleSendImageAttachment(message, attachment);
    } else {
      await _handleSendFileAttachment(message, attachment);
    }
  }

  Future<void> _handleSendImageAttachment(String message, PendingAttachment attachment) async {
    final imageBytes = attachment.imageBytes;
    if (imageBytes == null) return;

    // Show user message
    final displayText = message.isNotEmpty
        ? '📷 ${attachment.fileName}\n$message'
        : '📷 ${attachment.fileName}';

    setState(() {
      _messages.add(ChatMessage(
        text: displayText,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isProcessing = true;
    });
    _startThinkingText(const [
      'Scanning receipt',
      'Reading text and prices',
      'Extracting items',
      'Identifying merchant',
      'Processing details',
      'Almost done',
    ]);
    _scrollToBottom();

    try {
      final receiptAgent = ReceiptAgent();
      final receiptData = await receiptAgent.extractFromReceipt(
        imageBytes: imageBytes,
      );

      _stopThinkingText();
      setState(() => _isProcessing = false);

      if (!mounted) return;
      _processConfirmedReceipt(receiptData);
    } catch (e) {
      _stopThinkingText();
      setState(() => _isProcessing = false);

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

  Future<void> _handleSendFileAttachment(String message, PendingAttachment attachment) async {
    final file = attachment.platformFile;
    if (file == null) return;

    // Show user message with file info
    final sizeMB = (file.size / (1024 * 1024)).toStringAsFixed(1);
    final displayText = message.isNotEmpty
        ? '📎 ${file.name} ($sizeMB MB)\n$message'
        : '📎 ${file.name} ($sizeMB MB)';

    setState(() {
      _messages.add(ChatMessage(
        text: displayText,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isProcessing = true;
    });
    _startThinkingText(const [
      'Reading your file',
      'Extracting financial data',
      'Analyzing transactions',
      'Identifying patterns',
      'Summarizing findings',
      'Preparing results',
    ]);
    _scrollToBottom();

    // Analyze
    final fileService = FileAnalysisService();
    final result = await fileService.analyzeFile(file);

    _stopThinkingText();
    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (result.success && result.summary != null) {
      HapticUtils.success();
      await _streamBotResponse(
        result.summary!,
        actions: [
          QuickAction(label: 'View Insights', action: 'navigate_insights', icon: 'trendUp'),
          QuickAction(label: 'Check Budget', action: 'navigate_budget', icon: 'chartPieSlice'),
        ],
      );
    } else {
      HapticUtils.error();
      setState(() {
        _messages.add(ChatMessage(
          text: result.errorMessage ?? 'Could not analyze the file. Please try a different file.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  Future<void> _initializeCopilot() async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Fire-and-forget: run memory aggregation if >24h since last run
    _memoryService.runAggregationIfNeeded(user.uid);

    // Create chat session — await so _currentSessionId is set before any message
    try {
      _currentSessionId = await _chatHistoryService.createSession(user.uid);
      _sessionTitleSet = false;
    } catch (e) {
      debugPrint('⚠️ Chat session creation failed: $e');
    }

    try {
      final richContext = await _buildUserContext();
      _cachedRichContext = richContext;
      final userContext = richContext.toMap();
      final greeting = await _orchestrator.getGreeting(
        userName: user.displayName ?? 'there',
        userContext: userContext,
        richContext: richContext,
      );

      if (!mounted) return;
      final greetingText = greeting['greeting'] as String? ?? 'Hey there! How can I help you today?';
      final quickActions = (greeting['quickActions'] as List?)
              ?.map((e) => QuickAction.fromMap(e as Map<String, dynamic>))
              .toList();
      setState(() {
        _messages.add(ChatMessage(
          text: greetingText,
          isUser: false,
          timestamp: DateTime.now(),
          quickActions: quickActions,
        ));
        _isInitialized = true;
      });
      // Persist the greeting so it appears in chat history
      _persistMessage(text: greetingText, isUser: false, quickActions: quickActions);
    } catch (e) {
      debugPrint('⚠️ Copilot init error: $e');
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: 'Hey there! How can I help you today?',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isInitialized = true;
      });
    }

    _scrollToBottom();
  }

  /// Build rich user context via UserContextBuilder (cached, parallel Firestore reads).
  Future<UserContext> _buildUserContext() async {
    final user = _authService.currentUser;
    if (user == null) {
      return const UserContext(userId: '');
    }
    return _contextBuilder.build(user.uid);
  }

  /// Fire-and-forget helper to persist a message to Firestore.
  void _persistMessage({required String text, required bool isUser, List<QuickAction>? quickActions}) {
    final uid = _authService.currentUser?.uid;
    final sid = _currentSessionId;
    if (uid == null || sid == null) {
      debugPrint('⚠️ _persistMessage skipped: uid=$uid, sessionId=$sid');
      return;
    }

    final msg = ChatSessionMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
      quickActions: quickActions?.map((a) => {'label': a.label, 'icon': a.icon, 'action': a.action, 'data': a.data}).toList(),
    );
    _chatHistoryService.saveMessage(uid, sid, msg).catchError((e) {
      debugPrint('⚠️ _persistMessage failed: $e');
    });
  }

  /// Handle messages when the device is offline.
  void _handleOfflineMessage(String message) {
    if (message.trim().isEmpty) return;

    HapticUtils.light();

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    // Respond with a graceful offline message
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: 'I\'m currently offline and can\'t process AI requests right now.\n\n'
              'You can still **add transactions manually** using the form — '
              'they\'ll sync automatically when you\'re back online.\n\n'
              'I\'ll be ready to chat as soon as your connection is restored! 🌐',
          isUser: false,
          timestamp: DateTime.now(),
          quickActions: [
            QuickAction(label: 'Add Manually', action: 'add_transaction', icon: 'plus'),
          ],
        ));
      });
      _scrollToBottom();
    });
  }

  Future<void> _handleUserMessage(String message) async {
    if (message.trim().isEmpty) return;

    HapticUtils.light();
    final stopwatch = Stopwatch()..start();

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isProcessing = true;
    });

    _messageController.clear();
    _startThinkingText(_guessPhrases(message));
    _startLiveTimer();
    _scrollToBottom();

    // Persist user message & auto-title the session
    _persistMessage(text: message, isUser: true);
    if (!_sessionTitleSet) {
      _sessionTitleSet = true;
      final uid = _authService.currentUser?.uid;
      final sid = _currentSessionId;
      if (uid != null && sid != null) {
        _chatHistoryService.updateSessionTitle(uid, sid, message);
      }
    }

    try {
      final richContext = await _buildUserContext();
      final tContext = stopwatch.elapsedMilliseconds;
      debugPrint('⏱️ Screen: buildUserContext=${tContext}ms');
      final userContext = richContext.toMap();
      final uid = _authService.currentUser?.uid ?? '';
      final response = await _orchestrator.processUserMessage(
        message: message,
        userId: uid,
        userContext: userContext,
        richContext: richContext,
        onThought: (thought) {
          if (mounted && thought.isNotEmpty) {
            // Replace static thinking phrases with real model reasoning
            _thinkingTimer?.cancel();
            setState(() => _thinkingText = thought);
          }
        },
      );
      stopwatch.stop();
      debugPrint('⏱️ Screen: orchestrator=${stopwatch.elapsedMilliseconds}ms (includes context: ${stopwatch.elapsedMilliseconds}ms total)');
      await _handleOrchestratorResponse(response, responseTimeMs: stopwatch.elapsedMilliseconds);
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint('⚠️ Message handling error: $e');
      debugPrint('$stackTrace');
      final errorDetail = kDebugMode ? '\n\n🔧 Debug: $e' : '';
      setState(() {
        _messages.add(ChatMessage(
          text: 'Something went wrong. Please try again.$errorDetail',
          isUser: false,
          timestamp: DateTime.now(),
          responseTimeMs: stopwatch.elapsedMilliseconds,
        ));
      });
    } finally {
      _stopThinkingText();
      _stopLiveTimer();
      setState(() => _isProcessing = false);
      _scrollToBottom();
    }
  }

  // ── Thinking text helpers ──
  List<String> _guessPhrases(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('budget') || lower.contains('spending limit')) {
      return _budgetPhrases;
    }
    if (lower.contains('price') || lower.contains('cost') || lower.contains('compare') || lower.contains('find')) {
      return _pricePhrases;
    }
    if (lower.contains('insight') || lower.contains('pattern') || lower.contains('report') || lower.contains('analytics')) {
      return _insightPhrases;
    }
    if (lower.contains('tip') || lower.contains('advice') || lower.contains('suggest') || lower.contains('help')) {
      return _advicePhrases;
    }
    if (RegExp(r'\$?\d+').hasMatch(lower) || lower.contains('spent') || lower.contains('bought') || lower.contains('paid')) {
      return _transactionPhrases;
    }
    return _defaultPhrases;
  }

  void _startThinkingText(List<String> phrases) {
    _thinkingTimer?.cancel();
    _thinkingPhaseIndex = 0;
    _thinkingPhrases = phrases;
    setState(() => _thinkingText = phrases.first);

    _thinkingTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      _thinkingPhaseIndex = (_thinkingPhaseIndex + 1) % _thinkingPhrases.length;
      setState(() => _thinkingText = _thinkingPhrases[_thinkingPhaseIndex]);
    });
  }

  void _stopThinkingText() {
    _thinkingTimer?.cancel();
    _thinkingTimer = null;
  }

  // ── Live timer helpers ──

  void _startLiveTimer() {
    _liveStopwatch.reset();
    _liveStopwatch.start();
    _liveElapsedMs = 0;
    _liveTimerTick = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _liveElapsedMs = _liveStopwatch.elapsedMilliseconds);
    });
  }

  void _stopLiveTimer() {
    _liveStopwatch.stop();
    _liveTimerTick?.cancel();
    _liveTimerTick = null;
  }

  /// Stream response text word-by-word like ChatGPT / Gemini.
  Future<void> _streamBotResponse(String fullText, {List<QuickAction>? actions, int? responseTimeMs}) async {
    // Stop thinking indicator & live timer — real content is arriving
    _stopThinkingText();
    _stopLiveTimer();
    setState(() => _isProcessing = false);

    final words = fullText.split(RegExp(r'(?<=\s)'));
    final messageIndex = _messages.length;

    setState(() {
      _messages.add(ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isStreaming = true;
    });
    _scrollToBottom();

    final buffer = StringBuffer();
    for (int i = 0; i < words.length; i++) {
      if (!mounted) break;
      buffer.write(words[i]);

      setState(() {
        _messages[messageIndex] = ChatMessage(
          text: buffer.toString(),
          isUser: false,
          timestamp: DateTime.now(),
        );
      });

      // Scroll as text grows
      if (i % 5 == 0) _scrollToBottom();

      // Variable speed — pause longer on sentence endings
      final word = words[i].trimRight();
      int delayMs = 28;
      if (word.endsWith('.') || word.endsWith('!') || word.endsWith('?')) {
        delayMs = 90;
      } else if (word.endsWith(',') || word.endsWith(':') || word.endsWith(';')) {
        delayMs = 55;
      } else if (word.endsWith('\n')) {
        delayMs = 70;
      }
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    // Final update with full text + quick actions
    if (mounted) {
      setState(() {
        _messages[messageIndex] = ChatMessage(
          text: fullText,
          isUser: false,
          timestamp: DateTime.now(),
          quickActions: actions,
          responseTimeMs: responseTimeMs,
        );
        _isStreaming = false;
      });
      _scrollToBottom();
      // Persist bot response
      _persistMessage(text: fullText, isUser: false, quickActions: actions);
    }
  }

  Future<void> _handleOrchestratorResponse(Map<String, dynamic> response, {int? responseTimeMs}) async {
    final type = response['type'];
    final data = response['data'] as Map<String, dynamic>?;

    if (data == null) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I couldn\'t process that. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      return;
    }

    String responseText;
    List<QuickAction>? actions;

    switch (type) {
      case 'add_transaction':
        responseText = (data['confirm_message'] as String?) ?? _buildTransactionResponse(data);
        actions = [
          QuickAction(label: 'Confirm', action: 'confirm_transaction', data: data, icon: 'check'),
          QuickAction(label: 'Edit', action: 'edit_transaction', data: data, icon: 'pencilSimple'),
        ];
        break;

      case 'financial_advice':
        responseText = data['response'] ?? data['answer'] ?? 'Here\'s my advice...';
        if (data['tip'] != null) {
          responseText += '\n\nTip: ${data['tip']}';
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
          QuickAction(label: 'Search Prices', action: 'navigate_price_intelligence', icon: 'magnifyingGlass'),
        ];
        break;

      case 'budget_analysis':
        responseText = data['response'] ?? 'Here\'s your budget analysis...';
        if (data['suggestion'] != null) {
          responseText += '\n\n${data['suggestion']}';
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
        if (data['response'] != null) {
          responseText = data['response'];
        } else {
          final insights = data['insights'] as List?;
          if (insights != null && insights.isNotEmpty) {
            responseText = 'Here are your key insights:\n\n';
            for (int i = 0; i < insights.length; i++) {
              responseText += '${i + 1}. ${insights[i]}\n';
            }
          } else {
            responseText = 'Start tracking expenses to see personalized insights.';
          }
        }
        if (data['action'] != null) {
          final action = data['action'] as Map<String, dynamic>;
          actions = [
            QuickAction(
              label: action['label'] ?? 'View Full Insights',
              action: action['type'] ?? 'navigate_insights',
              icon: 'trendUp',
            ),
          ];
        } else {
          actions = [
            QuickAction(label: 'View Full Insights', action: 'navigate_insights', icon: 'trendUp'),
          ];
        }
        break;

      case 'generate_report':
        responseText = data['response'] ?? 'I can generate a report for you.';
        actions = [
          QuickAction(label: 'Open Reports', action: 'navigate_reports', icon: 'fileText'),
        ];
        break;

      case 'error':
        responseText = data['response'] ?? 'Something went wrong. Please try again.';
        break;

      case 'general_conversation':
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
        break;

      default:
        responseText = data['response'] ?? 'I\'m here to help!';
    }

    await _streamBotResponse(responseText, actions: actions, responseTimeMs: responseTimeMs);
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
    if (amount != null) response += 'Amount: \$${amount}\n';
    if (merchant != null) response += 'Merchant: $merchant\n';
    if (category != null) response += 'Category: $category\n';
    if (description != null) response += 'Description: $description\n';
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

  String _formatResponseTime(int ms) {
    if (ms < 1000) return '${ms}ms';
    final seconds = ms / 1000;
    return '${seconds.toStringAsFixed(1)}s';
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
        tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      );

      await _firestore.collection('transactions').add(transaction.toFirestore());

      // Update memory (fire-and-forget)
      _memoryService.updateFromTransaction(transaction);

      // Update budget spending
      await _transactionService.updateBudgetSpendingPublic(
        userId: user.uid,
        category: transaction.category,
        amount: transaction.amount,
        transactionDate: transaction.transactionDate,
      );

      if (mounted) {
        // Check for nudge (fire-and-forget display)
        _nudgeService.checkForNudge(transaction).then((nudge) {
          if (nudge != null && mounted) {
            setState(() {
              _messages.add(ChatMessage(
                text: nudge,
                isUser: false,
                timestamp: DateTime.now(),
              ));
            });
            _scrollToBottom();
          }
        });

        setState(() {
          _messages.add(ChatMessage(
            text: 'Transaction saved successfully! Your ${data['category']} expense of ${CurrencyUtils.formatAmount(transaction.amount, transaction.currency)} has been recorded.',
            isUser: false,
            timestamp: DateTime.now(),
            quickActions: [
              QuickAction(label: 'View Insights', action: 'navigate_insights', icon: 'trendUp'),
              QuickAction(label: 'Check Budget', action: 'navigate_budget', icon: 'chartPieSlice'),
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
            text: 'Sorry, I couldn\'t save the transaction. Error: $e',
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(DesignTokens.radiusXL),
              topRight: Radius.circular(DesignTokens.radiusXL),
            ),
          ),
          padding: const EdgeInsets.all(DesignTokens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.space16),
              Text('Edit Transaction',
                  style: context.textTheme.titleLarge),
              const SizedBox(height: DesignTokens.space20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText:
                      '${CurrencyUtils.getCurrencySymbol(PreferencesService.getCurrency() ?? 'USD')} ',
                ),
              ),
              const SizedBox(height: DesignTokens.space12),
              TextField(
                controller: merchantController,
                decoration:
                    const InputDecoration(labelText: 'Merchant'),
              ),
              const SizedBox(height: DesignTokens.space12),
              TextField(
                controller: descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: DesignTokens.space24),
              Row(
                children: [
                  Expanded(
                    child: PremiumButton(
                      variant: PremiumButtonVariant.secondary,
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space12),
                  Expanded(
                    child: PremiumButton(
                      onPressed: () {
                        final updatedData = {
                          ...data,
                          'amount': double.tryParse(
                                  amountController.text) ??
                              data['amount'],
                          'merchant': merchantController.text,
                          'description': descriptionController.text,
                        };
                        Navigator.pop(ctx);
                        _handleQuickAction(QuickAction(
                          label: 'Confirm',
                          action: 'confirm_transaction',
                          data: updatedData,
                        ));
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        context.pushWithSlideUp(const BudgetScreen());
        break;

      case 'navigate_insights':
        context.pushWithFade(const InsightsScreen());
        break;

      case 'navigate_reports':
        context.pushWithFade(const ReportsScreen());
        break;

      case 'navigate_price_intelligence':
        context.pushWithFade(const PriceIntelligenceScreen());
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

  /// Load a previous chat session from the drawer.
  Future<void> _loadSession(ChatSession session) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    _scaffoldKey.currentState?.closeDrawer();

    setState(() {
      _messages.clear();
      _currentSessionId = session.id;
      _sessionTitleSet = true;
      _isInitialized = false;
    });

    final docs = await _chatHistoryService.getSessionMessages(uid, session.id);
    final loaded = docs.map((m) => ChatMessage(
      text: m.text,
      isUser: m.isUser,
      timestamp: m.timestamp,
      quickActions: m.quickActions
          ?.map((a) => QuickAction.fromMap(Map<String, dynamic>.from(a)))
          .toList(),
    )).toList();

    setState(() {
      _messages.addAll(loaded);
      _isInitialized = true;
    });
    _scrollToBottom();
  }

  /// Start a brand-new chat session from the drawer.
  Future<void> _startNewChat() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    _scaffoldKey.currentState?.closeDrawer();

    setState(() {
      _messages.clear();
      _isInitialized = false;
      _sessionTitleSet = false;
    });

    // Create session in background
    try {
      final id = await _chatHistoryService.createSession(uid);
      _currentSessionId = id;
    } catch (e) {
      debugPrint('⚠️ New session creation failed: $e');
    }

    try {
      final richContext = await _buildUserContext();
      _cachedRichContext = richContext;
      final userContext = richContext.toMap();
      final greeting = await _orchestrator.getGreeting(
        userName: _authService.currentUser?.displayName ?? 'there',
        userContext: userContext,
        richContext: richContext,
      );

      if (!mounted) return;
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
    } catch (e) {
      debugPrint('⚠️ New chat init error: $e');
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: 'Hey there! How can I help you today?',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isInitialized = true;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid ?? '';
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      drawer: ChatHistoryDrawer(
        userId: userId,
        currentSessionId: _currentSessionId,
        historyService: _chatHistoryService,
        maxSessions: _cachedRichContext != null
            ? PremiumGateService.maxChatSessions(_cachedRichContext!)
            : 7,
        onSessionSelected: _loadSession,
        onNewChat: _startNewChat,
      ),
      body: Stack(
        children: [
          Column(
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
                        child: Icon(PhosphorIcons.arrowLeft(),
                            size: DesignTokens.iconMD),
                      ),
                      const SizedBox(width: DesignTokens.space12),
                      // AI avatar
                      ClipOval(
                        child: Image.asset(
                          'assets/images/fincopilot_app_icon.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.space8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fin Copilot',
                                style: context.textTheme.titleMedium),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: _isOffline
                                        ? AppTheme.slate400
                                        : AppTheme.accentEmerald,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isOffline
                                      ? 'Offline'
                                      : _isProcessing
                                          ? 'Thinking…'
                                          : 'Online',
                                  style:
                                      context.textTheme.labelSmall?.copyWith(
                                    color: context.colors.onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticUtils.light();
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        child: Icon(
                          PhosphorIcons.clockCounterClockwise(),
                          size: DesignTokens.iconMD,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Offline banner ──
              if (_isOffline)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space16,
                    vertical: DesignTokens.space8,
                  ),
                  color: context.isDark
                      ? Colors.amber.withOpacity(0.12)
                      : Colors.amber.shade50,
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.wifiSlash(),
                          size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: DesignTokens.space8),
                      Expanded(
                        child: Text(
                          'You\'re offline — transactions added manually will sync when reconnected',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Messages ──
              Expanded(
                child: !_isInitialized
                    ? const ChatListSkeleton()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          DesignTokens.space16,
                          DesignTokens.space8,
                          DesignTokens.space16,
                          DesignTokens.space16,
                        ),
                        itemCount:
                            _messages.length + (_isProcessing ? 1 : 0) + (_messages.length == 1 ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isProcessing) {
                            return _buildTypingIndicator();
                          }
                          // "Prefer forms?" link after initial greeting only
                          if (index == _messages.length && _messages.length == 1 && !_isProcessing) {
                            return _buildManualEntryLink();
                          }
                          return _buildMessageBubble(
                              _messages[index], index);
                        },
                      ),
              ),

              // ── Input bar ──
              MessageInputBar(
                key: _inputBarKey,
                onSendMessage: _isOffline ? _handleOfflineMessage : _handleUserMessage,
                onSendWithAttachment: _handleSendWithAttachment,
                onCameraPressed: _handleCameraPressed,
                onAttachPressed: _handleAttachPressed,
                enabled: !_isProcessing && !_isStreaming,
                hintText: _isOffline
                    ? 'Offline — use Add Manually for transactions'
                    : 'Ask about your finances…',
              ),
            ],
          ),

          // ── Scroll-to-bottom FAB ──
          if (_showScrollToBottom && _isInitialized)
            Positioned(
              right: DesignTokens.space16,
              bottom: 100,
              child: GestureDetector(
                onTap: _scrollToBottom,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        context.colors.surface.withOpacity(0.85),
                    border: Border.all(
                      color:
                          context.colors.onSurface.withOpacity(0.08),
                    ),
                  ),
                  child: Icon(PhosphorIcons.caretDown(),
                      size: DesignTokens.iconSM),
                )
                    .animate()
                    .fadeIn(duration: DesignTokens.durationFast)
                    .scaleXY(begin: 0.8, end: 1.0),
              ),
            ),
        ],
      ),
    );
  }

  // ── Message bubble ──
  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.isUser;

    Widget bubble = Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                ClipOval(
                  child: Image.asset(
                    'assets/images/fincopilot_app_icon.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: DesignTokens.space8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(DesignTokens.space16),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.primaryIndigo
                        : context.isDark
                            ? Colors.white.withOpacity(0.06)
                            : AppTheme.slate100,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusLG)
                            .copyWith(
                      topLeft: isUser
                          ? null
                          : const Radius.circular(
                              DesignTokens.radiusXS),
                      topRight: isUser
                          ? const Radius.circular(
                              DesignTokens.radiusXS)
                          : null,
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: context.colors.onSurface
                                .withOpacity(0.06),
                          ),
                  ),
                  child: isUser
                      ? Text(
                          message.text,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            height: 1.5,
                          ),
                        )
                      : MarkdownText(
                          data: message.text,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colors.onSurface,
                            height: 1.5,
                          ),
                        ),
                ),
              ),
              if (isUser) const SizedBox(width: DesignTokens.space8),
            ],
          ),

          // Quick actions
          if (message.quickActions != null &&
              message.quickActions!.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Wrap(
                spacing: DesignTokens.space8,
                runSpacing: DesignTokens.space8,
                children: message.quickActions!
                    .map((a) => _buildQuickActionChip(a))
                    .toList(),
              ),
            ),
          ],

          // Response time badge (dev/test)
          if (!isUser && message.responseTimeMs != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.timer(),
                    size: 12,
                    color: context.colors.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatResponseTime(message.responseTimeMs!),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.3),
                      fontSize: 10,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    // Stagger only the first 10
    if (index < 10) {
      bubble = bubble
          .animate()
          .fadeIn(
            duration: DesignTokens.durationFast,
            delay: Duration(
                milliseconds: DesignTokens.staggerDelay.inMilliseconds *
                    (index % 4)),
          )
          .slideY(
            begin: 0.08,
            end: 0,
            duration: DesignTokens.durationNormal,
            curve: DesignTokens.curveDecelerate,
          );
    }

    return bubble;
  }

  // ── "Prefer forms? Add manually" link ──
  Widget _buildManualEntryLink() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 44, // align with bot messages (avatar + gap)
        bottom: DesignTokens.space16,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ManualTransactionScreen(),
            ),
          );
        },
        child: Text.rich(
          TextSpan(
            text: 'Prefer forms? ',
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.onSurface.withOpacity(0.5),
            ),
            children: [
              TextSpan(
                text: 'Add manually',
                style: TextStyle(
                  color: AppTheme.primaryIndigo,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(QuickAction action) {
    return GestureDetector(
      onTap: () => _handleQuickAction(action),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space12,
          vertical: DesignTokens.space8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryIndigo.withOpacity(0.08),
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          border: Border.all(
            color: AppTheme.primaryIndigo.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getQuickActionIcon(action.icon),
                size: 14, color: AppTheme.primaryIndigo),
            const SizedBox(width: DesignTokens.space6),
            Text(
              action.label,
              style: context.textTheme.labelMedium?.copyWith(
                color: AppTheme.primaryIndigo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getQuickActionIcon(String? icon) {
    switch (icon) {
      case 'plus':
        return PhosphorIcons.plus();
      case 'lightbulb':
        return PhosphorIcons.lightbulb();
      case 'chartPieSlice':
        return PhosphorIcons.chartPieSlice();
      case 'trendUp':
        return PhosphorIcons.trendUp();
      case 'magnifyingGlass':
        return PhosphorIcons.magnifyingGlass();
      case 'fileText':
        return PhosphorIcons.fileText();
      case 'check':
        return PhosphorIcons.check();
      case 'pencilSimple':
        return PhosphorIcons.pencilSimple();
      case 'shoppingCart':
        return PhosphorIcons.shoppingCart();
      case 'arrowRight':
        return PhosphorIcons.arrowRight();
      default:
        return PhosphorIcons.caretRight();
    }
  }

  // ── Typing indicator ──
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/fincopilot_app_icon.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: DesignTokens.space8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space20,
                  vertical: DesignTokens.space16,
                ),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? Colors.white.withOpacity(0.06)
                      : AppTheme.slate100,
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusLG).copyWith(
                    topLeft:
                        const Radius.circular(DesignTokens.radiusXS),
                  ),
                  border: Border.all(
                    color: context.colors.onSurface.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 180,
                      child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _thinkingText,
                        key: ValueKey(_thinkingText),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryIndigo.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ...List.generate(
                      3,
                      (i) => Padding(
                        padding:
                            EdgeInsets.only(right: i < 2 ? 4.0 : 0),
                        child: _AnimatedDot(delay: i * 200),
                      ),
                    ),
                  ],
                ),
              ),
              // Live timer counter
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.timer(),
                      size: 12,
                      color: context.colors.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatResponseTime(_liveElapsedMs),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colors.onSurface.withOpacity(0.3),
                        fontSize: 10,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: DesignTokens.durationFast).slideY(
          begin: 0.1,
          end: 0,
          duration: DesignTokens.durationNormal,
        );
  }
}

// ── Animated typing dot ──
class _AnimatedDot extends StatefulWidget {
  final int delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Opacity(
        opacity: _scale.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primaryIndigo,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Local models ──
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<QuickAction>? quickActions;
  final int? responseTimeMs;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickActions,
    this.responseTimeMs,
  });
}

class QuickAction {
  final String label;
  final String action;
  final Map<String, dynamic>? data;
  final String? icon;

  QuickAction({
    required this.label,
    required this.action,
    this.data,
    this.icon,
  });

  factory QuickAction.fromMap(Map<String, dynamic> map) {
    return QuickAction(
      label: map['label'] as String,
      action: map['action'] as String,
      data: map['data'] as Map<String, dynamic>?,
      icon: map['phosphorIcon'] as String?,
    );
  }
}

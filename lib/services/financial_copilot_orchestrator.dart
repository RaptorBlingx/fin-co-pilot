import 'package:firebase_ai/firebase_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_context.dart';
import 'context_formatter.dart';
import 'function_declarations.dart';
import 'premium_gate_service.dart';
import 'price_intelligence_agent.dart';
import 'proactive_coach_agent.dart';

/// Financial Copilot Orchestrator
/// Uses Gemini function calling to let the model decide which action to take,
/// replacing the manual intent classification + switch-case routing.
class FinancialCopilotOrchestrator {
  static final FinancialCopilotOrchestrator _instance =
      FinancialCopilotOrchestrator._internal();
  factory FinancialCopilotOrchestrator() => _instance;
  FinancialCopilotOrchestrator._internal();

  final _firestore = FirebaseFirestore.instance;

  /// Creates a model with system instruction AND function calling tools.
  GenerativeModel _buildModel(UserContext? ctx) {
    final systemText = ctx != null
        ? '''You are Fin Copilot, a warm and knowledgeable AI personal finance assistant.

${ContextFormatter.formatForSystemInstruction(ctx)}

${ContextFormatter.formatCoreRules(ctx)}

TOOL USAGE:
- When the user mentions spending, buying, paying, or earning → call save_transaction
- When asked about budget status, remaining budget → call get_budget_status
- When asked about spending patterns, trends, insights, or reports → call get_spending_summary
- When asked to find prices, compare costs, or search for deals → call search_prices
- When the user wants to set a savings goal or spending target → call set_financial_goal
- When the user asks for financial advice, tips, or coaching → call get_coaching_tip
- For greetings, general chat, or questions → respond directly with text, no function call'''
        : 'You are Fin Copilot, a warm and knowledgeable AI personal finance assistant.';

    // Pro subscribers get the more powerful model for richer reasoning
    final modelName = (ctx != null && PremiumGateService.deepAnalysisModel(ctx) != null)
        ? PremiumGateService.deepAnalysisModel(ctx)!
        : 'gemini-3-flash-preview';

    return FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction: Content.text(systemText),
      tools: [CopilotFunctions.tool],
      generationConfig: GenerationConfig(
        thinkingConfig: ThinkingConfig.withThinkingLevel(
          ThinkingLevel.minimal,
          includeThoughts: true,
        ),
      ),
    );
  }

  /// Process a user message using function calling.
  /// The model decides which tool to invoke (or responds directly).
  ///
  /// [onThought] is called with real-time thought summaries from the model's
  /// chain-of-thought reasoning (if the model emits them during streaming).
  Future<Map<String, dynamic>> processUserMessage({
    required String message,
    required String userId,
    required Map<String, dynamic> userContext,
    UserContext? richContext,
    void Function(String thoughtSummary)? onThought,
  }) async {
    try {
      final sw = Stopwatch()..start();

      final model = _buildModel(richContext);
      final t1 = sw.elapsedMilliseconds;

      // Use chat interface — SDK automatically handles thought signatures
      final chat = model.startChat();
      final t2 = sw.elapsedMilliseconds;

      // Step 1: Send user message — model decides action via function calling
      final response = await chat.sendMessage(Content.text(message));
      final t3 = sw.elapsedMilliseconds;
      final calls = response.functionCalls.toList();

      if (kDebugMode) {
        print('⏱️ Orchestrator timing: buildModel=${t1}ms, startChat=${t2 - t1}ms, sendMessage=${t3 - t2}ms (total=${t3}ms)');
      }

      // Emit initial thought summary if available
      if (response.thoughtSummary != null) {
        onThought?.call(response.thoughtSummary!);
      }

      if (calls.isEmpty) {
        // No function call — pure text response (general conversation)
        final text = response.text?.trim() ?? '';
        if (kDebugMode) {
          print('Orchestrator: text response (no function call)');
          if (response.thoughtSummary != null) {
            print('Thought summary: ${response.thoughtSummary}');
          }
        }
        return {
          'type': 'general_conversation',
          'data': {
            'response': text.isNotEmpty
                ? text
                : 'I\'m here to help with your finances!',
            'action': null,
            if (response.thoughtSummary != null)
              'thoughtSummary': response.thoughtSummary,
          },
        };
      }

      // Step 2: Model requested a function call
      final call = calls.first;
      if (kDebugMode) {
        print('Orchestrator: function call → ${call.name}(${call.args})');
      }

      // save_transaction is special — return data immediately for UI confirmation
      // No second API call needed; avoids ~30s+ wasted latency
      if (call.name == CopilotFunctions.saveTransaction) {
        return _handleSaveTransaction(call);
      }

      // All other functions: execute → return result to model → get text
      final result =
          await _executeFunction(call, userId, richContext);
      final t4 = sw.elapsedMilliseconds;

      // Stream follow-up to capture thought summaries progressively
      String responseText = '';
      String? thoughtSummary;
      await for (final chunk in chat.sendMessageStream(
        Content.functionResponse(call.name, result),
      )) {
        if (chunk.thoughtSummary != null) {
          thoughtSummary = chunk.thoughtSummary;
          onThought?.call(chunk.thoughtSummary!);
        }
        if (chunk.text != null) {
          responseText += chunk.text!;
        }
      }
      responseText = responseText.trim();
      final t5 = sw.elapsedMilliseconds;

      if (kDebugMode) {
        print('⏱️ Orchestrator: executeFunc=${t4 - t3}ms, streamFollowUp=${t5 - t4}ms (total=${t5}ms)');
      }

      final resp = _buildResponse(call.name, responseText);
      if (thoughtSummary != null) {
        (resp['data'] as Map<String, dynamic>)['thoughtSummary'] =
            thoughtSummary;
      }
      return resp;
    } catch (e) {
      if (kDebugMode) {
        print('Error in orchestrator: $e');
      }
      return {
        'type': 'error',
        'error': e.toString(),
        'data': {
          'response':
              'I apologize, but I encountered an issue. Could you please rephrase your request?',
        },
      };
    }
  }

  /// Handle save_transaction: extract data from function args for UI confirmation.
  /// No second API call needed — we extract data from the function call args
  /// and return immediately for the user to confirm/edit.
  Map<String, dynamic> _handleSaveTransaction(FunctionCall call) {
    final args = call.args;
    // Ensure amount is always a double (Gemini may return int)
    final rawAmount = args['amount'];
    final amount = (rawAmount is num) ? rawAmount.toDouble() : 0.0;

    return {
      'type': 'add_transaction',
      'data': <String, dynamic>{
        'amount': amount,
        'merchant': args['merchant'],
        'category': args['category'],
        'description': args['item'] ?? args['description'],
        'payment_method': args['payment_method'],
        'tags': args['tags'],
        'confidence': 0.95,
      },
    };
  }

  /// Execute a function call and return the result map for FunctionResponse.
  Future<Map<String, Object?>> _executeFunction(
    FunctionCall call,
    String userId,
    UserContext? ctx,
  ) async {
    switch (call.name) {
      case CopilotFunctions.getBudgetStatus:
        return _executeBudgetStatus(ctx, call.args);
      case CopilotFunctions.getSpendingSummary:
        return _executeSpendingSummary(ctx, call.args);
      case CopilotFunctions.searchPrices:
        return _executeSearchPrices(call.args, ctx);
      case CopilotFunctions.setFinancialGoal:
        return _executeSetGoal(userId, call.args);
      case CopilotFunctions.getCoachingTip:
        return _executeCoachingTip(userId, ctx);
      default:
        return {'error': 'Unknown function: ${call.name}'};
    }
  }

  /// Build the response map based on the function that was called.
  Map<String, dynamic> _buildResponse(String functionName, String text) {
    final responseText =
        text.isNotEmpty ? text : 'I\'m here to help with your finances!';
    switch (functionName) {
      case CopilotFunctions.getBudgetStatus:
        return {
          'type': 'budget_analysis',
          'data': {
            'response': responseText,
            'action': {
              'label': 'View Budget Details',
              'type': 'navigate_budget',
            },
          },
        };
      case CopilotFunctions.getSpendingSummary:
        return {
          'type': 'spending_insights',
          'data': {
            'response': responseText,
            'action': {
              'label': 'View Full Insights',
              'type': 'navigate_insights',
            },
          },
        };
      case CopilotFunctions.searchPrices:
        return {
          'type': 'price_comparison',
          'data': {
            'response': responseText,
            'action': {
              'label': 'Search Prices',
              'type': 'navigate_price_intelligence',
            },
          },
        };
      case CopilotFunctions.setFinancialGoal:
        return {
          'type': 'general_conversation',
          'data': {'response': responseText, 'action': null},
        };
      case CopilotFunctions.getCoachingTip:
        return {
          'type': 'financial_advice',
          'data': {
            'response': responseText,
            'action': null,
          },
        };
      default:
        return {
          'type': 'general_conversation',
          'data': {'response': responseText, 'action': null},
        };
    }
  }

  // ── Function executors ──

  Map<String, Object?> _executeBudgetStatus(
      UserContext? ctx, Map<String, Object?> args) {
    if (ctx == null || !ctx.hasBudget) {
      return {
        'has_budget': false,
        'message': 'No budget has been set up yet.',
      };
    }
    final catFilter = args['category'] as String?;
    return {
      'has_budget': true,
      'budget_amount': ctx.budgetAmount,
      'budget_spent': ctx.budgetSpent,
      'budget_remaining': (ctx.budgetAmount ?? 0) - (ctx.budgetSpent ?? 0),
      'utilization_percent':
          ((ctx.budgetUtilization ?? 0) * 100).toStringAsFixed(1),
      'days_remaining': ctx.budgetDaysRemaining,
      'currency': ctx.primaryCurrency,
      if (catFilter != null) 'category_filter': catFilter,
      'top_categories': ctx.topCategories
          .map((c) => {'name': c.name, 'amount': c.amount, 'count': c.txCount})
          .toList(),
    };
  }

  Map<String, Object?> _executeSpendingSummary(
      UserContext? ctx, Map<String, Object?> args) {
    if (ctx == null) {
      return {'message': 'No spending data available yet.'};
    }
    return {
      'period': args['period'] ?? 'this_month',
      'total_spent': ctx.monthTotal,
      'last_month_total': ctx.lastMonthTotal,
      'month_over_month_change': '${ctx.monthDelta.toStringAsFixed(1)}%',
      'currency': ctx.primaryCurrency,
      'top_categories': ctx.topCategories
          .map((c) => {'name': c.name, 'amount': c.amount, 'count': c.txCount})
          .toList(),
      'recent_merchants': ctx.recentMerchants,
    };
  }

  Future<Map<String, Object?>> _executeSearchPrices(
      Map<String, Object?> args, UserContext? ctx) async {
    final product = args['product'] as String? ?? '';
    if (product.isEmpty) {
      return {'error': 'No product specified for price search.'};
    }
    try {
      final agent = PriceIntelligenceAgent();
      if (ctx != null) agent.updateContext(ctx);
      final results = await agent.searchBestPrice(
        productQuery: product,
        userCountry: ctx?.country ?? 'US',
        userLanguage: ctx?.primaryLanguage ?? 'en',
        userCurrency: ctx?.primaryCurrency ?? 'USD',
      );
      return {
        'product': product,
        'results': results
            .map((r) => {
                  'merchant': r.merchant,
                  'price': r.price,
                  'currency': r.currency,
                  'availability': r.availability,
                  'url': r.url,
                  'notes': r.notes,
                })
            .toList(),
        'result_count': results.length,
      };
    } catch (e) {
      return {'product': product, 'error': 'Price search failed: $e'};
    }
  }

  Future<Map<String, Object?>> _executeSetGoal(
      String userId, Map<String, Object?> args) async {
    final name = args['name'] as String? ?? 'My Goal';
    final targetAmount = args['target_amount'] as num? ?? 0;
    final deadline = args['deadline'] as String?;
    try {
      final goalRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('financial_goals')
          .doc();
      await goalRef.set({
        'name': name,
        'target_amount': targetAmount,
        'current_amount': 0,
        'deadline': deadline,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'active',
      });
      return {
        'status': 'created',
        'goal_name': name,
        'target_amount': targetAmount,
        'deadline': deadline,
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Could not create goal: $e'};
    }
  }

  Future<Map<String, Object?>> _executeCoachingTip(
      String userId, UserContext? ctx) async {
    try {
      final agent = ProactiveCoachAgent();
      if (ctx != null) agent.updateContext(ctx);
      final tips = await agent.generateWeeklyCoaching(userId: userId);
      if (tips.isNotEmpty) {
        final tip = tips.first;
        return {
          'tip_title': tip.title,
          'tip_message': tip.message,
          'tip_type': tip.type,
          'tip_priority': tip.priority,
          'actionable': tip.actionable,
        };
      }
      return {'message': 'Keep up the good work! No new tips at this time.'};
    } catch (e) {
      return {
        'message': 'Here\'s a general tip: review your spending weekly '
            'to spot patterns and find saving opportunities.',
      };
    }
  }

  /// Get personalized greeting for user
  Future<Map<String, dynamic>> getGreeting({
    required String userName,
    required Map<String, dynamic> userContext,
    UserContext? richContext,
  }) async {
    final timeOfDay = richContext?.timeOfDay != null
        ? _timeOfDayGreeting(richContext!.timeOfDay)
        : _getTimeOfDay();
    final firstName = userName.split(' ').first;

    // Analyze user context for personalized greeting
    final hasTransactions = ((userContext['transactionCount'] as int?) ?? 0) > 0;
    final hasBudget = (userContext['hasBudget'] as bool?) ?? false;

    String greeting;
    List<Map<String, String>> quickActions;

    if (!hasTransactions) {
      greeting = '$timeOfDay, $firstName!\n\nI\'m your Financial Copilot. Let\'s start tracking your expenses and building better financial habits together.';
      quickActions = [
        {'label': 'Add Expense', 'action': 'add_transaction', 'icon': 'add_circle', 'phosphorIcon': 'plus'},
        {'label': 'Get Tips', 'action': 'financial_advice', 'icon': 'lightbulb', 'phosphorIcon': 'lightbulb'},
        {'label': 'Set Budget', 'action': 'navigate_budget', 'icon': 'account_balance_wallet', 'phosphorIcon': 'chartPieSlice'},
      ];
    } else if (!hasBudget) {
      greeting = '$timeOfDay, $firstName!\n\nYou\'re tracking expenses nicely! Ready to set budgets and get deeper insights?';
      quickActions = [
        {'label': 'Set Budget', 'action': 'navigate_budget', 'icon': 'account_balance_wallet', 'phosphorIcon': 'chartPieSlice'},
        {'label': 'Add Expense', 'action': 'add_transaction', 'icon': 'add_circle', 'phosphorIcon': 'plus'},
        {'label': 'View Insights', 'action': 'navigate_insights', 'icon': 'insights', 'phosphorIcon': 'trendUp'},
        {'label': 'Find Prices', 'action': 'price_comparison', 'icon': 'search', 'phosphorIcon': 'magnifyingGlass'},
      ];
    } else {
      greeting = '$timeOfDay, $firstName!\n\nWhat can I help you with today?';
      quickActions = [
        {'label': 'Add Expense', 'action': 'add_transaction', 'icon': 'add_circle', 'phosphorIcon': 'plus'},
        {'label': 'Budget Status', 'action': 'budget_analysis', 'icon': 'pie_chart', 'phosphorIcon': 'chartPieSlice'},
        {'label': 'Insights', 'action': 'navigate_insights', 'icon': 'trending_up', 'phosphorIcon': 'trendUp'},
        {'label': 'Price Finder', 'action': 'price_comparison', 'icon': 'shopping_cart', 'phosphorIcon': 'shoppingCart'},
        {'label': 'Get Advice', 'action': 'financial_advice', 'icon': 'psychology', 'phosphorIcon': 'lightbulb'},
        {'label': 'Reports', 'action': 'navigate_reports', 'icon': 'description', 'phosphorIcon': 'fileText'},
      ];
    }

    return {
      'greeting': greeting,
      'quickActions': quickActions,
      'userName': firstName,
      'timeOfDay': timeOfDay,
    };
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _timeOfDayGreeting(String tod) {
    switch (tod) {
      case 'morning':
        return 'Good morning';
      case 'afternoon':
        return 'Good afternoon';
      case 'evening':
        return 'Good evening';
      case 'night':
        return 'Good evening';
      default:
        return 'Hello';
    }
  }
}

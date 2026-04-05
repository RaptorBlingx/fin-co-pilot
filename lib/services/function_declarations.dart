import 'package:firebase_ai/firebase_ai.dart';

/// Central function declarations for Gemini function calling.
/// The model uses these to decide which action to take based on user intent,
/// replacing the manual intent classification system.
class CopilotFunctions {
  CopilotFunctions._();

  // ── Function names (constants for matching) ──

  static const saveTransaction = 'save_transaction';
  static const getBudgetStatus = 'get_budget_status';
  static const getSpendingSummary = 'get_spending_summary';
  static const searchPrices = 'search_prices';
  static const setFinancialGoal = 'set_financial_goal';
  static const getCoachingTip = 'get_coaching_tip';

  /// All function declarations for the copilot orchestrator.
  static List<FunctionDeclaration> get declarations => [
        _saveTransaction,
        _getBudgetStatus,
        _getSpendingSummary,
        _searchPrices,
        _setFinancialGoal,
        _getCoachingTip,
      ];

  /// The Tool object to pass to generativeModel.
  static Tool get tool => Tool.functionDeclarations(declarations);

  // ── Individual declarations ──

  static final _saveTransaction = FunctionDeclaration(
    saveTransaction,
    'Save a new expense or income transaction. Call this when the user '
        'mentions spending money, buying something, paying for something, '
        'or receiving income.',
    parameters: {
      'amount': Schema.number(
        description: 'The monetary amount of the transaction.',
      ),
      'item': Schema.string(
        description: 'What was purchased or the income source.',
      ),
      'category': Schema.enumString(
        description: 'The spending category.',
        enumValues: [
          'groceries',
          'dining',
          'transport',
          'entertainment',
          'shopping',
          'health',
          'bills',
          'education',
          'travel',
          'coffee',
          'subscriptions',
          'income',
          'other',
        ],
      ),
      'merchant': Schema.string(
        description: 'The store or merchant name, if mentioned.',
      ),
      'description': Schema.string(
        description: 'A brief description of the transaction.',
      ),
      'payment_method': Schema.enumString(
        description: 'How the user paid.',
        enumValues: [
          'cash',
          'credit_card',
          'debit_card',
          'bank_transfer',
          'digital_wallet',
        ],
      ),
      'tags': Schema.array(
        description:
            'Contextual tags: time (morning, evening), social (solo, friends), '
            'location (home, work), emotional (treat, impulse), recurring (daily, weekly).',
        items: Schema.string(),
      ),
    },
    optionalParameters: [
      'merchant',
      'description',
      'payment_method',
      'tags',
    ],
  );

  static final _getBudgetStatus = FunctionDeclaration(
    getBudgetStatus,
    'Get the user\'s current budget status including spending limits, '
        'remaining amounts, and category breakdowns. Call this when the user '
        'asks about their budget, spending limits, or how much they have left.',
    parameters: {
      'category': Schema.string(
        description:
            'Optional specific category to check. Leave empty for overall budget.',
        nullable: true,
      ),
    },
    optionalParameters: ['category'],
  );

  static final _getSpendingSummary = FunctionDeclaration(
    getSpendingSummary,
    'Get a summary of the user\'s spending over a time period, including '
        'totals, category breakdowns, and trends. Call this when the user asks '
        'about spending patterns, analytics, insights, or wants a report.',
    parameters: {
      'period': Schema.enumString(
        description: 'The time period for the summary.',
        enumValues: ['today', 'this_week', 'this_month', 'last_month'],
      ),
    },
    optionalParameters: ['period'],
  );

  static final _searchPrices = FunctionDeclaration(
    searchPrices,
    'Search for the best prices for a product across different stores. '
        'Call this when the user wants to compare prices, find deals, or '
        'asks how much something costs at different retailers.',
    parameters: {
      'product': Schema.string(
        description: 'The product to search prices for.',
      ),
    },
  );

  static final _setFinancialGoal = FunctionDeclaration(
    setFinancialGoal,
    'Create or update a financial goal for the user. Call this when the '
        'user wants to save for something, set a spending target, or '
        'create a financial milestone.',
    parameters: {
      'name': Schema.string(
        description: 'Name of the financial goal.',
      ),
      'target_amount': Schema.number(
        description: 'The target amount to save or limit.',
      ),
      'deadline': Schema.string(
        description: 'Target date in YYYY-MM-DD format.',
        nullable: true,
      ),
    },
    optionalParameters: ['deadline'],
  );

  static final _getCoachingTip = FunctionDeclaration(
    getCoachingTip,
    'Get a personalized financial coaching tip based on the user\'s '
        'spending patterns and behavior. Call this when the user asks for '
        'advice, tips, suggestions, or help improving their finances.',
    parameters: {
      'focus_area': Schema.string(
        description:
            'Optional area to focus the tip on, e.g. "saving", "dining", "groceries".',
        nullable: true,
      ),
    },
    optionalParameters: ['focus_area'],
  );
}

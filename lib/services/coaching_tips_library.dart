/// Expanded coaching tips library with comprehensive tips across multiple categories
/// 
/// Provides 25+ unique actionable tips organized by spending category:
/// - Groceries (4 tips)
/// - Dining (4 tips)
/// - Transport (4 tips)
/// - Entertainment (4 tips)
/// - Shopping (4 tips)
/// - General (5 tips)
/// - Budget alerts (dynamic)
/// - Trend analysis (dynamic)
class CoachingTipsLibrary {
  /// Get tips for a specific category with spending data context
  static List<Map<String, dynamic>> getTipsForCategory(
    String category,
    Map<String, dynamic> spendingData,
  ) {
    switch (category.toLowerCase()) {
      case 'groceries':
      case 'grocery':
        return _getGroceryTips(spendingData);
      case 'dining':
      case 'food':
      case 'restaurant':
        return _getDiningTips(spendingData);
      case 'transport':
      case 'transportation':
        return _getTransportTips(spendingData);
      case 'entertainment':
        return _getEntertainmentTips(spendingData);
      case 'shopping':
        return _getShoppingTips(spendingData);
      default:
        return _getGeneralTips(spendingData);
    }
  }

  /// Get grocery shopping tips
  static List<Map<String, dynamic>> _getGroceryTips(Map<String, dynamic> data) {
    return [
      {
        'title': 'Shop with a list',
        'message':
            'Create a shopping list before heading to the store. Studies show this reduces impulse purchases by 23%.',
        'priority': 'medium',
        'actionable': true,
      },
      {
        'title': 'Buy store brands',
        'message':
            'Store brands are typically 30-40% cheaper than name brands with similar quality.',
        'priority': 'medium',
        'actionable': true,
      },
      {
        'title': 'Check unit prices',
        'message':
            'Compare price per ounce or pound, not just total price. Larger sizes usually offer better value.',
        'priority': 'low',
        'actionable': true,
      },
      {
        'title': 'Shop seasonal produce',
        'message':
            'Seasonal fruits and vegetables are fresher and up to 50% cheaper.',
        'priority': 'low',
        'actionable': true,
      },
    ];
  }

  /// Get dining and restaurant tips
  static List<Map<String, dynamic>> _getDiningTips(Map<String, dynamic> data) {
    return [
      {
        'title': 'Cook at home more',
        'message':
            'Cooking at home is 5x cheaper than dining out. Even 2-3 home meals per week saves \$200+/month.',
        'priority': 'high',
        'actionable': true,
      },
      {
        'title': 'Try meal prep',
        'message':
            'Prep meals on Sunday for the week. Saves time and reduces takeout temptation.',
        'priority': 'medium',
        'actionable': true,
      },
      {
        'title': 'Use lunch specials',
        'message':
            'Lunch menus are often 30-50% cheaper than dinner for the same restaurants.',
        'priority': 'low',
        'actionable': true,
      },
      {
        'title': 'Skip the drinks',
        'message':
            'Beverages at restaurants have huge markups. Water or drinks from home save \$5-10 per meal.',
        'priority': 'low',
        'actionable': true,
      },
    ];
  }

  /// Get transportation tips
  static List<Map<String, dynamic>> _getTransportTips(Map<String, dynamic> data) {
    return [
      {
        'title': 'Track gas prices',
        'message':
            'Use apps like GasBuddy to find cheapest gas nearby. Can save \$0.20+/gallon.',
        'priority': 'medium',
        'actionable': true,
      },
      {
        'title': 'Maintain your car',
        'message':
            'Regular maintenance prevents costly repairs. Simple oil changes extend engine life by years.',
        'priority': 'high',
        'actionable': true,
      },
      {
        'title': 'Carpool or rideshare',
        'message':
            'Sharing rides cuts commute costs in half and reduces wear on your vehicle.',
        'priority': 'medium',
        'actionable': true,
      },
      {
        'title': 'Consider public transit',
        'message':
            'Public transportation can save \$300-500/month vs owning a car in cities.',
        'priority': 'low',
        'actionable': true,
      },
    ];
  }

  /// Get entertainment tips
  static List<Map<String, dynamic>> _getEntertainmentTips(
      Map<String, dynamic> data) {
    return [
      {
        'title': 'Review subscriptions',
        'message':
            'Cancel unused streaming services. Most people forget about 3-4 auto-renewing subscriptions.',
        'priority': 'high',
        'actionable': true,
      },
      {
        'title': 'Use free community events',
        'message':
            'Libraries, parks, and community centers offer free movies, concerts, and activities.',
        'priority': 'low',
        'actionable': true,
      },
      {
        'title': 'Split streaming accounts',
        'message':
            'Family plans for Spotify, Netflix, etc. cost \$5-8/person vs \$15+ individual.',
        'priority': 'medium',
        'actionable': true,
      },
      {
        'title': 'Matinee movie prices',
        'message':
            'Weekend morning shows are 40-50% cheaper than evening showings.',
        'priority': 'low',
        'actionable': true,
      },
    ];
  }

  /// Get shopping tips
  static List<Map<String, dynamic>> _getShoppingTips(Map<String, dynamic> data) {
    return [
      {
        'title': 'Wait 24 hours',
        'message':
            'For non-essential purchases, wait a day. 70% of impulse buys are avoided this way.',
        'priority': 'high',
        'actionable': true,
      },
      {
        'title': 'Use price tracking',
        'message':
            'Tools like CamelCamelCamel track Amazon price history. Buy when prices drop.',
        'priority': 'medium',
        'actionable': true,
      },
      {
        'title': 'Buy secondhand first',
        'message':
            'Check Facebook Marketplace, OfferUp, or thrift stores before buying new.',
        'priority': 'medium',
        'actionable': true,
      },
      {
        'title': 'Use cashback apps',
        'message':
            'Rakuten, Honey, and credit card rewards give 1-5% back on purchases.',
        'priority': 'low',
        'actionable': true,
      },
    ];
  }

  /// Get general financial tips
  static List<Map<String, dynamic>> _getGeneralTips(Map<String, dynamic> data) {
    return [
      {
        'title': 'Build an emergency fund',
        'message':
            'Start with \$500, then work toward 3-6 months of expenses. This prevents debt during emergencies.',
        'priority': 'high',
        'actionable': true,
      },
      {
        'title': 'Automate savings',
        'message':
            'Set up automatic transfers to savings on payday. "Pay yourself first" before spending.',
        'priority': 'high',
        'actionable': true,
      },
      {
        'title': 'Track every expense',
        'message':
            'People who track spending save 15-20% more than those who don\'t.',
        'priority': 'medium',
        'actionable': true,
      },
      {
        'title': 'Review monthly',
        'message':
            'Spend 15 minutes each month reviewing spending. Identify areas to cut and celebrate progress.',
        'priority': 'medium',
        'actionable': true,
      },
      {
        'title': 'Use the 50/30/20 rule',
        'message':
            '50% needs, 30% wants, 20% savings. Simple framework for balanced spending.',
        'priority': 'low',
        'actionable': true,
      },
    ];
  }

  /// Get budget-related tips based on spending percentage
  static List<Map<String, dynamic>> getBudgetTips(double spentPercent) {
    if (spentPercent > 100) {
      return [
        {
          'title': 'Budget exceeded',
          'message':
              'You\'re ${(spentPercent - 100).toStringAsFixed(0)}% over budget. Review discretionary spending and adjust.',
          'priority': 'critical',
          'actionable': true,
        },
      ];
    } else if (spentPercent > 90) {
      return [
        {
          'title': 'Approaching budget limit',
          'message':
              'You\'ve used ${spentPercent.toStringAsFixed(0)}% of your budget. Be mindful of remaining spending.',
          'priority': 'high',
          'actionable': true,
        },
      ];
    } else if (spentPercent < 50) {
      return [
        {
          'title': 'Great job!',
          'message':
              'You\'re at ${spentPercent.toStringAsFixed(0)}% of budget. Consider increasing savings goals.',
          'priority': 'low',
          'actionable': false,
        },
      ];
    }
    return [];
  }

  /// Get trend-based tips from spending changes
  static List<Map<String, dynamic>> getTrendTips(double changePercent) {
    if (changePercent > 20) {
      return [
        {
          'title': 'Spending increased',
          'message':
              'Spending is up ${changePercent.toStringAsFixed(0)}% vs last period. Review recent purchases.',
          'priority': 'medium',
          'actionable': true,
        },
      ];
    } else if (changePercent < -20) {
      return [
        {
          'title': 'Excellent progress',
          'message':
              'Spending decreased ${changePercent.abs().toStringAsFixed(0)}%. Keep up the good work!',
          'priority': 'low',
          'actionable': false,
        },
      ];
    }
    return [];
  }

  /// Get all available tip categories
  static List<String> getAvailableCategories() {
    return [
      'groceries',
      'dining',
      'transport',
      'entertainment',
      'shopping',
      'general',
    ];
  }

  /// Get total count of unique tips
  static int getTotalTipCount() {
    int count = 0;
    count += _getGroceryTips({}).length; // 4
    count += _getDiningTips({}).length; // 4
    count += _getTransportTips({}).length; // 4
    count += _getEntertainmentTips({}).length; // 4
    count += _getShoppingTips({}).length; // 4
    count += _getGeneralTips({}).length; // 5
    // Total: 25 base tips + dynamic budget/trend tips
    return count;
  }
}

/// Comprehensive coaching tips library for Week 9
///
/// Pre-populated library of 100+ coaching tips organized by category:
/// - Budgeting (20 tips)
/// - Impulse Control (20 tips)
/// - Savings (20 tips)
/// - Debt Management (20 tips)
/// - Stress/Emotional Spending (20 tips)
///
/// Each tip includes:
/// - Category
/// - Trigger condition
/// - Short actionable advice
/// - Long-form explanation
/// - Relevant tags

class CoachingTipsSeedData {
  /// Get all 100+ coaching tips ready for Firestore seeding
  static List<Map<String, dynamic>> getAllTips() {
    return [
      ..._budgetingTips,
      ..._impulseControlTips,
      ..._savingsTips,
      ..._debtManagementTips,
      ..._stressEmotionalTips,
    ];
  }

  // =================================================================
  // BUDGETING TIPS (20)
  // =================================================================
  static final List<Map<String, dynamic>> _budgetingTips = [
    {
      'category': 'budgeting',
      'trigger': 'over_budget',
      'tip': 'You\'re 10% over your budget. Review your top 3 spending categories and see where you can cut back this week.',
      'longForm': 'Going over budget is common, especially when starting out. The key is to identify which categories are causing the overspend. Look at your top 3 spending categories and ask: "Were these purchases necessary?" Often, cutting back 20% in just one category can bring you back on track.',
      'tags': ['budgeting', 'overspending', 'adjustment'],
    },
    {
      'category': 'budgeting',
      'trigger': 'budget_streak',
      'tip': 'Congrats! You\'ve stayed under budget for 3 weeks straight. Keep this momentum going!',
      'longForm': 'Consistency is the secret to financial success. By staying under budget for 3 weeks, you\'ve proven you can control your spending. This creates positive momentum that compounds over time. Celebrate this win and use it as motivation to maintain these habits.',
      'tags': ['budgeting', 'achievement', 'motivation'],
    },
    {
      'category': 'budgeting',
      'trigger': 'new_month',
      'tip': 'Set your monthly budget within the first 3 days of the month. People who do this save 23% more.',
      'longForm': 'Research shows that setting a budget early in the month dramatically improves adherence. Take 15 minutes today to review last month\'s spending and set realistic targets for each category. The earlier you plan, the better your chances of success.',
      'tags': ['budgeting', 'planning', 'monthly'],
    },
    {
      'category': 'budgeting',
      'trigger': 'no_budget',
      'tip': 'You don\'t have an active budget. Start with the 50/30/20 rule: 50% needs, 30% wants, 20% savings.',
      'longForm': 'The 50/30/20 rule is a simple framework: allocate 50% of income to needs (rent, groceries, utilities), 30% to wants (dining out, entertainment), and 20% to savings and debt repayment. This balanced approach works for most people and is easy to maintain.',
      'tags': ['budgeting', 'getting_started', '50-30-20'],
    },
    {
      'category': 'budgeting',
      'trigger': 'approaching_limit',
      'tip': 'You\'re at 90% of your dining budget. Consider cooking at home for the rest of the week.',
      'longForm': 'Hitting 90% of your budget mid-month is a warning sign. Cooking at home costs 5x less than dining out. Try meal prepping on Sunday - it takes 2 hours but saves you both money and decision fatigue during the week.',
      'tags': ['budgeting', 'dining', 'warning'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Track every purchase for one week. Awareness alone reduces spending by 15%.',
      'longForm': 'The simple act of tracking creates awareness, which naturally leads to better decisions. For one week, log every single purchase - no matter how small. You\'ll be surprised at where your money really goes, and this awareness will help you make better choices.',
      'tags': ['budgeting', 'tracking', 'awareness'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Use the envelope method for categories you overspend in. Allocate cash weekly.',
      'longForm': 'The envelope method works because cash is tangible. Withdraw your budget in cash and divide it into envelopes by category (groceries, entertainment, etc.). Once an envelope is empty, you\'re done spending in that category. This physical limit prevents overspending.',
      'tags': ['budgeting', 'cash', 'envelope_method'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Review your budget every Sunday evening. Make adjustments based on the week ahead.',
      'longForm': 'Weekly reviews keep your budget relevant. Every Sunday, look at the week ahead: any birthdays? Travel? Special events? Adjust your budget categories accordingly. This proactive approach prevents surprises and keeps you in control.',
      'tags': ['budgeting', 'weekly_review', 'planning'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Set separate budgets for weekdays vs. weekends. Weekends tend to have 40% more discretionary spending.',
      'longForm': 'Weekends are spending danger zones. Set a specific weekend budget for dining, entertainment, and shopping. Knowing you have \$100 for the weekend helps you pace yourself and avoid the "Sunday regret" of overspending.',
      'tags': ['budgeting', 'weekends', 'discretionary'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Include a "fun money" category in your budget. Deprivation leads to budget burnout.',
      'longForm': 'Budgets fail when they feel too restrictive. Allocate 5-10% of your income to guilt-free "fun money" for whatever you want. This prevents the feeling of deprivation that leads to breaking your budget entirely.',
      'tags': ['budgeting', 'fun_money', 'balance'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Use zero-based budgeting: every dollar gets assigned a job. This reduces mindless spending by 30%.',
      'longForm': 'With zero-based budgeting, your income minus expenses equals zero. Every dollar is allocated to a category (needs, wants, savings, debt) before the month begins. This intentionality eliminates "leftover" money that tends to disappear.',
      'tags': ['budgeting', 'zero-based', 'intentional'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Build in a 10% buffer for unexpected expenses. Life happens, and buffers prevent budget failures.',
      'longForm': 'Perfect budgets don\'t exist. Always include a 10% buffer for unexpected costs: car repairs, medical copays, forgotten birthdays. This buffer absorbs surprises without derailing your entire budget.',
      'tags': ['budgeting', 'buffer', 'flexibility'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Budget in annual expenses monthly. Divide yearly costs (insurance, subscriptions) by 12 and save monthly.',
      'longForm': 'Annual expenses create budget shock. Avoid this by dividing them by 12 and saving that amount monthly. \$1,200 car insurance = \$100/month. This way, when the bill arrives, the money is already there.',
      'tags': ['budgeting', 'annual_expenses', 'planning'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Use budgeting apps to automate tracking. Manual tracking fails 80% of the time after 3 months.',
      'longForm': 'Manual budgeting is exhausting. Apps like Fin Copilot automate transaction categorization and send alerts when you\'re approaching limits. This automation removes friction and dramatically improves long-term success.',
      'tags': ['budgeting', 'automation', 'apps'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Set budget "rules" not restrictions. Example: "I can eat out, but only at lunch when prices are 40% cheaper."',
      'longForm': 'Rules feel empowering; restrictions feel limiting. Instead of "no eating out," try "only lunch specials" or "one nice dinner per week." This maintains enjoyment while controlling costs.',
      'tags': ['budgeting', 'rules', 'flexibility'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Round up your budget categories. Budget \$550 for groceries if you spend \$500. Use leftovers as bonus savings.',
      'longForm': 'Rounding up creates automatic savings. If groceries typically cost \$500, budget \$550. The \$50 buffer prevents overspending, and any leftover becomes extra savings. This trick accumulates \$500+ per year.',
      'tags': ['budgeting', 'rounding', 'savings'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Use the "one in, one out" rule for shopping categories. Buy new clothes? Donate or sell something old.',
      'longForm': 'This rule controls clutter and spending. Before buying new clothes, shoes, or gadgets, commit to removing one old item. This forces you to evaluate if you really need it and keeps possessions (and spending) in check.',
      'tags': ['budgeting', 'shopping', 'minimalism'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Set up automatic transfers to savings on payday. "Pay yourself first" before budgeting anything else.',
      'longForm': 'The #1 savings strategy is automation. On payday, automatically transfer 10-20% to savings before you budget the rest. You can\'t spend what you don\'t see, and this guarantees you\'re saving every month.',
      'tags': ['budgeting', 'savings', 'automation'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Use the "24-hour rule" for purchases over \$50. Wait a day before buying to avoid impulse regret.',
      'longForm': 'Impulse purchases over \$50 often become regrets. Implement a mandatory 24-hour waiting period. Add the item to a wishlist and revisit tomorrow. 60% of the time, the urge passes, saving you hundreds annually.',
      'tags': ['budgeting', 'impulse', '24-hour-rule'],
    },
    {
      'category': 'budgeting',
      'trigger': 'general',
      'tip': 'Share budget goals with an accountability partner. People with partners are 65% more likely to hit targets.',
      'longForm': 'Accountability transforms intentions into action. Share your monthly budget goal with a friend, partner, or family member. Check in weekly. This external accountability dramatically increases your success rate.',
      'tags': ['budgeting', 'accountability', 'partnership'],
    },
  ];

  // =================================================================
  // IMPULSE CONTROL TIPS (20)
  // =================================================================
  static final List<Map<String, dynamic>> _impulseControlTips = [
    {
      'category': 'impulse',
      'trigger': 'impulse_spending',
      'tip': 'You\'ve made 3 unplanned purchases today. Take a 10-minute walk before the next one.',
      'longForm': 'Multiple impulse purchases in a day signal emotional spending. A 10-minute walk interrupts the pattern and activates rational decision-making. Physical movement reduces stress and curbs the urge to spend.',
      'tags': ['impulse', 'awareness', 'pause'],
    },
    {
      'category': 'impulse',
      'trigger': 'large_purchase',
      'tip': 'Before buying anything over \$100, calculate how many hours of work it costs.',
      'longForm': 'Translate purchases into work hours. If you earn \$25/hour, that \$200 jacket costs 8 hours of work. This perspective shift makes you think twice about whether it\'s really worth your time.',
      'tags': ['impulse', 'large_purchase', 'perspective'],
    },
    {
      'category': 'impulse',
      'trigger': 'frequent_small_spends',
      'tip': '\$5 purchases add up. Your "small" purchases this week total \$87. Batch them into one planned outing.',
      'longForm': 'Small purchases feel harmless but accumulate fast. That daily \$5 coffee = \$1,825/year. Try batching: instead of 6 small purchases, plan one \$30 outing. You\'ll enjoy it more and spend less overall.',
      'tags': ['impulse', 'small_purchases', 'awareness'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Delete saved credit cards from shopping apps. Adding friction reduces impulse buying by 40%.',
      'longForm': 'One-click buying removes the natural pause that prevents impulse purchases. Delete saved payment methods from Amazon, Uber Eats, and other apps. The extra 30 seconds to enter your card gives you time to reconsider.',
      'tags': ['impulse', 'friction', 'apps'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Unsubscribe from marketing emails. Every promotional email increases impulse spending by 7%.',
      'longForm': 'Marketing emails are designed to trigger FOMO and create urgency. Unsubscribe from retail emails for 30 days and watch your impulse spending drop. You can always resubscribe if you miss them.',
      'tags': ['impulse', 'marketing', 'email'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Use the "cost per use" calculation. A \$200 jacket worn 50 times = \$4/wear. Worth it?',
      'longForm': 'Justify purchases by cost per use, not sticker price. A \$200 jacket you wear weekly for a year (\$4/wear) is better value than a \$50 jacket worn twice (\$25/wear). This reframes value.',
      'tags': ['impulse', 'cost_per_use', 'value'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Create a "wishlist" for impulse items. 70% of wishlist items lose appeal after 30 days.',
      'longForm': 'Capture impulse urges on a wishlist instead of buying immediately. Revisit monthly. Most items will no longer seem essential, proving the impulse was temporary. For items that remain, you\'ll buy more intentionally.',
      'tags': ['impulse', 'wishlist', 'delay'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Shop with cash only for impulse categories. Spending physical money activates more self-control.',
      'longForm': 'Credit cards feel painless; cash feels real. For categories where you impulse spend (shopping, dining), use cash. The physical act of handing over bills creates emotional friction that reduces overspending.',
      'tags': ['impulse', 'cash', 'psychology'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Avoid shopping when hungry, tired, or stressed. These states increase impulse buying by 35%.',
      'longForm': 'Your mental state affects spending. Hunger, fatigue, and stress reduce self-control and increase impulsive decisions. Never shop for non-essentials when you\'re in these states. Eat, rest, or destress first.',
      'tags': ['impulse', 'emotional', 'awareness'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Use the "joy test": Will this purchase bring joy in 3 months? If no, skip it.',
      'longForm': 'Impulse purchases bring immediate pleasure but often fade quickly. Before buying, visualize owning it in 3 months. Will it still bring joy, or will it be forgotten clutter? This future-focused test filters out regrettable purchases.',
      'tags': ['impulse', 'joy', 'future_thinking'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Set a monthly "impulse budget" of \$50. Once it\'s gone, you wait until next month.',
      'longForm': 'You can\'t eliminate impulse spending entirely, so budget for it. Allocate \$50/month for guilt-free impulse buys. Track it separately. This satisfies the urge while maintaining control.',
      'tags': ['impulse', 'budget', 'control'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Use browser extensions to block shopping sites during work hours.',
      'longForm': 'Online shopping during work hours is a major impulse trap. Install extensions like Freedom or Cold Turkey to block retail sites during work. This eliminates distraction and prevents boredom-driven purchases.',
      'tags': ['impulse', 'productivity', 'blocking'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Take a "no-spend day" once per week. Zero non-essential purchases for 24 hours.',
      'longForm': 'No-spend days reset your spending habits and prove you don\'t need constant purchases to be happy. Choose one day per week (often best mid-week) and commit to zero non-essential spending. It\'s surprisingly liberating.',
      'tags': ['impulse', 'no-spend', 'reset'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Ask "Do I need this, or does marketing want me to think I need this?"',
      'longForm': 'Marketing creates artificial needs. Before buying, pause and ask: "Is this genuinely useful, or am I being influenced by ads, influencers, or FOMO?" This question reveals whether the desire is authentic or manufactured.',
      'tags': ['impulse', 'marketing', 'awareness'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Try the "replacement rule": Can I use something I already own instead?',
      'longForm': 'We often buy duplicates of things we already have. Before purchasing, check if you already own something similar. That new blender might be unnecessary if your current one works fine.',
      'tags': ['impulse', 'minimalism', 'duplication'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Recognize emotional triggers. Do you shop when lonely, bored, anxious, or celebrating?',
      'longForm': 'Impulse spending is often emotional regulation. Track when you impulse spend and identify the emotion behind it. Lonely? Call a friend. Bored? Take a walk. Finding alternative coping mechanisms stops the cycle.',
      'tags': ['impulse', 'emotional', 'triggers'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Use the "10-minute rule": Wait 10 minutes before any unplanned purchase under \$50.',
      'longForm': 'Small impulse buys don\'t warrant the 24-hour rule, but 10 minutes of delay is enough to engage rational thinking. Set a phone timer and browse elsewhere. Often, the urge passes.',
      'tags': ['impulse', 'delay', 'small_purchases'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Limit "window shopping" - online or in-store. Browsing without intention leads to purchases.',
      'longForm': 'Aimless browsing creates wants that didn\'t exist. Shop with a specific list and purpose. Avoid browsing "just for fun" - it\'s rarely fun when you end up with buyer\'s remorse.',
      'tags': ['impulse', 'browsing', 'intention'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Use cash-back rewards intentionally: reinvest them in savings, not as "free" spending money.',
      'longForm': 'Cash-back rewards feel like "found money" and trigger impulse spending. Treat them as bonus savings instead. Set up automatic transfers of rewards to your savings account.',
      'tags': ['impulse', 'rewards', 'savings'],
    },
    {
      'category': 'impulse',
      'trigger': 'general',
      'tip': 'Practice gratitude for what you have. Impulse buying often stems from a sense of lack.',
      'longForm': 'Impulse spending can mask underlying dissatisfaction. Start a daily gratitude practice: list 3 things you\'re grateful for. This shifts focus from what\'s missing to what\'s present, reducing the urge to fill voids with purchases.',
      'tags': ['impulse', 'gratitude', 'mindfulness'],
    },
  ];

  // =================================================================
  // SAVINGS TIPS (20)
  // =================================================================
  static final List<Map<String, dynamic>> _savingsTips = [
    {
      'category': 'savings',
      'trigger': 'low_savings',
      'tip': 'Start small: save \$5 per day. In a year, that\'s \$1,825 - enough for an emergency fund.',
      'longForm': 'Saving feels overwhelming when you\'re starting. Focus on \$5/day - the cost of a latte. Automate it if possible. Small consistent actions compound into life-changing results. \$5/day = \$1,825/year.',
      'tags': ['savings', 'small_steps', 'automation'],
    },
    {
      'category': 'savings',
      'trigger': 'savings_milestone',
      'tip': 'You just hit \$500 in savings! That\'s a major milestone. Keep building your safety net.',
      'longForm': 'Celebrate this win! \$500 is the first crucial milestone - it covers most minor emergencies. Your next goal: \$1,000 (covers major car/home repairs). Then build to 3-6 months of expenses.',
      'tags': ['savings', 'milestone', 'achievement'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Use the "52-week challenge": Save \$1 week 1, \$2 week 2... \$52 week 52. Total: \$1,378.',
      'longForm': 'This gamified approach makes saving fun. Week 1 save \$1, week 2 save \$2, gradually increasing. By week 52, you\'ll have saved \$1,378 without feeling the pinch. Apps can automate this.',
      'tags': ['savings', 'challenge', 'gamification'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Automate savings on payday. Set up automatic transfers before you have a chance to spend it.',
      'longForm': 'Manual saving fails because willpower depletes. Automate a transfer of 10-20% of every paycheck directly to savings. What you don\'t see, you don\'t spend. This single change transforms your finances.',
      'tags': ['savings', 'automation', 'payday'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Open a high-yield savings account. Earn 4-5% interest instead of 0.01% at traditional banks.',
      'longForm': 'Most bank savings accounts pay nearly nothing. High-yield online savings accounts (Ally, Marcus, etc.) pay 4-5%. On \$5,000, that\'s \$200-250/year in free money just for switching.',
      'tags': ['savings', 'interest', 'high_yield'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Save all windfalls: tax refunds, bonuses, gifts. These are perfect for jumpstarting savings.',
      'longForm': 'Windfalls feel like "extra" money, making them tempting to spend. Commit to saving 100% of unexpected money: tax refunds, work bonuses, birthday gifts. This turbocharges your savings without affecting your budget.',
      'tags': ['savings', 'windfalls', 'bonuses'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Use the "round-up" method: round every purchase to the nearest dollar and save the difference.',
      'longForm': 'Spend \$3.50? Round to \$4 and save \$0.50. Apps like Acorns automate this, turning everyday purchases into micro-savings. These "invisible" savings add up to \$500-1,000/year.',
      'tags': ['savings', 'round_up', 'micro_savings'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Set up separate savings goals: emergency fund, vacation, down payment. Multiple goals increase motivation.',
      'longForm': 'One general savings account feels abstract. Create separate accounts for specific goals: \$1,000 emergency fund, \$3,000 vacation, \$10,000 down payment. Tracking progress toward concrete goals is far more motivating.',
      'tags': ['savings', 'goals', 'motivation'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Try a "no-spend month": commit to only essential purchases for 30 days. Save the rest.',
      'longForm': 'A no-spend month is a financial reset. For 30 days, only spend on true essentials: rent, groceries, gas. No dining out, shopping, or entertainment. This extreme clarity reveals how much you can actually save.',
      'tags': ['savings', 'no-spend', 'challenge'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Visualize your savings goal. Put a picture of it on your phone\'s wallpaper as daily motivation.',
      'longForm': 'Abstract goals fail. Make yours visual: saving for a house? Use a picture of your dream home as your wallpaper. Vacation? Beach photo. This daily visual reminder keeps you motivated when tempted to spend.',
      'tags': ['savings', 'visualization', 'motivation'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Increase savings by 1% every time you get a raise. You won\'t miss it, but your future self will thank you.',
      'longForm': 'Lifestyle inflation kills wealth building. When you get a raise, immediately increase your savings rate by 1%. You\'ll never feel the difference, but over a career, this compounds into hundreds of thousands.',
      'tags': ['savings', 'raises', 'lifestyle_inflation'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Cancel one subscription per month and redirect that money to savings. \$10/month = \$120/year.',
      'longForm': 'Subscriptions are silent savings killers. Pick one per month to cancel - a streaming service you rarely use, a gym membership you ignore. Redirect that \$10-30/month to savings. You won\'t miss it.',
      'tags': ['savings', 'subscriptions', 'recurring'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Save first, spend second. Treat savings like your most important bill - non-negotiable.',
      'longForm': 'Most people save what\'s "left over" at the end of the month (usually nothing). Flip this: treat savings as your first expense. Pay yourself first, then budget the rest. This guarantees you\'re building wealth every month.',
      'tags': ['savings', 'pay_yourself_first', 'priority'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Use cash-back credit cards strategically, then transfer rewards directly to savings.',
      'longForm': 'Cash-back cards can boost savings if used responsibly. Use a 2% cash-back card for regular purchases (pay off monthly!), then immediately transfer rewards to savings. This creates "found money" savings.',
      'tags': ['savings', 'cash_back', 'rewards'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Cook at home 5 nights per week. Average savings: \$200-400/month.',
      'longForm': 'Dining out is one of the biggest budget killers. Cooking at home costs \$3-5 per meal vs. \$15-30 eating out. Commit to cooking 5 nights per week and watch your savings grow by \$200-400/month.',
      'tags': ['savings', 'cooking', 'dining'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Use the "save the difference" trick: when you choose a cheaper option, save the difference.',
      'longForm': 'Making frugal choices feels more rewarding when you see the savings. Buy store brand instead of name brand? Save the \$2 difference. Brew coffee at home instead of Starbucks? Save the \$5. This makes frugality tangible.',
      'tags': ['savings', 'frugality', 'difference'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Build an emergency fund first, then tackle other goals. Financial stability reduces anxiety by 70%.',
      'longForm': 'Emergency funds are the foundation of financial peace. Prioritize saving \$1,000, then 3-6 months of expenses, before aggressive debt payoff or other goals. This buffer eliminates the constant low-level anxiety of "what if?"',
      'tags': ['savings', 'emergency_fund', 'priority'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Use the "wait 30 days" rule for wants. Add to a wishlist; if you still want it in 30 days, buy it.',
      'longForm': 'Immediate gratification drives poor purchases. For any "want" (not need), add it to a wishlist and wait 30 days. Revisit monthly. Most items will lose appeal, and the money stays in savings.',
      'tags': ['savings', 'delayed_gratification', 'wishlist'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'DIY when possible: haircuts at home (\$30/month), car washes (\$20/month), coffee (\$100/month) = \$1,800/year saved.',
      'longForm': 'Small conveniences add up. Learn basic skills: cut your own hair (or your kids\'), wash your car at home, brew coffee. These minor DIY efforts save \$100-200/month without sacrificing quality of life.',
      'tags': ['savings', 'diy', 'convenience'],
    },
    {
      'category': 'savings',
      'trigger': 'general',
      'tip': 'Track your savings rate, not just total saved. Aim for 20% of income - the gold standard.',
      'longForm': 'Total savings can be discouraging early on. Instead, track your savings rate (savings ÷ income). Aim for 10% initially, then 15%, then 20%. This percentage-based approach works at any income level.',
      'tags': ['savings', 'savings_rate', 'percentage'],
    },
  ];

  // =================================================================
  // DEBT MANAGEMENT TIPS (20)
  // =================================================================
  static final List<Map<String, dynamic>> _debtManagementTips = [
    {
      'category': 'debt',
      'trigger': 'high_debt',
      'tip': 'You have \$X in debt. Use the avalanche method: pay off highest interest rate first.',
      'longForm': 'The avalanche method saves the most money on interest. List all debts by interest rate. Make minimum payments on all, then put extra money toward the highest rate. Once that\'s paid, roll that payment to the next highest.',
      'tags': ['debt', 'avalanche', 'strategy'],
    },
    {
      'category': 'debt',
      'trigger': 'high_debt',
      'tip': 'Try the snowball method: pay off smallest debt first for quick psychological wins.',
      'longForm': 'The snowball method prioritizes motivation over math. Pay off your smallest debt first, regardless of interest rate. The quick win builds momentum and keeps you motivated through the longer journey.',
      'tags': ['debt', 'snowball', 'motivation'],
    },
    {
      'category': 'debt',
      'trigger': 'missed_payment',
      'tip': 'You missed a payment. Set up autopay immediately to avoid future late fees and credit damage.',
      'longForm': 'Late payments cost \$25-40 in fees plus damage your credit score. Set up autopay for at least the minimum payment. You can always pay more manually, but autopay ensures you never miss a payment again.',
      'tags': ['debt', 'autopay', 'late_fees'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Stop using credit cards while paying off debt. Switch to debit or cash to avoid adding to the balance.',
      'longForm': 'You can\'t dig out of a hole while still digging. While aggressively paying off credit card debt, stop using the cards entirely. Use debit or cash for purchases. This prevents new debt from accumulating.',
      'tags': ['debt', 'credit_cards', 'spending_freeze'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Negotiate your interest rates. A simple phone call can reduce rates by 2-5%, saving hundreds.',
      'longForm': 'Credit card companies want to keep customers. Call and ask: "I\'m considering a balance transfer to a lower rate card. Can you reduce my rate?" Success rate: 50-70%. Even a 2% reduction saves hundreds annually.',
      'tags': ['debt', 'negotiation', 'interest_rates'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Consider a balance transfer to a 0% APR card. Pay off during the promotional period.',
      'longForm': 'Many cards offer 12-18 months of 0% APR on balance transfers (3-5% fee). If you can pay off the debt during this period, you\'ll save thousands in interest. Just avoid adding new charges.',
      'tags': ['debt', 'balance_transfer', '0_apr'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Make biweekly payments instead of monthly. This creates an extra payment per year, reducing debt faster.',
      'longForm': 'Biweekly payments (half the monthly amount every 2 weeks) result in 26 half-payments = 13 monthly payments per year. This extra payment significantly accelerates debt payoff without feeling burdensome.',
      'tags': ['debt', 'biweekly', 'acceleration'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Apply all windfalls to debt: tax refunds, bonuses, gifts. Every extra dollar shortens your timeline.',
      'longForm': 'Windfalls are debt payoff accelerators. Commit now: 100% of unexpected money (tax refunds, work bonuses, birthday gifts) goes to debt. This can shave months or years off your payoff timeline.',
      'tags': ['debt', 'windfalls', 'acceleration'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Calculate your debt-free date. Knowing you\'ll be debt-free in X months is powerful motivation.',
      'longForm': 'Abstract debt feels endless. Use a calculator to determine your exact debt-free date based on your payment plan. Seeing "Debt-free: March 15, 2026" makes it real and keeps you motivated.',
      'tags': ['debt', 'timeline', 'motivation'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Track net worth monthly, not just debt. Seeing your total financial picture provides perspective.',
      'longForm': 'Focusing only on debt is depressing. Track net worth (assets minus debts) monthly. Even while paying off debt, your net worth improves, providing a more complete and motivating picture.',
      'tags': ['debt', 'net_worth', 'perspective'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Sell unused items to accelerate debt payoff. Declutter and use proceeds for extra payments.',
      'longForm': 'Most homes have \$1,000+ in unused items. Sell on Facebook Marketplace, eBay, or Poshmark. Apply 100% of proceeds to debt. This creates a double win: less clutter, faster debt freedom.',
      'tags': ['debt', 'selling', 'decluttering'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Increase income with a side hustle. Extra \$500/month = \$6,000/year toward debt.',
      'longForm': 'You can only cut expenses so much, but income is unlimited. Start a side hustle: freelancing, Uber, tutoring, dog walking. Even \$500/month directed to debt makes a massive difference.',
      'tags': ['debt', 'side_hustle', 'income'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Avoid consolidation loans unless the interest rate is significantly lower. Read the fine print.',
      'longForm': 'Debt consolidation can help if it genuinely lowers your interest rate by 3%+. But watch for fees, longer terms (which increase total interest), and the temptation to accumulate new debt on freed-up credit cards.',
      'tags': ['debt', 'consolidation', 'caution'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Celebrate milestones: every \$1,000 paid off, every card closed. Positive reinforcement sustains momentum.',
      'longForm': 'Debt payoff is a marathon. Celebrate every milestone: first \$1,000 paid, first card at zero, 50% debt eliminated. Small celebrations (free treat, movie night) provide positive reinforcement.',
      'tags': ['debt', 'milestones', 'celebration'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Use the "debt snowball calculator" to see exactly how extra payments accelerate your timeline.',
      'longForm': 'Seeing is believing. Use a debt snowball calculator (many free online) to visualize how \$50 or \$100 extra per month shortens your debt-free date. This concrete evidence motivates continued effort.',
      'tags': ['debt', 'calculator', 'visualization'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Freeze your credit cards in a block of ice. Literal barrier = think twice before using.',
      'longForm': 'The "frozen card" trick works because it adds friction. Put credit cards in a container of water and freeze. If tempted to use it, you\'ll have to wait for it to thaw, giving you time to reconsider.',
      'tags': ['debt', 'friction', 'psychology'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Write your "why" for debt payoff. Revisit it whenever motivation wanes.',
      'longForm': 'Debt payoff is hard. Write down your "why": "to buy a house," "to stop living paycheck to paycheck," "to feel financially secure." Put it on your mirror. Read it when tempted to give up.',
      'tags': ['debt', 'why', 'motivation'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Build a tiny emergency fund (\$500-1,000) before aggressive debt payoff to avoid new debt.',
      'longForm': 'Aggressively paying debt without an emergency buffer backfires. A \$500 car repair forces you back into debt. Build a small emergency fund first, then attack debt. This prevents the cycle.',
      'tags': ['debt', 'emergency_fund', 'strategy'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Join a debt payoff community for accountability and motivation. You\'re not alone in this.',
      'longForm': 'Debt payoff is lonely. Join Reddit\'s r/DaveRamsey or r/povertyfinance, or a local debt-free group. Sharing wins, setbacks, and strategies with others on the journey provides crucial accountability and motivation.',
      'tags': ['debt', 'community', 'accountability'],
    },
    {
      'category': 'debt',
      'trigger': 'general',
      'tip': 'Once a card is paid off, don\'t close it if it helps your credit utilization ratio.',
      'longForm': 'Closing paid-off cards can hurt your credit score by increasing your utilization ratio (debt ÷ total credit). Keep them open with zero balance, but remove from wallet and freeze the accounts to avoid temptation.',
      'tags': ['debt', 'credit_score', 'utilization'],
    },
  ];

  // =================================================================
  // STRESS/EMOTIONAL SPENDING TIPS (20)
  // =================================================================
  static final List<Map<String, dynamic>> _stressEmotionalTips = [
    {
      'category': 'stress',
      'trigger': 'high_stress',
      'tip': 'You\'ve spent \$X after 8 PM this week. Late-night spending is often emotional. Try a pre-bed routine instead.',
      'longForm': 'Late-night spending is typically stress or boredom driven. Establish a pre-bed routine: tea, reading, journaling. This addresses the real need (relaxation) without the regret of impulse purchases.',
      'tags': ['stress', 'emotional', 'late_night'],
    },
    {
      'category': 'stress',
      'trigger': 'rapid_purchases',
      'tip': 'Three purchases in one hour signals emotional spending. Take a 15-minute break and check in with yourself.',
      'longForm': 'Rapid-fire purchasing is a red flag for emotional spending. Stop and ask: "What am I really feeling right now?" Often it\'s stress, loneliness, or boredom. Address the real emotion instead of medicating with purchases.',
      'tags': ['stress', 'emotional', 'rapid'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Keep a "spending emotions journal." Track what you were feeling before each purchase.',
      'longForm': 'Awareness breaks patterns. For two weeks, log every purchase alongside your emotional state. You\'ll see patterns: "I shop when lonely," "I order takeout when stressed." This awareness enables alternative coping strategies.',
      'tags': ['stress', 'journal', 'awareness'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Identify your emotional spending triggers: boredom, stress, sadness, celebration?',
      'longForm': 'Everyone has spending triggers. Common ones: boredom (browsing online), stress (takeout), sadness (retail therapy), celebration (restaurants). Identify yours and develop alternative responses to each emotion.',
      'tags': ['stress', 'triggers', 'identification'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Create a "boredom list" of free activities. Boredom spending costs the average person \$200/month.',
      'longForm': 'Boredom is expensive. Make a list of 10 free activities: walk, call a friend, read, exercise, clean a drawer. When bored, consult the list instead of defaulting to shopping.',
      'tags': ['stress', 'boredom', 'alternatives'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Practice the "5-minute rule": sit with the urge to spend for 5 minutes. Often, it passes.',
      'longForm': 'Emotional urges peak and fade. When you feel the urge to shop, set a 5-minute timer and sit with the feeling. Don\'t fight it, just observe. 70% of the time, the urge diminishes without action.',
      'tags': ['stress', 'urges', 'mindfulness'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'If you\'re sad, call someone instead of shopping. Connection heals; purchases don\'t.',
      'longForm': 'Retail therapy is a temporary band-aid. Sadness needs connection, not consumption. When feeling down, call a friend, text a family member, or join a community. Genuine connection addresses the root need.',
      'tags': ['stress', 'sadness', 'connection'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Exercise instead of emotional spending. A 20-minute walk reduces stress and saves money.',
      'longForm': 'Exercise releases endorphins - nature\'s mood booster. When stressed or emotional, take a 20-minute walk before spending. You\'ll often find the urge gone and your mood lifted, all without spending a dollar.',
      'tags': ['stress', 'exercise', 'alternatives'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Unfollow social media accounts that trigger spending: influencers, brands, aspirational lifestyles.',
      'longForm': 'Social media curates unrealistic lifestyles that trigger insecurity and spending. Unfollow accounts that make you feel inadequate or increase shopping urges. Protect your mental and financial health.',
      'tags': ['stress', 'social_media', 'comparison'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Try the "opposite action": feeling the urge to spend? Do the opposite - review your savings.',
      'longForm': 'Dialectical Behavior Therapy teaches "opposite action" for urges. When you want to spend, do the opposite: open your savings account, review your financial goals, or log into your investment account. This redirects the impulse.',
      'tags': ['stress', 'opposite_action', 'dbt'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Schedule "worry time": 15 minutes daily to process financial stress, then close the mental tab.',
      'longForm': 'Constant financial worry is exhausting. Schedule 15 minutes daily to fully engage with money stress: review accounts, make a plan, journal fears. Then close the mental tab. This contained processing reduces all-day anxiety.',
      'tags': ['stress', 'worry', 'compartmentalization'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Use the "feeling wheel" to identify specific emotions. "I\'m stressed" is too vague to address.',
      'longForm': 'Generic "stress" is hard to solve. Use an emotion wheel to pinpoint the specific feeling: anxious? Frustrated? Overwhelmed? Lonely? Specific emotions enable specific solutions beyond spending.',
      'tags': ['stress', 'emotions', 'specificity'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Practice gratitude when tempted by comparison. "I have enough" is financially liberating.',
      'longForm': 'Comparison is the thief of joy and destroyer of budgets. When you notice comparison-driven spending urges, list 3 things you\'re grateful for. This shifts focus from lack to abundance, reducing the need to "keep up."',
      'tags': ['stress', 'gratitude', 'comparison'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Establish "financial self-care": weekly check-ins that reduce anxiety rather than trigger it.',
      'longForm': 'Financial reviews don\'t have to be stressful. Create a Sunday 15-minute ritual: review the week, celebrate wins, adjust next week\'s budget. Pair it with coffee and music. Make money management a calm practice, not a source of dread.',
      'tags': ['stress', 'self_care', 'routine'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Recognize "treat yourself" culture as marketing. True self-care is often free: rest, boundaries, connection.',
      'longForm': '"Treat yourself" culture equates self-care with spending. Real self-care is usually free: sleep, saying no, connecting with loved ones, moving your body. Don\'t let marketing convince you that self-love requires purchases.',
      'tags': ['stress', 'self_care', 'marketing'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Use the "HALT" check before spending: Am I Hungry, Angry, Lonely, or Tired?',
      'longForm': 'HALT is a decision-making tool from recovery programs. Before any purchase, ask: Am I Hungry, Angry, Lonely, or Tired? If yes, address that need directly. Never make spending decisions in HALT states.',
      'tags': ['stress', 'halt', 'decision_making'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Create a "financial calm" playlist. Listen when feeling spending urges to regulate your nervous system.',
      'longForm': 'Music regulates the nervous system. Create a playlist of calming music and listen when you feel spending urges. The 5-10 minute pause while listening often dissipates the impulse.',
      'tags': ['stress', 'music', 'regulation'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Set "buying boundaries": no shopping when tired, hungry, or emotional. Wait for a neutral state.',
      'longForm': 'Establish firm rules: no shopping after 8 PM, when hungry, or within an hour of a stressful event. Buy only when calm and clear-headed. This single boundary prevents 80% of regrettable purchases.',
      'tags': ['stress', 'boundaries', 'rules'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Journal your financial wins weekly. Positive reinforcement reduces anxiety and builds confidence.',
      'longForm': 'Financial anxiety focuses on problems. Counter this by journaling wins every Sunday: "Stayed under budget," "Saved \$50," "Resisted an impulse buy." This positive focus reduces anxiety and builds self-efficacy.',
      'tags': ['stress', 'journaling', 'positive'],
    },
    {
      'category': 'stress',
      'trigger': 'general',
      'tip': 'Reframe money as a tool, not a source of identity or self-worth. You are not your bank account.',
      'longForm': 'Tying self-worth to money creates immense stress. You are not your net worth, salary, or debt. Money is a tool to support your values and goals - nothing more. This reframe dramatically reduces financial anxiety.',
      'tags': ['stress', 'identity', 'reframing'],
    },
  ];
}

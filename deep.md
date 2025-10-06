# Fin Co-Pilot: Comprehensive Technical Documentation

## 1. Project Overview

### 1.1. Purpose

This document provides a deep, technical dive into the Fin Co-Pilot Flutter application. Its goal is to equip the project owner and future developers with a thorough understanding of the app's architecture, feature workflows, and file-level implementation details to ensure maximum clarity for ongoing development and maintenance.

Fin Co-Pilot is a sophisticated personal finance application designed to act as an intelligent financial assistant for its users. It goes beyond simple expense tracking by leveraging a powerful, AI-driven "Agent Swarm" to provide deep financial insights, proactive coaching, and intelligent services that help users manage their money more effectively.

### 1.2. Core Architecture

The project is built using Flutter and follows modern, best-practice software architecture principles to ensure it is scalable, maintainable, and testable.

#### 1.2.1. Project Structure: Feature-First

The codebase is organized using a **feature-first** directory structure. This means that UI (widgets, screens), business logic (providers, services), and data models are grouped by the feature they belong to.

-   **`lib/features`**: Contains directories for each major feature of the app (e.g., `insights`, `coaching`, `shopping`). This co-location makes it easy to find all the code related to a specific part of the application.
-   **`lib/core`**: Contains foundational code shared across multiple features, such as core business logic, base classes, and fundamental utilities that are not tied to a specific feature.
-   **`lib/shared`**: Holds shared widgets, models, and constants that are reused throughout the application but are not part of the core business logic.

#### 1.2.2. State Management: Provider with ChangeNotifier

The application uses the **Provider** package for state management, coupled with the `ChangeNotifier` class. This approach provides a clear and efficient way to manage and distribute application state.

-   **`ChangeNotifier`**: Services or view models extend `ChangeNotifier`. They encapsulate business logic and hold the state for a particular feature or screen. When the state changes, the `notifyListeners()` method is called.
-   **`ChangeNotifierProvider`**: This widget is used to provide an instance of a `ChangeNotifier` to its descendants in the widget tree.
-   **`Consumer` / `context.watch`**: Widgets that need to react to state changes use these to listen to a `ChangeNotifier` and automatically rebuild when `notifyListeners()` is called.

This setup promotes a clean separation of concerns, keeping the business logic out of the UI and making the app easier to reason about and test.

## 2. The Agent Swarm: A Deep Dive

The core intelligence of Fin Co-Pilot comes from its "Agent Swarm," a collection of specialized AI agents built on Google's Gemini models. Each agent has a distinct responsibility and is orchestrated by a central service to handle complex user requests. All agents are located in the `lib/services/` directory.

This multi-agent architecture allows the application to break down complex financial tasks into manageable sub-problems, with each agent applying its specialized knowledge to a piece of the puzzle.

### 2.1. Orchestrator Agent

-   **File:** `lib/services/gemini_orchestrator_service.dart`
-   **Model:** `gemini-2.5-flash`

The **Orchestrator Agent** is the brain of the swarm. It is the first point of contact for any user input that requires AI processing. Its primary role is **intent classification**. It analyzes the user's natural language input to determine what they want to do and then routes the request to the appropriate specialist agent.

#### Workflow:

1.  Receives raw user input (e.g., "I spent $20 on lunch").
2.  Uses the `_determineIntent` method with a specific prompt to classify the input into one of several categories (`add_transaction`, `get_insights`, `price_search`, `general_query`).
3.  Based on the intent, it calls the corresponding agent to handle the request.
4.  For simple, general queries, it can handle the response directly.

#### Intent Classification Prompt:

```dart
final prompt = '''
You are an intent classifier for a personal finance app called Fin Co-Pilot.

Analyze the user's input and determine their intent. Respond ONLY with valid JSON.

User input: "$userInput"

Intent types:
- add_transaction: User wants to log an expense (e.g., "I spent \$50 on groceries", "bought coffee for \$5")
- get_insights: User wants financial analysis (e.g., "how much did I spend this month?", "show my spending breakdown")
- price_search: User wants to find best prices (e.g., "best price for iPhone 16", "where to buy cheap milk")
- general_query: General questions about the app or finances (e.g., "how do I add a transaction?", "what is a budget?")

Required JSON format:
{
  "type": "intent_type",
  "confidence": 0.95,
  "entities": {
    "amount": null,
    "category": null,
    "merchant": null,
    "product": null,
    "query": null
  }
}

Extract relevant entities based on intent type:
- For add_transaction: amount, category, merchant
- For price_search: product, query
- For get_insights: query

Respond with ONLY the JSON object, no markdown formatting, no other text.
''';
```

### 2.2. Receipt Parser Agent

-   **File:** `lib/services/receipt_parser_agent.dart`
-   **Model:** `gemini-2.5-flash-lite`

The **Receipt Parser Agent** specializes in Optical Character Recognition (OCR) for receipts. It uses a multimodal Gemini model to analyze an image of a receipt and extract structured data from it, automating the process of logging expenses.

The use of `gemini-2.5-flash-lite` indicates a strategy focused on cost-effectiveness and speed for this common task.

#### Workflow:

1.  Receives an image file of a receipt.
2.  Sends the image and a detailed prompt to the Gemini model.
3.  The model analyzes the image and returns a JSON object containing the extracted data.
4.  This data can then be used to pre-fill the transaction entry form for the user.

#### Receipt Parsing Prompt:

```dart
final prompt = '''
You are a receipt parser. Analyze this receipt image and extract the following information.

Extract these fields:
- merchant: Store/business name
- total: Total amount (number only, no currency symbol)
- currency: Currency code (USD, EUR, etc.) - infer from receipt
- date: Purchase date (YYYY-MM-DD format)
- items: List of items purchased with prices
- tax: Tax amount if visible
- payment_method: Payment method if visible (cash, credit, debit)

Respond with ONLY valid JSON in this exact format:
{
  "merchant": "Store Name",
  "total": 123.45,
  "currency": "USD",
  "date": "2025-10-04",
  "items": [
    {"name": "Item 1", "price": 10.00, "quantity": 1},
    {"name": "Item 2", "price": 5.50, "quantity": 2}
  ],
  "tax": 12.34,
  "payment_method": "credit_card",
  "confidence": 0.95
}

If you cannot read certain fields, use null. Set confidence between 0-1 based on image quality.
Respond with ONLY the JSON, no markdown formatting, no other text.
''';
```

### 2.3. Financial Analyst Agent

-   **File:** `lib/services/financial_analyst_agent.dart`
-   **Model:** `gemini-2.5-pro`

The **Financial Analyst Agent** is the most powerful and sophisticated agent in the swarm. It uses the high-end `gemini-2.5-pro` model to perform a deep analysis of a user's financial data and generate actionable insights.

#### Workflow:

1.  Fetches user transactions and budget data from Firestore for a given period.
2.  Calculates a wide range of statistics (total spending, category breakdowns, budget performance, anomalies, etc.).
3.  Constructs a highly detailed prompt containing all the raw data and statistics.
4.  Sends this prompt to `gemini-2.5-pro` for analysis.
5.  The model returns a set of structured insights, which are then parsed and stored in Firestore to be displayed to the user.

#### Financial Analysis Prompt:

```dart
return '''
You are a financial analyst AI. Analyze the following spending data and generate 3-5 actionable insights.

SPENDING SUMMARY:
- Total spent: \$${stats['total_spent'].toStringAsFixed(2)}
- Number of transactions: ${stats['transaction_count']}
- Average transaction: \$${stats['avg_transaction'].toStringAsFixed(2)}

SPENDING BY CATEGORY:
${byCategory.entries.map((e) => '- ${e.key}: \$${e.value.toStringAsFixed(2)} (${(e.value / stats['total_spent'] * 100).toStringAsFixed(1)}%)').join('\n')}

BUDGET PERFORMANCE:
${budgetPerformance.isEmpty ? 'No budgets set' : budgetPerformance.entries.map((e) {
  final data = e.value;
  return '- ${e.key}: \$${data['spent'].toStringAsFixed(2)} / \$${data['budget'].toStringAsFixed(2)} (${data['percent_used'].toStringAsFixed(0)}% used) - Status: ${data['status']}';
}).join('\n')}

ANOMALIES (Unusually high transactions):
${anomalies.isEmpty ? 'None detected' : anomalies.map((tx) => '- ${tx.merchant ?? 'Unknown'}: \$${tx.amount.toStringAsFixed(2)} on ${tx.transactionDate.toString().split(' ')[0]}').join('\n')}

RECURRING MERCHANTS (3+ transactions):
${recurringMerchants.isEmpty ? 'None detected' : recurringMerchants.map((m) => '- $m').join('\n')}

Generate 3-5 insights in this EXACT format (one per line):

[TYPE]|[SEVERITY]|[TITLE]|[DESCRIPTION]|[SUGGESTION]|[POTENTIAL_SAVINGS]

Where:
- TYPE: pattern, achievement, warning, opportunity, anomaly
- SEVERITY: low, medium, high
- TITLE: Short title (5-8 words)
- DESCRIPTION: One sentence explanation
- SUGGESTION: Actionable advice (one sentence)
- POTENTIAL_SAVINGS: Dollar amount if applicable, or 0

Example:
pattern|medium|Dining spending increased 25%|You spent \$450 on dining this month, up from \$360 last month|Consider meal prepping twice a week to reduce restaurant visits|80

Focus on:
1. Budget adherence (praise if on track, warn if overspending)
2. Spending patterns (increases/decreases)
3. Anomalies that need attention
4. Recurring subscriptions or wasteful spending
5. Savings opportunities

Be specific with numbers. Be encouraging but honest. Make suggestions actionable.
''';
```

### 2.4. Proactive Coach Agent

-   **File:** `lib/services/proactive_coach_agent.dart`
-   **Model:** `gemini-2.5-pro`

The **Proactive Coach Agent** acts as a personal financial mentor. It analyzes a user's recent spending behavior and provides personalized, timely coaching tips. Like the Analyst Agent, it uses `gemini-2.5-pro` for its advanced reasoning and personalization capabilities.

#### Workflow:

1.  Fetches the user's transactions from the last 30 days.
2.  Analyzes spending behavior, looking for trends, habits (both positive and negative), and changes week-over-week.
3.  Fetches previous coaching tips to avoid repetition.
4.  Constructs a prompt that includes the behavioral analysis and asks the model to act as a financial coach.
5.  Parses the response to create `CoachingTip` objects, which are then stored and displayed to the user.

#### Proactive Coaching Prompt:

```dart
return '''
You are an expert personal finance coach using Gemini 2.5 Pro with advanced reasoning capabilities. Use deep analytical thinking to provide personalized coaching.

REASONING APPROACH:
1. Analyze spending patterns for trends, anomalies, and behavioral insights
2. Consider psychological factors behind spending decisions
3. Identify both immediate opportunities and long-term financial health strategies
4. Provide actionable, personalized recommendations based on user's specific behavior

SPENDING ANALYSIS:
- Total spent (30 days): \$${analysis['totalSpent']?.toStringAsFixed(2) ?? '0'}
- Daily average: \$${analysis['avgDaily']?.toStringAsFixed(2) ?? '0'}
- Top category: ${analysis['topCategory'] ?? 'N/A'}
- Weekend spending: \$${analysis['weekendSpending']?.toStringAsFixed(2) ?? '0'}
- Weekday spending: \$${analysis['weekdaySpending']?.toStringAsFixed(2) ?? '0'}
- Recent positive habits: ${analysis['positiveHabits']?.join(', ') ?? 'None'}
- Areas for improvement: ${analysis['negativeHabits']?.join(', ') ?? 'None'}

RECENT TRANSACTIONS (last 10):
${transactions.take(10).map((tx) => '- ${tx.transactionDate.toString().split(' ')[0]}: \$${tx.amount.toStringAsFixed(2)} on ${tx.category} (${tx.description})').join('\n')}

AVOID REPETITION: Don't suggest these previous tips: $previousTitles

COACHING REQUIREMENTS:
- Create 2-3 different, actionable coaching tips
- Use behavioral psychology principles
- Provide specific, measurable recommendations
- Balance encouragement with constructive guidance
- Consider both short-term wins and long-term financial health

Use your advanced reasoning to create highly personalized, effective coaching tips.
''';
```

### 2.5. Price Intelligence Agent

-   **File:** `lib/services/price_intelligence_agent.dart`
-   **Model:** `gemini-2.5-flash`

The **Price Intelligence Agent** helps users make smarter shopping decisions by finding the best prices for products. It leverages the `gemini-2.5-flash` model's ability to ground its responses in Google Search results to provide real-time, location-aware pricing information.

#### Workflow:

1.  Checks a Firestore cache for recent results for the same product query to save costs and improve speed.
2.  If no valid cache exists, it constructs a detailed prompt asking the model to search for a product in the user's country and language.
3.  The model uses its connection to Google Search to find current prices from various retailers.
4.  It returns a structured list of prices, which is then parsed, cached in Firestore, and displayed to the user.

#### Price Search Prompt:

```dart
return '''
You are a price intelligence expert using Gemini 2.5 Flash with advanced reasoning capabilities. Search for the best prices for "$productQuery" in $userCountry.

REASONING APPROACH:
1. Think step-by-step about where consumers in $userCountry typically shop for this product
2. Consider both online retailers and physical stores with online presence
3. Analyze current market conditions and seasonal factors that might affect pricing
4. Verify availability status and shipping options

SEARCH INSTRUCTIONS:
1. Find prices from major online retailers and stores in $userCountry
2. Search in the local language: $userLanguage
3. Return prices in $userCurrency
4. Include at least 3-5 different retailers
5. Check current availability and stock status
6. Look for special offers, discounts, or bundle deals

For each result, provide:
- Merchant name
- Price (in $userCurrency)
- Availability status (in_stock / out_of_stock / pre_order / limited)
- Product URL (if available)
- Brief notes (e.g., includes shipping, on sale, Prime eligible, etc.)

FORMAT YOUR RESPONSE EXACTLY like this (one merchant per line):

[MERCHANT]|[PRICE]|[CURRENCY]|[AVAILABILITY]|[URL]|[NOTES]

Example:
Amazon.ca|299.99|CAD|in_stock|https://amazon.ca/product/xyz|Free shipping, Prime eligible
Best Buy Canada|319.99|CAD|in_stock|https://bestbuy.ca/product/abc|In-store pickup available
Walmart Canada|289.99|CAD|out_of_stock|https://walmart.ca/product/def|Expected back in 2 weeks

IMPORTANT: Use your advanced reasoning to provide accurate, current pricing information. If you cannot find a reliable price, skip that merchant.
''';
```

### 2.6. Report Generator Agent

-   **File:** `lib/services/report_generator_agent.dart`
-   **Model:** `gemini-2.5-flash`

The **Report Generator Agent** is responsible for creating structured financial reports (e.g., monthly or weekly summaries). It takes raw transaction data, calculates detailed statistics, and then uses the `gemini-2.5-flash` model to generate a natural language summary of the report.

#### Workflow:

1.  Fetches all transactions for a specific period (e.g., one month).
2.  Calculates a comprehensive set of statistics (total spend, category breakdowns, top merchants, daily averages, etc.).
3.  Constructs a prompt containing these statistics and asks the model to write an "executive summary."
4.  The model returns a narrative summary, which is combined with the raw statistics and transaction list to form a complete report.

#### Report Generation Prompt:

```dart
final prompt = '''
Generate a concise financial summary report in $language.

PERIOD OVERVIEW:
- Total Spent: $currency ${stats['total_spent'].toStringAsFixed(2)}
- Total Transactions: ${stats['transaction_count']}
- Average Transaction: $currency ${stats['average_transaction'].toStringAsFixed(2)}
- Daily Average: $currency ${stats['daily_average'].toStringAsFixed(2)}

SPENDING BY CATEGORY:
${byCategory.entries.map((e) => '- ${e.key}: $currency ${e.value['total'].toStringAsFixed(2)} (${e.value['percentage'].toStringAsFixed(1)}%)').join('\n')}

TOP MERCHANTS:
${topMerchants.take(5).map((m) => '- ${m['merchant']}: $currency ${m['amount'].toStringAsFixed(2)}').join('\n')}

Write a 3-4 paragraph executive summary that:
1. Opens with the total spending and key highlights
2. Analyzes spending patterns and notable trends
3. Identifies the top spending categories
4. Provides actionable insights or observations

Keep it professional, concise, and data-driven. Write in $language.
''';
```

## 3. Feature and UI Workflow Analysis

This section connects the backend Agent Swarm to the user-facing UI, describing the workflow for each major feature from the user's perspective.

### 3.1. Insights Screen

-   **File:** `lib/features/insights/presentation/screens/insights_screen.dart`

The Insights screen is the primary dashboard for users to understand their financial health. It provides both basic statistical analysis and deep AI-powered insights.

#### Workflow:

1.  **Initial View:** When the user navigates to the Insights screen, a `StreamBuilder` listens to the `transactionService.getCurrentMonthTransactions` stream to fetch all transactions for the current month.
2.  **Basic Insights:** While the stream is loading, shimmer placeholders are shown. Once data arrives, the `InsightsService.generateInsights` method is called locally to calculate basic statistics (total spend, category breakdown, top merchants). These are displayed immediately in charts and lists.
3.  **AI Analyst Invocation:** The screen contains a dedicated "AI Financial Analyst" card with an "Analyze" button.
4.  When the user taps this button, the `_generateFinancialInsights` method is triggered.
5.  This method calls the **Financial Analyst Agent** (`_financialAnalyst.analyzeSpending`), passing the `userId` and the date range for the current month.
6.  **Displaying Insights:** While the agent is working, a loading indicator is displayed. Upon completion, the agent returns a list of `FinancialInsight` objects. The UI then updates to display these rich, categorized insights in a series of formatted cards, each showing the insight's type, severity, title, description, and potential savings.

### 3.2. Coaching Screen

-   **File:** `lib/features/coaching/presentation/screens/coaching_screen.dart`

The Coaching screen provides users with personalized, actionable tips to improve their financial habits.

#### Workflow:

1.  **Initial View:** The screen uses a `StreamBuilder` to listen to the `_coach.getAllTips` stream, which retrieves all non-dismissed coaching tips for the user from Firestore.
2.  **Generating New Tips:** The user can tap a "New Tips" button on the app bar. This calls the `_generateCoaching` method.
3.  **Agent Invocation:** `_generateCoaching` calls the **Proactive Coach Agent** (`_coach.generateWeeklyCoaching`), passing the `userId`. The agent analyzes the last 30 days of transactions and generates new, personalized `CoachingTip` objects, which are saved to Firestore.
4.  **Displaying Tips:** Because the screen is listening to the tips stream, the new tips automatically appear in the UI as soon as they are saved to the database.
5.  **User Interaction:**
    *   Tapping a tip marks it as read (`_coach.markAsRead`).
    *   Tapping the 'x' icon on a tip dismisses it (`_coach.dismissTip`), removing it from the main view.

### 3.3. Shopping (Price Finder) Screen

-   **File:** `lib/features/shopping/presentation/screens/shopping_screen.dart`

The Price Finder screen empowers users to make smart purchasing decisions by finding the best prices for products.

#### Workflow:

1.  **User Input:** The user enters a product name into a search bar (`_searchController`).
2.  **Agent Invocation:** When the user submits the search, the `_searchPrices` method is called.
3.  This method first determines the user's location and currency (currently hardcoded placeholders).
4.  It then calls the **Price Intelligence Agent** (`_priceAgent.searchBestPrice`), passing the product query and user location data.
5.  **Displaying Results:** While the agent is searching, a shimmer loading animation is displayed.
6.  The agent returns a list of `PriceResult` objects. The UI sorts these to find the best price and displays each result in a card, highlighting the cheapest option.
7.  **User Actions:**
    *   Users can tap a result to open the product URL in an external browser (`_launchUrl`).
    *   Users can tap "Track" to save the product and its price for future price drop alerts (`_priceAgent.trackProduct`).

### 3.4. Reports Screen

-   **File:** `lib/features/reports/presentation/screens/reports_screen.dart`

The Reports screen allows users to generate, view, and export detailed financial reports for specific periods.

#### Workflow:

1.  **Period Selection:** The user is first presented with options to generate a report for "This Month" or "Last Month".
2.  **Agent Invocation:** Tapping a button calls the `_generateReport` method.
3.  This method calls the **Report Generator Agent** (`_reportAgent.generateMonthlyReport`), passing the `userId`, the selected year/month, and currency.
4.  **Displaying Report:** While the report is generating, a loading indicator is shown on the button.
5.  Once complete, the agent returns a comprehensive `Map` containing the AI summary, detailed statistics, and the full transaction list. The UI then switches to a detailed report view.
6.  **Exporting:** From the report view, the user can tap "PDF" or "CSV" to export the data. These actions call the `PdfExportService` or `CsvExportService` respectively, which use the report data to generate a file that can be shared via the device's share sheet.

### 3.5. Transaction Flow

#### Manual Entry:

A standard form allows users to manually input transaction details (amount, category, merchant, date). This is the baseline method for data entry.

#### Receipt Scanning:

1.  From the transaction entry form, the user can choose to scan a receipt.
2.  This action opens the device camera. Once a picture is taken, the image file is sent to the **Receipt Parser Agent**.
3.  The agent processes the image, extracts the relevant data (merchant, total, date, etc.), and returns it as a JSON object.
4.  The transaction entry form is then pre-filled with the extracted data, allowing the user to review and save it quickly.
# Fin Copilot v2 - AI Agents Specification
## Complete Multi-Agent System Design

**Document Version:** 1.0
**Last Updated:** October 21, 2025
**Status:** Active Development Blueprint

---

## Table of Contents
1. [Multi-Agent System Overview](#multi-agent-system-overview)
2. [Agent Architecture Patterns](#agent-architecture-patterns)
3. [Agent Specifications](#agent-specifications)
4. [Prompt Engineering](#prompt-engineering)
5. [Tool Registry](#tool-registry)
6. [Communication Protocols](#communication-protocols)
7. [Evaluation & Testing](#evaluation--testing)

---

## Multi-Agent System Overview

### Architecture Pattern

Fin Copilot uses the **Coordinator/Orchestrator Pattern** with **Agent-as-Tool** implementation:

```
                    ┌──────────────────────┐
                    │  Orchestrator Agent  │
                    │   (Coordinator)      │
                    └──────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
   ┌────▼─────┐        ┌─────▼──────┐      ┌──────▼───────┐
   │Financial │        │  Receipt   │      │    Price     │
   │ Analyst  │        │   Parser   │      │Intelligence  │
   │  Agent   │        │   Agent    │      │    Agent     │
   └──────────┘        └────────────┘      └──────────────┘
        │                     │                     │
   ┌────▼─────┐        ┌─────▼──────┐      ┌──────▼───────┐
   │ Context  │        │ Extractor  │      │  Validator   │
   │  Agent   │        │   Agent    │      │    Agent     │
   └──────────┘        └────────────┘      └──────────────┘
                             │
                      ┌──────▼────────┐
                      │ Pattern       │
                      │ Learner Agent │
                      └───────────────┘
```

### Agent Roster

| Agent | Role | Model | Priority | Status |
|-------|------|-------|----------|--------|
| **Orchestrator** | Route requests, coordinate agents | Gemini 2.5 Pro | P0 | Core |
| **Financial Analyst** | Deep financial analysis & insights | Gemini 2.5 Pro | P0 | Core |
| **Receipt Parser** | Extract data from receipts | Gemini 2.5 Flash | P0 | Core |
| **Extractor** | Parse natural language for transactions | Gemini 2.5 Flash | P0 | Core |
| **Validator** | Ensure data quality & completeness | Gemini 2.5 Flash-Lite | P0 | Core |
| **Context Agent** | User preferences & history | Gemini 2.5 Flash | P1 | Core |
| **Pattern Learner** | Learn spending patterns | Gemini 2.5 Pro | P1 | Enhancement |
| **Price Intelligence** | Find best prices, predict trends | Gemini 2.5 Pro | P1 | Feature |
| **Coaching Agent** | Personalized financial advice | Gemini 2.5 Flash | P1 | Feature |

---

## Agent Architecture Patterns

### 1. Orchestrator Pattern

**When to Use:** Entry point for all user requests

**Implementation:**
```python
from google_adk import Agent, AgentTool

orchestrator = Agent(
    name="Orchestrator",
    model=GeminiModel("gemini-2.5-pro"),
    system_prompt=ORCHESTRATOR_PROMPT,
    tools=[
        AgentTool(financial_analyst),
        AgentTool(receipt_parser),
        AgentTool(price_intelligence),
        AgentTool(extractor),
        AgentTool(validator),
        AgentTool(context_agent),
        # Regular tools
        get_user_context,
        query_firestore,
    ],
)
```

### 2. Sequential Delegation

**When to Use:** Multi-step workflows requiring order

**Example:** Transaction Entry Flow
```
User Input → Extractor → Validator → Context → Pattern Learner
```

### 3. Parallel Execution

**When to Use:** Independent tasks that can run concurrently

**Example:** Receipt Analysis
```
Receipt Image → OCR Extraction ──┬─→ Merchant Identification
                                  ├─→ Item Parsing
                                  └─→ Total Calculation
              ↓
         Merge Results → Validate → Save
```

### 4. Agent-as-Tool

**When to Use:** Complex sub-tasks requiring specialized expertise

**Implementation:**
```python
# Expose Financial Analyst as a tool
financial_analyst_tool = AgentTool(
    agent=financial_analyst,
    description="Analyzes user spending patterns and generates insights",
    parameters={
        "user_id": "string",
        "period": "string (week|month|year)",
        "focus_area": "string (optional)",
    }
)

# Orchestrator can call it like any tool
orchestrator.tools.append(financial_analyst_tool)
```

---

## Agent Specifications

### 1. Orchestrator Agent

#### Purpose
Main coordinator that receives user requests and routes them to appropriate specialized agents.

#### Configuration

```python
ORCHESTRATOR_CONFIG = {
    "name": "Orchestrator",
    "model": "gemini-2.5-pro",
    "temperature": 0.3,
    "max_output_tokens": 2048,
    "top_p": 0.95,
}
```

#### System Prompt

```python
ORCHESTRATOR_PROMPT = """
You are the Orchestrator agent for Fin Copilot, an AI-powered personal finance management system.

Your role is to:
1. Understand user intent from their messages
2. Route requests to the appropriate specialized agent(s)
3. Coordinate multi-agent workflows when needed
4. Synthesize results into clear, user-friendly responses
5. Ask clarifying questions when needed

Available Agents (as tools):
- Financial Analyst: Deep analysis, insights, trends, predictions
- Receipt Parser: Extract structured data from receipt images
- Price Intelligence: Find best prices, track deals, predict price drops
- Extractor: Parse natural language into structured transaction data
- Validator: Ensure data quality and completeness
- Context Agent: Access user preferences, history, and patterns
- Pattern Learner: Identify spending patterns and anomalies

Available Direct Tools:
- get_user_context(user_id): Get user profile and preferences
- query_transactions(user_id, filters): Search transaction history
- get_budget_status(user_id): Current budget information
- save_transaction(transaction_data): Save to database
- send_notification(user_id, message): Send push notification

Guidelines:
- Always confirm before making changes (saving, deleting)
- Provide context for your recommendations
- Be conversational but concise
- If uncertain, ask for clarification
- Handle errors gracefully
- Respect user privacy (don't share sensitive data in logs)

Response Format:
- For simple queries: Direct answer
- For complex requests: Step-by-step plan, then execute
- For errors: Apologize, explain issue, suggest alternative
- Always be helpful and encouraging

User Context:
{user_context}

Previous Conversation:
{conversation_history}
"""
```

#### Tools

```python
orchestrator_tools = [
    # Agent tools
    AgentTool(financial_analyst),
    AgentTool(receipt_parser),
    AgentTool(price_intelligence),
    AgentTool(extractor),
    AgentTool(validator),
    AgentTool(context_agent),
    AgentTool(pattern_learner),

    # Direct tools
    get_user_context,
    query_transactions,
    get_budget_status,
    save_transaction,
    send_notification,
    calculate_budget_remaining,
    get_exchange_rate,
]
```

#### Example Interactions

**Simple Transaction Entry:**
```
User: "I spent $50 on groceries"

Orchestrator:
1. Routes to Extractor agent
2. Extractor returns: {amount: 50, category: "groceries"}
3. Routes to Validator agent
4. Validator confirms completeness
5. Calls save_transaction()
6. Responds: "Got it! I've logged $50 for groceries."
```

**Complex Analysis Request:**
```
User: "How much am I spending on coffee this month?"

Orchestrator:
1. Calls get_user_context() to get user_id
2. Routes to Financial Analyst with query
3. Financial Analyst uses query_transactions() tool
4. Analyst analyzes coffee spending
5. Orchestrator synthesizes response:
   "You've spent $120 on coffee this month across 24 purchases.
    That's $30 more than last month. Consider cutting back to
    save $360/year."
```

---

### 2. Financial Analyst Agent

#### Purpose
Specialized agent for deep financial analysis, trend identification, and generating actionable insights.

#### Configuration

```python
FINANCIAL_ANALYST_CONFIG = {
    "name": "Financial Analyst",
    "model": "gemini-2.5-pro",
    "temperature": 0.2,  # Lower for more consistent analysis
    "max_output_tokens": 4096,
    "top_p": 0.9,
}
```

#### System Prompt

```python
FINANCIAL_ANALYST_PROMPT = """
You are an expert Financial Analyst agent specializing in personal finance analysis.

Your expertise includes:
- Spending pattern analysis
- Budget optimization
- Trend identification
- Anomaly detection
- Predictive modeling
- Financial goal tracking
- Savings opportunity identification

Analytical Framework:
1. Gather data using available tools
2. Calculate relevant metrics
3. Identify patterns and trends
4. Compare to benchmarks (historical, budgets, goals)
5. Generate actionable insights
6. Prioritize recommendations by impact

Available Tools:
- query_transactions(user_id, filters): Get transaction data
- get_budget_data(user_id): Get budget information
- calculate_metrics(transactions): Compute financial metrics
- identify_patterns(data, algorithm): ML pattern detection
- compare_periods(period1, period2): Historical comparison
- get_category_trends(user_id, category): Category analysis
- predict_spending(user_id, category, period): Forecast future spending

Analysis Guidelines:
- Use Persona-Task-Context-Format (PTCF) framework
- Set temperature ≤ 0.2 for deterministic reasoning
- Use Chain-of-Thought (CoT) for complex analyses
- Provide data-backed recommendations only
- Highlight both positive trends and concerns
- Always include actionable next steps
- Format numbers with proper currency symbols
- Use percentages for comparisons
- Reference specific date ranges

Output Format:
{
  "summary": "Brief 1-sentence overview",
  "metrics": {
    "total_spent": number,
    "vs_last_period": percentage,
    "vs_budget": percentage,
    "top_category": string,
  },
  "insights": [
    {
      "type": "positive|concern|neutral",
      "message": "Insight text",
      "data": {...},
    }
  ],
  "recommendations": [
    {
      "priority": "high|medium|low",
      "action": "Action description",
      "expected_impact": "Impact estimate",
    }
  ]
}

Current Analysis Request:
{analysis_request}

User Context:
{user_context}
"""
```

#### Tools

```python
financial_analyst_tools = [
    query_transactions,
    get_budget_data,
    calculate_metrics,
    identify_patterns,
    compare_periods,
    get_category_trends,
    predict_spending,
    get_user_goals,
    calculate_savings_rate,
]
```

#### Example Analysis

**Input:**
```python
{
  "user_id": "user123",
  "query": "Analyze my spending this month",
  "context": {
    "current_month": "October 2025",
    "budget": 3000,
  }
}
```

**Output:**
```json
{
  "summary": "October spending is 15% below budget with notable grocery savings",
  "metrics": {
    "total_spent": 2550,
    "vs_last_month": -12.5,
    "vs_budget": -15.0,
    "top_category": "Housing",
    "top_category_amount": 1200,
    "days_remaining": 10,
    "projected_total": 2850
  },
  "insights": [
    {
      "type": "positive",
      "message": "Grocery spending down 20% from last month ($400 vs $500)",
      "data": {
        "current": 400,
        "previous": 500,
        "savings": 100
      }
    },
    {
      "type": "concern",
      "message": "Dining out increased 40% ($350 vs $250), offsetting grocery savings",
      "data": {
        "current": 350,
        "previous": 250,
        "increase": 100
      }
    },
    {
      "type": "neutral",
      "message": "Transportation costs stable at $275 (within $25 of average)",
      "data": {
        "current": 275,
        "average": 290
      }
    }
  ],
  "recommendations": [
    {
      "priority": "medium",
      "action": "Continue grocery savings trend - you're on track to save $1,200/year",
      "expected_impact": "$100/month savings"
    },
    {
      "priority": "high",
      "action": "Reduce dining out by 2 meals/week to save $80/month",
      "expected_impact": "$960/year savings"
    },
    {
      "priority": "low",
      "action": "Consider carpooling or public transit to reduce transportation costs",
      "expected_impact": "$50/month potential savings"
    }
  ]
}
```

---

### 3. Receipt Parser Agent

#### Purpose
Extract structured transaction data from receipt images using OCR and AI parsing.

#### Configuration

```python
RECEIPT_PARSER_CONFIG = {
    "name": "Receipt Parser",
    "model": "gemini-2.5-flash",
    "temperature": 0.1,  # Very low for consistent parsing
    "max_output_tokens": 2048,
}
```

#### System Prompt

```python
RECEIPT_PARSER_PROMPT = """
You are a Receipt Parser agent specialized in extracting structured data from receipt images.

Your task is to parse OCR text from receipts and extract:
1. Merchant name and location
2. Transaction date and time
3. Line items with descriptions and prices
4. Subtotal, tax, tip, and total amounts
5. Payment method (if visible)

Input:
- OCR text from receipt image (may have errors)
- Image metadata (timestamp, location if available)

Output Schema:
{
  "merchant": {
    "name": string,
    "location": string | null,
    "category": string | null  // Auto-infer from merchant
  },
  "date": string (ISO 8601),
  "time": string (HH:MM) | null,
  "items": [
    {
      "description": string,
      "quantity": number,
      "unit_price": number,
      "total_price": number,
      "category": string | null  // Auto-categorize
    }
  ],
  "subtotal": number,
  "tax": number,
  "tip": number | null,
  "total": number,
  "payment_method": string | null,
  "confidence": number (0-1),
  "needs_review": boolean,
  "notes": string | null  // Any parsing issues
}

Parsing Guidelines:
- Handle OCR errors gracefully (common: 0/O, 1/I, S/$)
- Validate totals (subtotal + tax + tip should equal total)
- If validation fails, flag for review but provide best estimate
- Infer merchant category from name (e.g., "Whole Foods" → "Groceries")
- Auto-categorize items when possible
- Extract date even if partially visible
- Default to transaction date if receipt date unclear

Edge Cases:
- Itemized tips: Include in tip field
- Discounts: Subtract from subtotal
- Multi-page receipts: Combine items
- Handwritten amounts: Flag for manual review (low confidence)
- Foreign currency: Note currency code
- Multiple payment methods: List all

Confidence Scoring:
- 0.9-1.0: All fields clear, totals validate
- 0.7-0.9: Minor OCR errors corrected, totals validate
- 0.5-0.7: Some ambiguity, totals may not validate perfectly
- 0.3-0.5: Significant errors, needs review
- 0.0-0.3: Unable to parse, manual entry required

OCR Text:
{ocr_text}

Image Metadata:
{metadata}
"""
```

#### Tools

```python
receipt_parser_tools = [
    ocr_extract_text,  # ML Kit Text Recognition
    validate_total_calculation,
    infer_merchant_category,
    categorize_item,
    geocode_location,  # Get merchant location from name
    lookup_merchant_in_db,  # Check known merchants
]
```

#### Example Parsing

**Input (OCR Text):**
```
WHOLE FOODS MARKET
123 Main St, San Francisco CA

10/21/2025  14:32

Organic Milk           $5.99
Whole Wheat Bread      $3.49
Free Range Eggs        $6.99
Coffee Beans 1lb      $12.99

Subtotal              $29.46
Tax  (8.5%)            $2.50
Total                 $31.96

Card ***1234
```

**Output:**
```json
{
  "merchant": {
    "name": "Whole Foods Market",
    "location": "123 Main St, San Francisco CA",
    "category": "Groceries"
  },
  "date": "2025-10-21T14:32:00Z",
  "time": "14:32",
  "items": [
    {
      "description": "Organic Milk",
      "quantity": 1,
      "unit_price": 5.99,
      "total_price": 5.99,
      "category": "Dairy"
    },
    {
      "description": "Whole Wheat Bread",
      "quantity": 1,
      "unit_price": 3.49,
      "total_price": 3.49,
      "category": "Bakery"
    },
    {
      "description": "Free Range Eggs",
      "quantity": 1,
      "unit_price": 6.99,
      "total_price": 6.99,
      "category": "Dairy"
    },
    {
      "description": "Coffee Beans 1lb",
      "quantity": 1,
      "unit_price": 12.99,
      "total_price": 12.99,
      "category": "Beverages"
    }
  ],
  "subtotal": 29.46,
  "tax": 2.50,
  "tip": null,
  "total": 31.96,
  "payment_method": "Credit Card (****1234)",
  "confidence": 0.95,
  "needs_review": false,
  "notes": null
}
```

---

### 4. Extractor Agent

#### Purpose
Parse natural language descriptions into structured transaction data.

#### Configuration

```python
EXTRACTOR_CONFIG = {
    "name": "Extractor",
    "model": "gemini-2.5-flash",
    "temperature": 0.2,
    "max_output_tokens": 1024,
    "response_mime_type": "application/json",
}
```

#### System Prompt

```python
EXTRACTOR_PROMPT = """
You are a Transaction Data Extractor agent. Your job is to parse natural language descriptions into structured transaction data.

Input Examples:
- "I spent $50 on groceries at Whole Foods"
- "Coffee this morning, $5.25"
- "Paid €40 for dinner last Tuesday"
- "Gas $45 yesterday"
- "Movie tickets $30 for 2 people"

Output Schema:
{
  "amount": number (required),
  "currency": string (ISO 4217 code),
  "category": string (from predefined list),
  "merchant": string | null,
  "date": string (ISO 8601),
  "time": string (HH:MM) | null,
  "payment_method": string | null,
  "notes": string | null,
  "tags": string[] | null,
  "confidence": number (0-1),
  "needs_clarification": string[] | null
}

Extraction Rules:
1. Amount:
   - Extract numeric value (support: "50", "$50", "50 dollars", "fifty dollars")
   - Handle decimals: "50.25", "50.5", "50 and a half"
   - Approximate amounts: "around 50" → 50 with lower confidence

2. Currency:
   - Infer from symbol: $ → USD, € → EUR, £ → GBP, ¥ → JPY
   - Default to user's currency if not specified
   - Support: "50 euros", "50 USD", "50 dollars"

3. Category:
   - Match keywords to categories (see CATEGORY_KEYWORDS)
   - If no match, set to "Other" and flag for clarification
   - Consider merchant for context (e.g., "Starbucks" → "Coffee")

4. Merchant:
   - Extract proper nouns that look like business names
   - Clean up: "at Starbucks" → "Starbucks"
   - Null if generic: "coffee shop" → null

5. Date:
   - "today" → current date
   - "yesterday" → current date - 1 day
   - "last Tuesday" → previous Tuesday
   - "3 days ago" → current date - 3 days
   - "Jan 15" → YYYY-01-15 (current or last year)
   - Absolute dates: "2025-10-21", "10/21/2025"
   - Default to current date if not specified

6. Time:
   - Extract if mentioned: "this morning" → "09:00", "at 2pm" → "14:00"
   - Null if not specified

7. Payment Method:
   - Keywords: "cash", "card", "credit card", "debit", "Venmo", "PayPal", etc.
   - Null if not mentioned

8. Notes:
   - Capture additional context: "for team lunch" → notes: "team lunch"
   - Include quantity: "2 movie tickets" → notes: "2 tickets"

9. Tags:
   - Extract semantic tags: "work lunch" → tags: ["work", "meal"]
   - Null if none identified

10. Confidence:
    - 0.9-1.0: All required fields clear
    - 0.7-0.9: Minor ambiguity resolved with context
    - 0.5-0.7: Significant ambiguity, made best guess
    - 0.0-0.5: Missing required fields, needs clarification

11. Needs Clarification:
    - Array of questions if data incomplete or ambiguous
    - Examples: ["What category?", "Which store?", "What date?"]

Category Keywords:
{CATEGORY_KEYWORDS}

User Context:
- Default Currency: {user_currency}
- Timezone: {user_timezone}
- Recent Merchants: {recent_merchants}
- Frequent Categories: {frequent_categories}

User Message:
"{user_message}"
"""

CATEGORY_KEYWORDS = {
    "Groceries": ["grocery", "groceries", "supermarket", "food shopping", "Whole Foods", "Safeway", "Trader Joe's"],
    "Dining Out": ["restaurant", "dinner", "lunch", "breakfast", "meal", "ate out", "dined"],
    "Coffee": ["coffee", "café", "Starbucks", "espresso", "latte"],
    "Transportation": ["gas", "fuel", "uber", "lyft", "taxi", "metro", "bus", "parking"],
    "Entertainment": ["movie", "theater", "concert", "show", "game", "museum"],
    "Shopping": ["clothes", "shopping", "bought", "Amazon", "Target"],
    "Utilities": ["electric", "gas bill", "water", "internet", "phone bill"],
    "Healthcare": ["doctor", "pharmacy", "medicine", "hospital", "dentist"],
    "Fitness": ["gym", "yoga", "fitness", "workout", "sports"],
    "Education": ["book", "course", "class", "tuition", "seminar"],
}
```

#### Tools

```python
extractor_tools = [
    parse_date_natural_language,
    match_category_keywords,
    lookup_merchant_category,
    validate_currency_code,
    normalize_amount,
]
```

#### Example Extractions

**Simple:**
```
Input: "I spent $50 on groceries"
Output: {
  "amount": 50.00,
  "currency": "USD",
  "category": "Groceries",
  "merchant": null,
  "date": "2025-10-21",
  "confidence": 0.85,
  "needs_clarification": null
}
```

**Complex:**
```
Input: "Paid €40 for team dinner at Mario's last Tuesday around 7pm"
Output: {
  "amount": 40.00,
  "currency": "EUR",
  "category": "Dining Out",
  "merchant": "Mario's",
  "date": "2025-10-15",  // Calculated: last Tuesday
  "time": "19:00",
  "notes": "team dinner",
  "tags": ["work", "meal"],
  "confidence": 0.95,
  "needs_clarification": null
}
```

**Ambiguous:**
```
Input: "Coffee yesterday"
Output: {
  "amount": null,
  "currency": "USD",
  "category": "Coffee",
  "merchant": null,
  "date": "2025-10-20",
  "confidence": 0.40,
  "needs_clarification": ["How much did you spend?"]
}
```

---

### 5. Validator Agent

#### Purpose
Ensure transaction data is complete, accurate, and consistent.

#### Configuration

```python
VALIDATOR_CONFIG = {
    "name": "Validator",
    "model": "gemini-2.5-flash-lite",  # Fast, lightweight
    "temperature": 0.0,  // Deterministic
    "max_output_tokens": 512,
}
```

#### System Prompt

```python
VALIDATOR_PROMPT = """
You are a Data Validator agent. Your job is to ensure transaction data is complete, accurate, and consistent.

Validation Rules:

1. Required Fields:
   - amount: Must be > 0
   - currency: Must be valid ISO 4217 code
   - category: Must be from predefined list or "Other"
   - date: Must be valid date, not in future (unless marked as planned)

2. Optional Fields:
   - merchant: If present, should be reasonable business name
   - payment_method: If present, should be from known types
   - notes: No validation needed
   - tags: No validation needed

3. Range Checks:
   - amount: Warn if > $1000 (potential error or unusual expense)
   - date: Warn if > 30 days ago (might be forgotten transaction)

4. Consistency Checks:
   - Category matches merchant (e.g., "Starbucks" should be "Coffee" not "Groceries")
   - Amount reasonable for category (e.g., $500 for coffee is suspicious)
   - Date matches time context (e.g., "this morning" but date is yesterday)

5. Data Enrichment:
   - If merchant known, suggest category
   - If category "Other", try to infer from merchant/notes
   - Standardize merchant names (e.g., "Starbucks Coffee" → "Starbucks")

Output Schema:
{
  "valid": boolean,
  "data": {...},  // Cleaned/enriched data
  "warnings": string[],
  "errors": string[],
  "suggestions": {
    "category": string | null,
    "merchant": string | null,
  }
}

Validation Levels:
- ERROR: Missing required field or invalid value (blocks save)
- WARNING: Unusual value or inconsistency (allow save with confirmation)
- SUGGESTION: Recommended improvement (optional)

Input Transaction Data:
{transaction_data}

Predefined Categories:
{categories}

Known Merchants:
{known_merchants}
"""
```

#### Example Validation

**Valid Transaction:**
```
Input: {
  "amount": 50.00,
  "currency": "USD",
  "category": "Groceries",
  "merchant": "Whole Foods",
  "date": "2025-10-21"
}

Output: {
  "valid": true,
  "data": {
    "amount": 50.00,
    "currency": "USD",
    "category": "Groceries",
    "merchant": "Whole Foods",
    "date": "2025-10-21T00:00:00Z"
  },
  "warnings": [],
  "errors": [],
  "suggestions": null
}
```

**Invalid Transaction:**
```
Input: {
  "amount": -50.00,  // Negative!
  "currency": "USD",
  "category": "Groceries",
  "date": "2025-12-25"  // Future date!
}

Output: {
  "valid": false,
  "data": null,
  "warnings": [],
  "errors": [
    "Amount must be greater than 0",
    "Date cannot be in the future"
  ],
  "suggestions": null
}
```

**Warnings:**
```
Input: {
  "amount": 500.00,  // High amount for coffee!
  "currency": "USD",
  "category": "Coffee",
  "merchant": "Starbucks",
  "date": "2025-10-21"
}

Output: {
  "valid": true,
  "data": {...},
  "warnings": [
    "Unusually high amount for Coffee category ($500). Is this correct?"
  ],
  "errors": [],
  "suggestions": null
}
```

---

## Prompt Engineering

### PTCF Framework

All agent prompts follow the **Persona-Task-Context-Format** structure:

```
[PERSONA]
You are a {role} agent specializing in {domain}.

[TASK]
Your job is to {primary_task}.

[CONTEXT]
User Context: {user_data}
Historical Data: {history}
Current State: {state}

[FORMAT]
Output Schema:
{json_schema}

Guidelines:
- {guideline_1}
- {guideline_2}
```

### Temperature Settings

| Agent | Temperature | Reasoning |
|-------|-------------|-----------|
| Orchestrator | 0.3 | Balanced creativity and consistency |
| Financial Analyst | 0.2 | Deterministic analysis |
| Receipt Parser | 0.1 | Consistent data extraction |
| Extractor | 0.2 | Reliable parsing |
| Validator | 0.0 | Completely deterministic |
| Context Agent | 0.3 | Some creativity for recommendations |
| Pattern Learner | 0.4 | Creative pattern identification |
| Coaching Agent | 0.5 | Natural, conversational advice |

### JSON Mode

All extraction and parsing agents use `response_mime_type: "application/json"` for structured outputs.

---

## Tool Registry

### Firestore Tools

```python
def query_transactions(user_id: str, filters: dict) -> list:
    """Query user transactions with optional filters."""

def save_transaction(user_id: str, transaction: dict) -> str:
    """Save transaction to Firestore, return ID."""

def update_transaction(transaction_id: str, updates: dict) -> bool:
    """Update transaction fields."""

def delete_transaction(transaction_id: str) -> bool:
    """Soft delete transaction."""

def get_budget_data(user_id: str) -> dict:
    """Get user budget information."""

def get_user_preferences(user_id: str) -> dict:
    """Get user settings and preferences."""
```

### Analysis Tools

```python
def calculate_metrics(transactions: list) -> dict:
    """Calculate financial metrics from transactions."""

def identify_patterns(data: list, algorithm: str) -> dict:
    """Use ML to identify spending patterns."""

def predict_spending(user_id: str, category: str, period: str) -> dict:
    """Forecast future spending."""

def compare_periods(user_id: str, period1: str, period2: str) -> dict:
    """Compare spending between time periods."""
```

### External API Tools

```python
def get_exchange_rate(from_currency: str, to_currency: str) -> float:
    """Get current exchange rate."""

def find_product_prices(barcode: str) -> list:
    """Query price comparison APIs."""

def geocode_location(address: str) -> dict:
    """Convert address to coordinates."""
```

---

## Communication Protocols

### Agent-to-Agent (A2A)

```python
# Enable A2A protocol
from google_adk import enable_a2a

enable_a2a([
    orchestrator,
    financial_analyst,
    receipt_parser,
    extractor,
    validator,
    context_agent,
    pattern_learner,
])

# Agents can now communicate directly
# Example: Orchestrator → Financial Analyst
result = orchestrator.call_agent(
    agent=financial_analyst,
    task="Analyze spending patterns for user123",
    context={...}
)
```

### Model Context Protocol (MCP)

```python
# Register MCP tools
from mcp_client import McpClient

mcp = McpClient([
    "dart-flutter-mcp-server",
    "financial-tools-mcp",
])

# Make MCP tools available to agents
orchestrator.add_tools(mcp.get_tools())
```

---

## Evaluation & Testing

### Agent Performance Metrics

| Agent | Metric | Target | Measurement Method |
|-------|--------|--------|-------------------|
| Extractor | Accuracy | >95% | Manual review of 100 samples |
| Extractor | Latency | <1s | Cloud Trace |
| Receipt Parser | Accuracy | >85% | OCR + parsing validation |
| Receipt Parser | Latency | <5s | Cloud Trace |
| Financial Analyst | Insight Quality | >4/5 rating | User feedback |
| Validator | False Positive Rate | <5% | Flagged valid transactions |
| Orchestrator | Correct Routing | >98% | Agent call accuracy |

### Test Scenarios

**Transaction Extraction:**
```python
test_cases = [
    {
        "input": "I spent $50 on groceries",
        "expected": {
            "amount": 50.00,
            "category": "Groceries",
            "confidence": >0.8
        }
    },
    {
        "input": "Coffee this morning, around 5 bucks",
        "expected": {
            "amount": 5.00,
            "category": "Coffee",
            "date": "today"
        }
    },
    # ... 100+ test cases
]
```

### Continuous Evaluation

```python
# Run daily evaluations
def evaluate_agents():
    results = {}

    # Test Extractor
    extractor_results = run_test_suite(extractor, test_cases)
    results['extractor'] = {
        'accuracy': calculate_accuracy(extractor_results),
        'latency': calculate_avg_latency(extractor_results),
    }

    # Test Receipt Parser
    receipt_results = run_test_suite(receipt_parser, receipt_test_cases)
    results['receipt_parser'] = {...}

    # Log to monitoring
    log_metrics(results)

    # Alert if below threshold
    if results['extractor']['accuracy'] < 0.95:
        send_alert("Extractor accuracy dropped below 95%")
```

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-21 | Claude (AI Research) | Initial agent specifications |

**Next Steps:** Implement agents in ADK, test prompts, evaluate performance.

---

**End of AI Agents Specification**

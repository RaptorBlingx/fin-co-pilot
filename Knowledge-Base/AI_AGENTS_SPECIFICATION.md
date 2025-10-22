# AI Agents Specification v3

**Last Updated:** October 22, 2025
**Architecture:** 3-Agent System (Simplified)

---

## Architecture Overview

**OLD (Rejected):** 9 agents, complex orchestration, 3-5 sec response, $0.004/txn
**NEW (Approved):** 3 agents, simple flow, <1 sec response, $0.0008/txn

### The 3 Agents

1. **Financial Copilot Agent** (Gemini 2.5 Flash) - Main intelligence, 80% of interactions
2. **Vision Agent** (Gemini 2.5 Flash-Lite) - Receipt/document OCR only
3. **Analyst Agent** (Gemini 2.5 Flash) - Background insights, runs on schedule

---

## 1. Financial Copilot Agent

**Model:** Gemini 2.5 Flash
**Purpose:** Main conversational AI handling all user interactions
**Usage:** 80% of requests

### Capabilities
- Transaction extraction + validation in one call
- Multi-turn conversations with context
- Function calling for real-time data access
- Natural language understanding
- Budget queries and advice

### System Prompt

```
You are the Financial Copilot, an empathetic AI financial wellness companion.

CORE PERSONALITY:
- Supportive and encouraging, never judgmental
- Reduce anxiety, don't increase it
- Celebrate wins, gentle on overspending
- Like a friend who genuinely cares

PRIMARY FUNCTIONS:
1. Transaction Extraction
   - Parse natural language: "spent $15 on lunch at chipotle"
   - Extract: amount, merchant, category, date
   - Auto-categorize with 95%+ accuracy
   - Ask for missing required fields only

2. Financial Queries
   - Answer: "How much did I spend on coffee this week?"
   - Calculate: "Can I afford $200 shoes?"
   - Predict: "When will I run out of money?"
   - Compare: "Am I spending more than last month?"

3. Guidance & Support
   - Budget adherence check before purchases
   - Suggest alternatives when over budget
   - Emotional support for financial anxiety
   - Prevent regret spending

EXTRACTION RULES:
- Categories: Coffee, Dining, Groceries, Transport, Entertainment, Shopping, Health, Bills, Education, Travel, Other
- Infer merchant from context: "starbucks" → Coffee category
- Handle various amount formats: "$5", "five dollars", "5 bucks" → $5.00
- If unclear, ask ONE clarifying question
- Default to most likely category, allow correction

RESPONSE STYLE:
- Conversational, warm, brief (2-3 sentences)
- Use 1 emoji max per response
- Acknowledge what user provided
- If transaction complete: "Got it! $15 for lunch at Chipotle 🌯"
- If missing info: "Got the $15! What did you buy?"
- If over budget: "You're at $145/$150 dining budget. Still good for today! 👍"
- If way over budget: "Heads up - you're $50 over dining budget. Want to skip this one?"

FUNCTION CALLING:
You have access to these functions:
- saveTransaction(amount, merchant, category, date, description)
- getTransactions(startDate, endDate, category)
- getBudget(category)
- getCurrentBalance()
- getPredictedCashFlow()
- getSpendingPatterns(category, timeframe)

Always call functions to save/retrieve data. Never fabricate information.

EMOTIONAL INTELLIGENCE:
- Detect stress spending patterns: frequent small purchases after work hours
- Offer pause prompts: "Take a breath. Do you really need this?"
- Suggest alternatives: "Maybe brew coffee at home today?"
- Celebrate restraint: "Great decision! That's $5 toward your goal"

CONTEXT RETENTION:
- Remember previous transaction details in conversation
- "Another coffee" → use last coffee merchant and price
- "Same place" → use last merchant
- Build on conversation history

ANXIETY REDUCTION:
- Frame everything positively
- "You're doing great" > "You're overspending"
- "You're $50 ahead of last month" > "You only saved $50"
- Reassure: "You're okay. Let's adjust together"

EXAMPLES:

User: "coffee five bucks"
You: "Got it! $5 for coffee. Where was that?" [wait for merchant]

User: "starbucks"
You: "Perfect! $5 at Starbucks logged as Coffee ☕ That's your 2nd one this week ($10 total)"

User: "can i afford 200 dollar shoes"
You: [Call getCurrentBalance(), getPredictedCashFlow()]
"You have $847, but with upcoming bills ($450 due Oct 25), you'd have $197 for 10 days. That's tight. Maybe wait til payday? Or find shoes under $100?"

User: "how much on coffee this week"
You: [Call getTransactions(thisWeek, Coffee)]
"You've spent $35 on coffee this week across 7 visits. That's $10 more than your usual $25. Want to set a coffee budget?"

User: "i'm stressed about money"
You: "I hear you. Let's look at your situation together. [Call getCurrentBalance(), getPredictedCashFlow()] You have $650 now, and at your current rate, you'll end the month with $200. You're okay. Want me to help you find extra savings?"
```

### Tools/Functions

```typescript
// Save transaction
saveTransaction({
  amount: number,
  merchant: string,
  category: string,
  date: string,
  description?: string,
  userId: string
}): Promise<{success: boolean, transactionId: string}>

// Query transactions
getTransactions({
  userId: string,
  startDate: string,
  endDate: string,
  category?: string
}): Promise<Transaction[]>

// Get budget info
getBudget({
  userId: string,
  category: string
}): Promise<{budgeted: number, spent: number, remaining: number}>

// Current balance
getCurrentBalance({
  userId: string
}): Promise<{balance: number, lastUpdated: string}>

// Cash flow prediction
getPredictedCashFlow({
  userId: string
}): Promise<{
  daysUntilZero: number,
  projectedEndBalance: number,
  dailyBurnRate: number
}>

// Spending patterns
getSpendingPatterns({
  userId: string,
  category: string,
  timeframe: 'week' | 'month'
}): Promise<{
  totalSpent: number,
  transactionCount: number,
  avgPerTransaction: number,
  trend: 'up' | 'down' | 'stable'
}>
```

### Temperature & Config

```typescript
const copilotConfig = {
  model: 'gemini-2.5-flash',
  temperature: 0.7,
  topK: 40,
  topP: 0.95,
  maxOutputTokens: 512,
  functions: [
    saveTransaction,
    getTransactions,
    getBudget,
    getCurrentBalance,
    getPredictedCashFlow,
    getSpendingPatterns
  ]
}
```

### Example Interactions

**Transaction Entry:**
```
User: "spent 15 at chipotle"
Copilot: [Calls saveTransaction(15, "Chipotle", "Dining", now)]
         "Got it! $15 for lunch at Chipotle 🌯 That's $45 on dining this week"
```

**Budget Check:**
```
User: "should i get starbucks"
Copilot: [Calls getBudget("Coffee"), getSpendingPatterns("Coffee", "week")]
         "You're at $25/$30 coffee budget for the week. You're good! ☕"
```

**Affordability:**
```
User: "can i afford $200 shoes"
Copilot: [Calls getCurrentBalance(), getPredictedCashFlow()]
         "You have $847 but $450 in bills due soon. After that, $197 for 10 days.
         That's only $19/day vs your usual $30. Maybe wait til payday?"
```

---

## 2. Vision Agent

**Model:** Gemini 2.5 Flash-Lite
**Purpose:** OCR for receipts and documents only
**Usage:** 15% of requests

### System Prompt

```
You are a receipt OCR specialist. Extract ALL information from receipts accurately.

EXTRACT:
1. Merchant/store name
2. Date and time
3. ALL individual items with:
   - Item name (exact from receipt)
   - Quantity
   - Unit price
   - Total price per item
   - Category inference (Produce, Dairy, Meat, Bakery, Beverages, etc.)
4. Subtotal, tax, total
5. Payment method (if visible)
6. Store location/address (if visible)

RULES:
- Extract EVERY item, no matter how small
- Preserve exact item names
- If quantity not shown, assume 1
- Include discounts as negative amounts
- If text unclear, mark as [unclear]

OUTPUT FORMAT (JSON only):
{
  "merchant": "Store Name",
  "date": "2025-10-22T14:30:00",
  "location": "City, State",
  "items": [
    {
      "name": "Organic Milk 1 Gal",
      "quantity": 1,
      "unit_price": 4.99,
      "total_price": 4.99,
      "category": "Dairy"
    }
  ],
  "subtotal": 47.23,
  "tax": 3.78,
  "total": 51.01,
  "payment_method": "VISA ****1234"
}

CATEGORIES FOR GROCERY ITEMS:
Produce, Dairy, Meat, Seafood, Bakery, Frozen, Beverages, Snacks, Pantry, Health, Other
```

### Configuration

```typescript
const visionConfig = {
  model: 'gemini-2.5-flash-lite',
  temperature: 0.2, // Low for accuracy
  maxOutputTokens: 2048
}
```

### Usage

```typescript
// Receipt scanning
async function scanReceipt(imageBytes: Uint8List) {
  const response = await visionAgent.generateContent([
    Content.multi([
      TextPart(VISION_PROMPT),
      InlineDataPart('image/jpeg', imageBytes)
    ])
  ]);

  const receiptData = JSON.parse(response.text);

  // Pass to Financial Copilot for price analysis
  const priceAnalysis = await financialCopilot.analyzeReceiptPrices(receiptData);

  return { receiptData, priceAnalysis };
}
```

---

## 3. Analyst Agent

**Model:** Gemini 2.5 Flash
**Purpose:** Background analysis, runs on schedule (daily/weekly)
**Usage:** 5% of requests, but critical for insights

### Runs On Schedule
- Daily: 9 PM - Money Story generation
- Daily: Continuous - Anomaly detection
- Weekly: Sunday 8 PM - Pattern analysis
- Monthly: 1st day - Deep insights

### System Prompt

```
You are the Financial Analyst, running background analysis to generate insights.

DAILY MONEY STORY (9 PM):
Generate a conversational summary of today's spending.

Input: Array of today's transactions
Output: Engaging narrative with emojis

Template:
"Today's Money Story 📖
[Day], [Date]

You spent $[total] today

• $[amt] - [description] [emoji] [merchant]
• $[amt] - [description] [emoji] [merchant]
...

Top category: [category] ($[amount])
This week: $[weekTotal]

[Contextual insight based on patterns]"

INSIGHTS RULES:
- Compare to typical spending for this day of week
- Note if significantly higher/lower
- Celebrate low-spend days enthusiastically
- Be gentle on high-spend days
- Identify emerging patterns

ANOMALY DETECTION:
Monitor for:
- Unusual merchants (never seen before + high amount)
- Duplicate charges (same amount + merchant within 24hrs)
- Spike in category (>50% above typical)
- Out-of-pattern timing (3 AM purchase)
- Foreign transaction (if unusual)

Alert if detected, but with context:
"Unusual: $200 at [New Merchant]. Intentional purchase?"

PATTERN ANALYSIS (Weekly):
Identify:
- Spending trends by category (up/down %)
- Day-of-week patterns
- Merchant frequency
- Budget adherence
- Potential savings opportunities

Generate coaching tips:
"You spent $140 on coffee this month ($35/week). Brewing at home 2x/week would save $120/month."

TONE:
- Analytical but accessible
- Data-driven, not judgy
- Actionable insights only
- Encouraging and supportive
```

### Configuration

```typescript
const analystConfig = {
  model: 'gemini-2.5-flash',
  temperature: 0.4, // Balanced for creativity + accuracy
  topK: 40,
  topP: 0.9,
  maxOutputTokens: 1024
}
```

### Scheduled Functions

```typescript
// Cloud Function - runs at 9 PM daily
export const generateMoneyStory = functions.pubsub
  .schedule('0 21 * * *')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const users = await getActiveUsers();

    for (const user of users) {
      const todayTxns = await getTransactions(user.id, today);
      const story = await analystAgent.generateMoneyStory(todayTxns);
      await sendNotification(user.id, story);
    }
  });

// Cloud Function - runs continuously
export const detectAnomalies = functions.firestore
  .document('transactions/{transactionId}')
  .onCreate(async (snap, context) => {
    const txn = snap.data();
    const userHistory = await getTransactions(txn.userId, last30Days);

    const anomaly = await analystAgent.detectAnomaly(txn, userHistory);

    if (anomaly.detected) {
      await sendAlert(txn.userId, anomaly.message);
    }
  });

// Cloud Function - runs Sunday 8 PM
export const weeklyAnalysis = functions.pubsub
  .schedule('0 20 * * 0')
  .onRun(async (context) => {
    const users = await getActiveUsers();

    for (const user of users) {
      const weekTxns = await getTransactions(user.id, thisWeek);
      const insights = await analystAgent.analyzeWeek(weekTxns);
      await saveInsights(user.id, insights);
    }
  });
```

---

## Agent Communication Flow

### Transaction Entry Flow
```
User speaks: "five bucks coffee starbucks"
    ↓
Financial Copilot Agent:
  - Extracts: $5.00, Coffee, Starbucks
  - Calls saveTransaction()
  - Responds: "Got it! $5 at Starbucks ☕"
    ↓
Done (1 agent, <1 second)
```

### Receipt Scanning Flow
```
User scans receipt photo
    ↓
Vision Agent:
  - OCR extracts all items + prices
  - Returns structured JSON
    ↓
Financial Copilot Agent:
  - Analyzes prices vs market
  - Generates comparison report
  - "You paid $4.99 for milk - $1.20 more than Trader Joe's"
    ↓
Done (2 agents, <5 seconds)
```

### Daily Summary Flow
```
9 PM daily trigger
    ↓
Analyst Agent:
  - Fetches today's transactions
  - Generates Money Story
  - Returns narrative
    ↓
Send push notification
    ↓
Done (background, doesn't block user)
```

---

## Why 3 Agents Work

**OLD Problem (9 agents):**
- Orchestrator routes → Extractor extracts → Validator validates → Context analyzes
- 4 sequential calls for 1 transaction
- 3-5 seconds total
- $0.004 cost

**NEW Solution (3 agents):**
- Financial Copilot does it all in 1 call
- Extraction + validation + context in one intelligent prompt
- <1 second total
- $0.0008 cost

**Why This Works:**
- Gemini 2.5 Flash is smart enough (95%+ accuracy proven)
- Function calling provides real-time data access
- Multi-turn conversations maintain context naturally
- No orchestration overhead

**When to Use Each:**

| Task | Agent | Why |
|------|-------|-----|
| Transaction entry | Copilot | Needs understanding + data access |
| Budget query | Copilot | Needs data + advice |
| Can I afford X? | Copilot | Needs calculation + context |
| Receipt scan | Vision | Specialized OCR task |
| Receipt price analysis | Copilot | Needs market comparison |
| Daily summary | Analyst | Background, scheduled |
| Anomaly detection | Analyst | Pattern recognition |
| Weekly insights | Analyst | Deep analysis |

---

## Evaluation Metrics

### Financial Copilot
- Extraction accuracy: >95%
- Response time: <1 sec
- User satisfaction: >90%
- Function call success: >99%

### Vision Agent
- OCR accuracy: >95%
- Item extraction: >90%
- Processing time: <5 sec

### Analyst Agent
- Story engagement: >80% open rate
- Anomaly detection: <5% false positives
- Insight actionability: >70% act on tips

---

## Prompt Engineering Guidelines

### PTCF Framework
- **Persona:** Who the agent is
- **Task:** What it should do
- **Context:** What information it has
- **Format:** How to respond

### Best Practices
- Be specific about output format
- Provide concrete examples
- Use clear constraints
- Test with edge cases
- Iterate based on failures

### Temperature Settings
- **0.2:** OCR, data extraction (accuracy critical)
- **0.4:** Analysis, insights (balanced)
- **0.7:** Conversation, advice (creative but grounded)

---

**End of AI Agents Specification v3**

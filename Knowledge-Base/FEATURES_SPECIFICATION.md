# Fin Copilot v2 - Features Specification
## Complete Feature Requirements & User Stories

**Document Version:** 1.0
**Last Updated:** October 21, 2025
**Status:** Active Development Blueprint

---

## Table of Contents
1. [Feature Priority Matrix](#feature-priority-matrix)
2. [Transaction Management](#1-transaction-management)
3. [Budgeting System](#2-budgeting-system)
4. [Insights & Analytics](#3-insights--analytics)
5. [Price Intelligence](#4-price-intelligence)
6. [Financial Coaching](#5-financial-coaching)
7. [Settings & Personalization](#6-settings--personalization)
8. [Notifications System](#7-notifications-system)
9. [Security & Privacy](#8-security--privacy)
10. [Onboarding Flow](#9-onboarding-flow)

---

## Feature Priority Matrix

| Feature Area | Priority | Complexity | User Impact | MVP Status |
|--------------|----------|------------|-------------|------------|
| Transaction Management | P0 | High | Critical | ✅ Must Have |
| Basic Budgeting | P0 | Medium | Critical | ✅ Must Have |
| Core AI Agents | P0 | Very High | Critical | ✅ Must Have |
| Dashboard Insights | P0 | Medium | High | ✅ Must Have |
| Receipt Scanning | P1 | High | High | ✅ Should Have |
| Voice Input | P1 | High | High | ✅ Should Have |
| Price Intelligence | P1 | Very High | High | ✅ Should Have |
| Financial Coaching | P1 | High | Medium | ⚠️ Nice to Have |
| Advanced Reports | P2 | Medium | Medium | ⚠️ Nice to Have |
| Multi-Currency | P2 | Medium | Medium | ⚠️ Nice to Have |
| Export Features | P2 | Low | Low | ⚠️ Nice to Have |

**Priority Levels:**
- **P0:** Critical for MVP launch
- **P1:** Important for competitive differentiation
- **P2:** Enhancement features for future versions

---

## 1. Transaction Management

### Overview
Core feature enabling users to log, view, edit, and analyze financial transactions through multiple input methods powered by AI.

### 1.1 Add Transaction via AI Chat

#### User Story
> "As a user, I want to add transactions through natural conversation with AI, so I can quickly log expenses without navigating through forms."

#### Functional Requirements

**FR-TXN-001:** Chat Interface
- User opens Financial Copilot via FAB
- AI greets user with personalized message based on context
- User types natural language like "I spent $50 on groceries at Whole Foods"
- AI extracts: amount ($50), category (groceries), merchant (Whole Foods), date (today)
- AI asks for clarification if needed ("Was that today or yesterday?")
- User confirms or edits extracted data
- Transaction saved to Firestore

**FR-TXN-002:** Natural Language Processing
- Support formats: "spent $50 on coffee", "$50 coffee", "coffee $50", "50 dollars coffee"
- Parse dates: "yesterday", "last Tuesday", "3 days ago", "Jan 15"
- Recognize categories from keywords
- Extract merchant names
- Handle multiple currencies: "$50", "€40", "¥1000"

**FR-TXN-003:** Multi-Item Transactions
- User can add multiple items in one conversation
- "I bought milk for $5, bread for $3, and eggs for $4"
- AI extracts each item separately
- Option to save as single aggregated transaction or separate items
- Total calculation and confirmation

#### UI/UX Requirements

**UX-TXN-001:** Chat Interface
```
┌─────────────────────────────────────┐
│  Financial Copilot             [X]  │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ AI: Hi! Ready to log an     │   │
│  │ expense or ask anything     │   │
│  │ about your finances?        │   │
│  └─────────────────────────────┘   │
│                                     │
│          ┌────────────────────┐    │
│          │ I spent $50 on    │    │
│          │ groceries         │    │
│          └────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ AI: Got it! I'll log $50    │   │
│  │ for groceries today.        │   │
│  │                             │   │
│  │ ┏━━━━━━━━━━━━━━━━━━━━━┓   │   │
│  │ ┃ Amount: $50.00       ┃   │   │
│  │ ┃ Category: Groceries  ┃   │   │
│  │ ┃ Date: Today          ┃   │   │
│  │ ┃ Payment: Card        ┃   │   │
│  │ ┗━━━━━━━━━━━━━━━━━━━━━┛   │   │
│  │                             │   │
│  │ [Edit] [Confirm ✓]         │   │
│  └─────────────────────────────┘   │
│                                     │
├─────────────────────────────────────┤
│ 🎤 [Type a message...]         [>] │
└─────────────────────────────────────┘
```

**UX-TXN-002:** Quick Actions
- Suggested buttons appear based on context
- "Add Another", "View All Transactions", "See Budget Status"
- Recent merchants as quick-tap options
- Common amounts ($5, $10, $20, $50, $100)

#### AI Agent Involvement

**Agent:** Orchestrator Agent + Extractor Agent
- **Orchestrator:** Routes message to appropriate handler
- **Extractor:** Parses natural language for transaction data
- **Validator:** Ensures data completeness and accuracy
- **Context:** Provides user history for better extraction

**Prompt Template (Extractor Agent):**
```
You are a financial transaction data extractor. Your job is to parse natural language descriptions into structured transaction data.

User message: "{user_message}"
User's currency: "{user_currency}"
User's timezone: "{user_timezone}"
Recent merchants: {recent_merchants}

Extract:
- amount (number)
- currency (ISO code)
- category (from predefined list)
- merchant (string, or null)
- date (ISO 8601, default to today)
- payment_method (card, cash, digital wallet, or null)
- notes (any additional context)

If information is missing or ambiguous, set "needs_clarification" field with questions to ask.

Return JSON only.
```

#### Edge Cases

| Edge Case | Handling |
|-----------|----------|
| Ambiguous amount ("spent around 50") | Ask for exact amount or use ~$50 with flag |
| Future date | Warn user, allow if intentional (planned expense) |
| Very large amount | Confirmation dialog "Did you really spend $10,000?" |
| No category match | AI suggests closest match, user can create custom |
| Multiple currencies in one input | Extract each separately, ask which to use |
| Receipt image + text | Process image first, then combine with text context |

#### Acceptance Criteria

✅ **AC-TXN-001:** User can add transaction in <30 seconds
✅ **AC-TXN-002:** AI extracts data with 95%+ accuracy
✅ **AC-TXN-003:** Unclear inputs trigger clarification questions
✅ **AC-TXN-004:** Confirmation screen shows before saving
✅ **AC-TXN-005:** Transaction appears immediately in list after save
✅ **AC-TXN-006:** Works offline (queued for sync when online)

---

### 1.2 Add Transaction via Voice

#### User Story
> "As a user on the go, I want to add transactions using just my voice, so I don't need to look at my phone."

#### Functional Requirements

**FR-VOICE-001:** Voice Activation
- Tap microphone icon in chat or transaction screens
- Visual feedback (pulsing animation) during listening
- Real-time transcription display
- Stop button or auto-stop after silence

**FR-VOICE-002:** Speech-to-Text
- Use platform native STT (iOS Speech, Android SpeechRecognizer)
- Fallback to Google Cloud Speech-to-Text if available
- Support continuous listening for natural speech
- Handle background noise gracefully

**FR-VOICE-003:** Voice Command Processing
- Same NLP as text chat
- Handle filler words ("um", "uh", "like")
- Support commands: "add expense", "show budget", "how much did I spend"
- Voice confirmation option ("Transaction added!")

#### UI/UX Requirements

```
Voice Input State Machine:
IDLE → (tap mic) → LISTENING → (processing) → TRANSCRIBED → (confirm) → SAVED
                      ↓                           ↓
                   (cancel)                    (retry)
                      ↓                           ↓
                    IDLE                      LISTENING
```

**Visual States:**
1. **Idle:** Microphone icon (outline)
2. **Listening:** Pulsing animation, "Listening..." text
3. **Processing:** Spinner, "Processing..."
4. **Transcribed:** Text displayed, "Did you say: {text}?"
5. **Confirmed:** Checkmark, "Transaction added!"

#### Acceptance Criteria

✅ **AC-VOICE-001:** Voice input works in quiet and moderately noisy environments
✅ **AC-VOICE-002:** Transcription accuracy >90% for clear speech
✅ **AC-VOICE-003:** User can review and edit transcription before confirming
✅ **AC-VOICE-004:** Works with screen locked (future: Siri/Assistant shortcuts)
✅ **AC-VOICE-005:** Graceful fallback if STT unavailable

---

### 1.3 Add Transaction via Receipt Scan

#### User Story
> "As a user, I want to photograph my receipts and have the transactions automatically extracted, so I don't have to manually type each item."

#### Functional Requirements

**FR-RECEIPT-001:** Image Capture
- Camera integration via image_picker
- Option to select from gallery
- Image quality guidance (lighting, angle)
- Crop/rotate before processing

**FR-RECEIPT-002:** OCR Processing
- Use ML Kit Text Recognition v2
- Extract text from receipt image
- Parse structured data: merchant, items, amounts, date, total
- Handle various receipt formats

**FR-RECEIPT-003:** Data Extraction
- Receipt Agent processes OCR text
- Extracts line items with amounts
- Identifies merchant from logo/header
- Determines date from receipt
- Calculates total and validates

**FR-RECEIPT-004:** Review & Edit
- Display extracted items in editable list
- User can add/remove items
- Edit amounts, categories
- Assign categories to each item or bulk category

**FR-RECEIPT-005:** Receipt Storage
- Original image stored in Firebase Storage
- Linked to transaction(s) in Firestore
- Accessible from transaction detail
- Used for tax/expense reporting

#### UI/UX Flow

```
[Camera Icon] → [Capture Receipt] → [Processing...] → [Review Extracted Data]
                       ↓
                 [Image Preview]
                   [Retake]

Review Screen:
┌─────────────────────────────────┐
│ Receipt from Whole Foods        │
│ Date: Oct 21, 2025             │
├─────────────────────────────────┤
│ ☑ Milk           $4.99  [Edit] │
│ ☑ Bread          $3.49  [Edit] │
│ ☑ Eggs           $5.99  [Edit] │
│ ☑ Coffee         $12.99 [Edit] │
├─────────────────────────────────┤
│ Total: $27.46                   │
│                                 │
│ Category: [Groceries ▾]        │
│ Payment: [Credit Card ▾]       │
│                                 │
│ [Add All Items] [Save as One]  │
└─────────────────────────────────┘
```

#### Edge Cases

| Edge Case | Handling |
|-----------|----------|
| Blurry/unreadable image | Ask user to retake or manually enter |
| Multiple pages | Process each page separately, combine |
| Handwritten receipts | May have lower accuracy, manual review |
| Foreign language | ML Kit supports many languages, translate |
| Itemized tip/tax | Separate from items, add to transaction metadata |
| Partial visibility | Extract what's visible, ask for missing info |

#### Acceptance Criteria

✅ **AC-RECEIPT-001:** Extracts text with >85% accuracy for standard printed receipts
✅ **AC-RECEIPT-002:** Correctly identifies merchant in >80% of cases
✅ **AC-RECEIPT-003:** Parsing completes in <5 seconds for typical receipt
✅ **AC-RECEIPT-004:** User can review all extracted items before saving
✅ **AC-RECEIPT-005:** Original receipt image accessible from transaction
✅ **AC-RECEIPT-006:** Works offline (image cached, processed when online)

---

### 1.4 View & Manage Transactions

#### User Story
> "As a user, I want to view all my transactions in a sortable, filterable list, so I can find specific expenses quickly."

#### Functional Requirements

**FR-VIEW-001:** Transaction List
- Display all transactions in reverse chronological order
- Group by date (Today, Yesterday, This Week, Earlier)
- Show: amount, category icon, merchant, date
- Pull-to-refresh for latest data
- Infinite scroll / pagination

**FR-VIEW-002:** Search & Filter
- Search by merchant, amount, category, notes
- Filter by:
  - Date range (custom, presets: this week, month, year)
  - Category (multi-select)
  - Amount range
  - Payment method
  - Tags
- Sort by: date, amount, category, merchant

**FR-VIEW-003:** Bulk Actions
- Select multiple transactions
- Bulk edit category
- Bulk delete
- Bulk export

**FR-VIEW-004:** Transaction Detail
- Tap transaction to view full details
- Display all fields: amount, category, merchant, date, payment method, notes, tags, receipt image
- Quick actions: Edit, Delete, Duplicate, Share
- Related insights (e.g., "You spent $120 on coffee this month")

#### UI/UX Design

```
Transactions Screen:
┌─────────────────────────────────┐
│ Transactions          [Filter🔍]│
├─────────────────────────────────┤
│ [Search transactions...]        │
├─────────────────────────────────┤
│ Today                           │
│  🍕 Lunch - Pizza Place         │
│     -$15.50         12:30 PM    │
│                                 │
│  ☕ Coffee - Starbucks          │
│     -$5.25           9:15 AM    │
├─────────────────────────────────┤
│ Yesterday                       │
│  🛒 Groceries - Whole Foods     │
│     -$87.32          5:45 PM    │
│     [Receipt 📷]                │
│                                 │
│  ⛽ Gas - Shell                 │
│     -$45.00          2:30 PM    │
├─────────────────────────────────┤
│ (Load more...)                  │
└─────────────────────────────────┘

Transaction Detail:
┌─────────────────────────────────┐
│ < Back          [Edit] [Delete] │
├─────────────────────────────────┤
│      🍕 Food & Dining           │
│                                 │
│         -$15.50                 │
│                                 │
│  Merchant: Pizza Place          │
│  Category: Food & Dining        │
│  Date: Oct 21, 2025  12:30 PM  │
│  Payment: Credit Card •••• 4242 │
│  Notes: Team lunch meeting      │
│                                 │
│  Tags: [work] [meal]            │
│                                 │
│  📷 Receipt                     │
│  ┌─────────────────────┐        │
│  │   [Receipt Image]   │        │
│  └─────────────────────┘        │
│                                 │
│  💡 Insight                     │
│  You've spent $120 on food     │
│  this week, 20% over budget.   │
│                                 │
│ [Duplicate] [Share]            │
└─────────────────────────────────┘
```

#### Acceptance Criteria

✅ **AC-VIEW-001:** List loads in <2 seconds with 100+ transactions
✅ **AC-VIEW-002:** Search returns results in <500ms
✅ **AC-VIEW-003:** Filters apply without page reload
✅ **AC-VIEW-004:** Transaction detail opens with smooth animation
✅ **AC-VIEW-005:** Receipt images load progressively (thumbnail first)
✅ **AC-VIEW-006:** Works offline with cached data

---

### 1.5 Edit & Delete Transactions

#### User Story
> "As a user, I want to edit transaction details if I make a mistake, so my financial data stays accurate."

#### Functional Requirements

**FR-EDIT-001:** Edit Transaction
- All fields editable: amount, category, merchant, date, payment method, notes, tags
- Real-time validation (e.g., amount > 0)
- Save button with confirmation
- "Last edited" timestamp

**FR-EDIT-002:** Delete Transaction
- Delete from detail screen or swipe-to-delete in list
- Confirmation dialog required
- Soft delete (30-day recovery window)
- Undo option in snackbar

**FR-EDIT-003:** Transaction History
- Audit trail of edits
- Show who edited (multi-user future)
- Show what changed

#### Acceptance Criteria

✅ **AC-EDIT-001:** Edits save within 1 second
✅ **AC-EDIT-002:** Budgets and insights update immediately after edit
✅ **AC-EDIT-003:** Delete requires confirmation
✅ **AC-EDIT-004:** Undo works within 10 seconds of delete
✅ **AC-EDIT-005:** Edit conflicts resolved if offline edits sync

---

## 2. Budgeting System

### Overview
Flexible budgeting system allowing users to set monthly budgets by category or total, with real-time tracking and AI-powered recommendations.

### 2.1 Create & Manage Budgets

#### User Story
> "As a user, I want to set monthly budgets for different spending categories, so I can control my expenses."

#### Functional Requirements

**FR-BUDGET-001:** Budget Creation
- Set total monthly budget (e.g., $3,000/month)
- OR set category-specific budgets (e.g., Groceries: $500, Dining: $300)
- OR hybrid: total budget divided into categories
- Recurring (auto-renew each month) or one-time

**FR-BUDGET-002:** Budget Allocation
- Suggest allocation based on historical spending
- AI recommendations for optimal distribution
- Visual slider to allocate total budget
- Warning if allocations exceed total

**FR-BUDGET-003:** Budget Templates
- Preset templates: "Essential Only", "Balanced", "Aggressive Savings"
- User can save custom templates
- Share templates with community (future)

#### UI/UX Design

```
Budget Creation Screen:
┌─────────────────────────────────┐
│ Set Your Budget    [Save] [X]  │
├─────────────────────────────────┤
│                                 │
│ How much do you want to spend  │
│ this month?                     │
│                                 │
│  ┌─────────────────────────┐   │
│  │  Total: $ 3,000        │   │
│  └─────────────────────────┘   │
│                                 │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                 │
│ Divide by category?            │
│ [○ No, track total only]       │
│ [● Yes, allocate to categories]│
│                                 │
├─────────────────────────────────┤
│ 🛒 Groceries        $500  17%  │
│ ────────────────────────────   │
│                                 │
│ 🍽️ Dining Out        $300  10%  │
│ ────────────────────────────   │
│                                 │
│ 🚗 Transportation   $400  13%  │
│ ────────────────────────────   │
│                                 │
│ 🏠 Housing        $1,200  40%  │
│ ────────────────────────────   │
│                                 │
│ 💡 Utilities        $200   7%  │
│ ────────────────────────────   │
│                                 │
│ 🎬 Entertainment    $200   7%  │
│ ────────────────────────────   │
│                                 │
│ 📱 Other            $200   6%  │
│ ────────────────────────────   │
│                                 │
│ Remaining: $0                  │
│                                 │
│ 💡 AI Suggestion:              │
│ Based on your spending, try    │
│ reducing Dining Out to $250    │
│ to save $50/month.             │
│                                 │
│ [Auto-allocate] [Start Fresh] │
└─────────────────────────────────┘
```

#### Acceptance Criteria

✅ **AC-BUDGET-001:** User can create budget in <2 minutes
✅ **AC-BUDGET-002:** AI auto-allocation matches user's actual spending within 10%
✅ **AC-BUDGET-003:** Visual feedback if allocations don't sum to total
✅ **AC-BUDGET-004:** Budgets persist across months
✅ **AC-BUDGET-005:** Edit/delete budgets without data loss

---

### 2.2 Budget Tracking & Alerts

#### User Story
> "As a user, I want to see how much of my budget I've used in real-time, so I can avoid overspending."

#### Functional Requirements

**FR-TRACK-001:** Real-Time Progress
- Progress bars for each category
- Color coding: Green (<75%), Yellow (75-90%), Orange (90-100%), Red (>100%)
- Percentage and dollar amount remaining
- Days left in month

**FR-TRACK-002:** Smart Alerts
- Alert at 75% of budget
- Warning at 90% of budget
- Critical alert at 100% of budget
- Daily summary if trending over
- AI prediction: "At this rate, you'll exceed by $X"

**FR-TRACK-003:** Budget Insights
- Comparison with previous months
- Category trends
- Savings opportunities
- "You're on track to save $X this month!"

#### UI/UX Design

```
Budget Dashboard:
┌─────────────────────────────────┐
│ Budget Overview    [Edit]      │
├─────────────────────────────────┤
│ October 2025        22 days left│
│                                 │
│ Total: $2,450 / $3,000         │
│ ████████████████░░░░  82%      │
│ $550 remaining                 │
│                                 │
├─────────────────────────────────┤
│ 🛒 Groceries                   │
│ $480 / $500                    │
│ ███████████████████░  96% ⚠️   │
│ $20 left                       │
├─────────────────────────────────┤
│ 🍽️ Dining Out                  │
│ $350 / $300                    │
│ ████████████████████  117% 🚨  │
│ $50 over budget!               │
│                                 │
│ 💡 Tip: You've exceeded your   │
│ dining budget. Try cooking     │
│ more meals at home.            │
├─────────────────────────────────┤
│ 🚗 Transportation              │
│ $275 / $400                    │
│ █████████████░░░░░░░  69%      │
│ $125 remaining                 │
├─────────────────────────────────┤
│ (View all categories...)        │
└─────────────────────────────────┘
```

#### Acceptance Criteria

✅ **AC-TRACK-001:** Budget updates within 2 seconds of new transaction
✅ **AC-TRACK-002:** Alerts fire at correct thresholds (75%, 90%, 100%)
✅ **AC-TRACK-003:** User can customize alert thresholds
✅ **AC-TRACK-004:** Predictions accurate within 10%
✅ **AC-TRACK-005:** Historical comparison shows trend (up/down)

---

## 3. Insights & Analytics

### Overview
AI-powered financial insights providing users with actionable intelligence about their spending patterns, trends, and opportunities.

### 3.1 Dashboard Insights

#### User Story
> "As a user, I want to see my financial health at a glance when I open the app."

#### Functional Requirements

**FR-DASH-001:** Key Metrics
- Total spent this month vs last month
- Top 3 spending categories
- Budget status (on track / over / under)
- Projected monthly spend based on current rate
- Savings this month

**FR-DASH-002:** Smart Insights Cards
- AI-generated insights based on patterns
- Rotating cards with different insights
- Actionable recommendations
- Visual charts and graphs

**FR-DASH-003:** Quick Actions
- Add expense FAB
- View all transactions
- Check budget status
- Access price finder
- Talk to AI coach

#### Example Insights

1. **Spending Trend:** "You're spending 15% less this month. Keep it up! 🎉"
2. **Category Alert:** "Coffee expenses up 40% vs last month. Consider a home brew?"
3. **Savings Opportunity:** "Switch to our recommended grocery store and save $20/week"
4. **Achievement:** "Streak: 7 days under budget! 🔥"
5. **Prediction:** "At current rate, you'll finish $150 under budget"

#### Acceptance Criteria

✅ **AC-DASH-001:** Dashboard loads in <2 seconds
✅ **AC-DASH-002:** Insights refresh every 6 hours or on user action
✅ **AC-DASH-003:** At least 3 unique insights shown per day
✅ **AC-DASH-004:** Insights relevant to user's actual data
✅ **AC-DASH-005:** Tap insight for detailed explanation

---

### 3.2 Detailed Reports

#### User Story
> "As a user, I want detailed reports of my spending by time period and category, so I can understand where my money goes."

#### Functional Requirements

**FR-REPORT-001:** Time Periods
- Weekly view
- Monthly view
- Yearly view
- Custom date range

**FR-REPORT-002:** Visualizations
- Pie charts (category breakdown)
- Line charts (spending over time)
- Bar charts (category comparison)
- Trend lines

**FR-REPORT-003:** Export Options
- PDF report with charts
- CSV data export
- Share via email/message

#### Acceptance Criteria

✅ **AC-REPORT-001:** Charts render in <1 second
✅ **AC-REPORT-002:** PDF exports in <5 seconds
✅ **AC-REPORT-003:** Data accuracy 100%
✅ **AC-REPORT-004:** Supports up to 1000 transactions in single report

---

## 4. Price Intelligence

### Overview
Advanced price comparison and deal-finding system using barcode scanning, ML predictions, and real-time price tracking.

### 4.1 Barcode Scanner & Product Search

#### User Story
> "As a user, I want to scan a product barcode and see the best prices across stores, so I can make informed purchasing decisions."

#### Functional Requirements

**FR-PRICE-001:** Barcode Scanning
- Camera-based barcode/QR code scanner
- Supports UPC, EAN, QR codes
- Real-time detection
- Flashlight toggle
- Manual barcode entry

**FR-PRICE-002:** Product Lookup
- Search product database by barcode
- Fallback to AI image recognition if barcode not in DB
- Display product name, image, description
- Show price history

**FR-PRICE-003:** Price Comparison
- Query multiple retailers for current prices
- Display sorted by price (lowest first)
- Show availability status
- Shipping costs (if applicable)
- Link to purchase

#### Detailed in [FEATURES_SPECIFICATION.md - Continued]

---

*Due to length, this document continues with detailed specifications for:*
- 4.2 Wishlist & Price Alerts
- 4.3 Deal Detection & Recommendations
- 5. Financial Coaching
- 6. Settings & Personalization
- 7. Notifications System
- 8. Security & Privacy
- 9. Onboarding Flow

**Note:** Each section follows the same detailed format with user stories, functional requirements, UI/UX designs, acceptance criteria, and edge cases.

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-21 | Claude (AI Research) | Initial specification document |

**Next Steps:** Review with stakeholders, prioritize features for MVP, begin architecture design.

---

**End of Features Specification (Part 1)**

*Full document available in project repository*

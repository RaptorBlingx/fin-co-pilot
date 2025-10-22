# Fin Copilot v3 - Data Models

**Last Updated:** October 22, 2025
**Version:** 3.0

---

## Firestore Collections

### 1. users

```typescript
interface User {
  uid: string;                    // Firebase Auth UID (document ID)
  email: string;
  displayName: string;
  photoURL?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;

  preferences: {
    currency: string;             // USD, EUR, etc.
    locale: string;               // en-US
    timezone: string;             // America/New_York
    theme: 'light' | 'dark' | 'system';
    notificationsEnabled: boolean;
    voiceEnabled: boolean;        // NEW: Voice input preference
    smsParsingEnabled: boolean;   // NEW: SMS auto-parsing
  };

  settings: {
    monthlyIncome?: number;
    categories: string[];         // Custom categories
    defaultPaymentMethod?: string;
    budgetAlertThreshold: number; // 0-100 (percentage)
  };

  onboarding: {
    completed: boolean;
    smsPermissionGranted: boolean;  // NEW
    completedAt?: Timestamp;
  };

  // NEW: Financial Health tracking
  financialHealth: {
    currentScore: number;         // 0-100
    lastCalculated: Timestamp;
    trend: 'improving' | 'stable' | 'declining';
  };

  // NEW: Couples feature
  coupleAccount?: {
    partnerId: string;            // Other user's UID
    role: 'initiator' | 'partner';
    status: 'pending' | 'active' | 'disconnected';
    connectedAt?: Timestamp;
  };
}
```

### 2. transactions

```typescript
interface Transaction {
  id: string;
  userId: string;
  amount: number;
  currency: string;
  category: string;
  type: 'expense' | 'income';
  merchant?: string;
  description?: string;
  notes?: string;
  tags?: string[];

  date: Timestamp;
  time?: string;                  // HH:MM

  paymentMethod?: string;         // card, cash, digital_wallet
  paymentDetails?: {
    cardLast4?: string;
    cardBrand?: string;
  };

  receipt?: {
    imageUrl: string;
    thumbnailUrl?: string;
    uploadedAt: Timestamp;
    parsedData?: ReceiptData;
    priceComparison?: {           // NEW: Price intelligence
      averagePrice: number;
      savingsOpportunity: number;
      cheapestStore: string;
    };
  };

  metadata: {
    source: 'manual' | 'voice' | 'chat' | 'receipt' | 'sms';  // NEW: sms
    confidence?: number;
    verified: boolean;
    edited: boolean;
    aiAgent?: string;             // NEW: Which agent processed it
  };

  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface ReceiptData {
  items: Array<{
    description: string;
    quantity: number;
    unitPrice: number;
    totalPrice: number;
  }>;
  subtotal: number;
  tax: number;
  tip?: number;
  total: number;
}
```

### 3. budgets

```typescript
interface Budget {
  id: string;
  userId: string;
  name: string;
  type: 'monthly' | 'weekly' | 'custom';

  amount: number;
  currency: string;

  period: {
    start: Timestamp;
    end: Timestamp;
    recurring: boolean;
  };

  categories?: {
    [category: string]: {
      budgeted: number;
      spent: number;              // Calculated
      remaining: number;          // Calculated
    };
  };

  totalSpent: number;             // Calculated
  alerts: {
    enabled: boolean;
    thresholds: number[];         // [75, 90, 100]
    lastAlertAt?: Timestamp;
  };

  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### 4. chat_messages

```typescript
interface ChatMessage {
  id: string;
  userId: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Timestamp;

  metadata?: {
    agent: string;                // financial_copilot, vision, analyst
    functionCalls?: Array<{
      name: string;
      args: Record<string, any>;
      result?: any;
    }>;
    extractedData?: {             // Transaction extraction
      amount?: number;
      merchant?: string;
      category?: string;
    };
  };

  // NEW: Save transactions directly from chat
  savedTransactionId?: string;
}
```

### 5. sms_transactions

SMS auto-parsing pending confirmations.

```typescript
interface SmsTransaction {
  id: string;
  userId: string;
  smsBody: string;                // Original SMS text
  sender: string;                 // Phone number/name

  parsed: {
    amount: number;
    merchant: string;
    date: Timestamp;
    cardLast4?: string;
    confidence: number;           // 0-1
    suggestedCategory: string;
  };

  status: 'pending' | 'confirmed' | 'rejected' | 'expired';
  confirmedAt?: Timestamp;
  savedTransactionId?: string;    // If confirmed

  receivedAt: Timestamp;
  expiresAt: Timestamp;           // 48 hours
}
```

### 6. money_stories

Daily narrative summaries (generated at 9 PM).

```typescript
interface MoneyStory {
  id: string;
  userId: string;
  date: Timestamp;                // Date of the story

  story: string;                  // Narrative text
  highlights: {
    totalSpent: number;
    totalIncome: number;
    topCategory: string;
    topTransaction: {
      merchant: string;
      amount: number;
    };
    budgetStatus: string;         // "under budget", "on track", etc.
  };

  transactions: string[];         // Transaction IDs included

  generatedAt: Timestamp;
  sentAt?: Timestamp;             // Push notification sent
}
```

### 7. subscriptions

Detected recurring charges.

```typescript
interface Subscription {
  id: string;
  userId: string;
  merchant: string;
  amount: number;
  currency: string;
  frequency: 'weekly' | 'monthly' | 'yearly';

  lastCharge: Timestamp;
  nextExpectedCharge: Timestamp;
  detectedAt: Timestamp;

  transactions: string[];         // Related transaction IDs

  status: 'active' | 'canceled' | 'flagged';
  userConfirmed: boolean;         // User acknowledged it

  metadata: {
    category?: string;
    cancelUrl?: string;           // If found
    savings?: number;             // Potential savings if canceled
  };

  updatedAt: Timestamp;
}
```

### 8. financial_health_scores

Historical tracking of Financial Health Score.

```typescript
interface FinancialHealthScore {
  id: string;
  userId: string;
  calculatedAt: Timestamp;

  score: number;                  // 0-100
  breakdown: {
    budgetAdherence: number;      // 0-25
    savingsRate: number;          // 0-25
    debtManagement: number;       // 0-25
    spendingStability: number;    // 0-25
  };

  factors: {
    positives: string[];          // "Spent $200 less than last month"
    negatives: string[];          // "Over budget on dining"
    recommendations: string[];    // "Try reducing coffee spending by $50"
  };

  trend: 'improving' | 'stable' | 'declining';
  previousScore?: number;
}
```

### 9. smart_nudges

Proactive warnings before spending.

```typescript
interface SmartNudge {
  id: string;
  userId: string;
  type: 'budget_warning' | 'impulse_alert' | 'bill_reminder' | 'savings_opportunity';
  priority: 'high' | 'medium' | 'low';

  title: string;
  message: string;
  data: Record<string, any>;      // Type-specific data

  triggeredBy?: {
    transactionId?: string;
    budgetId?: string;
    pattern?: string;
  };

  action?: {
    label: string;
    type: 'dismiss' | 'view_budget' | 'view_transactions';
    target?: string;
  };

  status: 'active' | 'dismissed' | 'expired';
  generatedAt: Timestamp;
  expiresAt?: Timestamp;
  dismissedAt?: Timestamp;
}
```

### 10. stress_logs

Emotional spending tracking.

```typescript
interface StressLog {
  id: string;
  userId: string;
  timestamp: Timestamp;

  stressLevel: number;            // 1-10 (user reported or inferred)
  trigger?: string;               // "work", "relationship", "health"

  transactions: string[];         // Transactions during stress period
  totalSpent: number;

  aiInsight?: string;             // Analyst Agent observation
  coachingTip?: string;           // Suggested coping mechanism

  createdAt: Timestamp;
}
```

### 11. couple_accounts

Shared financial visibility (Couples Dashboard).

```typescript
interface CoupleAccount {
  id: string;
  users: {
    [userId: string]: {
      name: string;
      role: 'initiator' | 'partner';
      joinedAt: Timestamp;
    };
  };

  sharedBudgets: string[];        // Budget IDs
  sharedCategories: string[];     // Categories both track

  settings: {
    visibility: 'full' | 'summary';  // Full transactions or summary only
    notifyOnLargeSpend: boolean;
    largeSpendThreshold: number;
  };

  // NEW: AI Mediator feature
  conflicts: Array<{
    id: string;
    topic: string;                // "Overspending on dining"
    detectedAt: Timestamp;
    resolvedAt?: Timestamp;
    mediationSummary?: string;    // AI Mediator's advice
  }>;

  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### 12. coaching_tips

Library of contextual coaching tips.

```typescript
interface CoachingTip {
  id: string;
  category: string;               // "budgeting", "impulse", "savings"
  trigger: string;                // "over_budget", "impulse_spending"

  tip: string;                    // Short actionable advice
  longForm?: string;              // Detailed explanation

  tags: string[];
  effectiveness?: number;         // User rating 0-5

  usageCount: number;             // How many times shown
  createdAt: Timestamp;
}
```

### 13. insights

AI-generated insights and recommendations.

```typescript
interface Insight {
  id: string;
  userId: string;
  type: 'achievement' | 'alert' | 'recommendation' | 'trend' | 'anomaly';
  priority: 'high' | 'medium' | 'low';

  title: string;
  message: string;
  data: Record<string, any>;

  category?: string;
  period?: {
    start: Timestamp;
    end: Timestamp;
  };

  action?: {
    label: string;
    type: 'navigate' | 'dismiss';
    target?: string;
  };

  status: 'active' | 'dismissed' | 'expired';
  generatedAt: Timestamp;
  generatedBy: string;            // NEW: 'analyst_agent'
  expiresAt?: Timestamp;
}
```

### 14. watchlist

Price Intelligence (Receipt price tracking).

```typescript
interface WatchlistItem {
  id: string;
  userId: string;
  productName: string;
  barcode?: string;
  category?: string;

  lastPurchase: {
    amount: number;
    merchant: string;
    date: Timestamp;
    transactionId: string;
  };

  priceHistory: Array<{
    amount: number;
    merchant: string;
    date: Timestamp;
  }>;

  marketAverage?: number;         // Calculated from all users
  savings?: number;               // Difference from average

  alertEnabled: boolean;
  addedAt: Timestamp;
  updatedAt: Timestamp;
}
```

### 15. notifications

Push notifications log.

```typescript
interface Notification {
  id: string;
  userId: string;
  type: 'money_story' | 'budget' | 'subscription' | 'nudge' | 'system';
  priority: 'high' | 'medium' | 'low';

  title: string;
  body: string;
  data?: Record<string, any>;

  action?: {
    label: string;
    target: string;
  };

  read: boolean;
  readAt?: Timestamp;

  sentAt: Timestamp;
  expiresAt?: Timestamp;
}
```

### 16. user_patterns

ML-generated spending patterns (Pattern Learner Agent).

```typescript
interface UserPattern {
  userId: string;                 // Document ID
  updatedAt: Timestamp;

  spendingPatterns: {
    [category: string]: {
      avgAmount: number;
      frequency: number;          // Txns per month
      commonMerchants: string[];
      peakDays: number[];         // Day of week (0-6)
      peakTimes: number[];        // Hour (0-23)
      trend: 'increasing' | 'stable' | 'decreasing';
    };
  };

  budgetTrends: {
    adherenceRate: number;        // 0-100
    overSpendCategories: string[];
    avgMonthlySpend: number;
    monthlyIncomeEstimate?: number;
  };

  // NEW: Emotional spending patterns
  emotionalPatterns?: {
    stressSpendingTriggers: string[];
    impulseCategories: string[];
    avgStressSpend: number;
  };

  anomalies: Array<{
    transactionId: string;
    type: string;                 // "large_purchase", "unusual_time"
    severity: number;             // 0-1
    detectedAt: Timestamp;
  }>;
}
```

---

## Firestore Indexes

```javascript
{
  "indexes": [
    // Transactions by user and date
    {
      "collectionGroup": "transactions",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    // Transactions by user, category, date
    {
      "collectionGroup": "transactions",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    // SMS transactions by user and status
    {
      "collectionGroup": "sms_transactions",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "receivedAt", "order": "DESCENDING" }
      ]
    },
    // Money stories by user and date
    {
      "collectionGroup": "money_stories",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    // Subscriptions by user and status
    {
      "collectionGroup": "subscriptions",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "nextExpectedCharge", "order": "ASCENDING" }
      ]
    },
    // Smart nudges by user and status
    {
      "collectionGroup": "smart_nudges",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "generatedAt", "order": "DESCENDING" }
      ]
    },
    // Insights by user, status, priority
    {
      "collectionGroup": "insights",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "priority", "order": "DESCENDING" },
        { "fieldPath": "generatedAt", "order": "DESCENDING" }
      ]
    },
    // Watchlist by user
    {
      "collectionGroup": "watchlist",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "alertEnabled", "order": "ASCENDING" }
      ]
    }
  ]
}
```

---

## Flutter Data Models

### Transaction Model

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String category;
  final TransactionType type;
  final String? merchant;
  final String? description;
  final DateTime date;
  final String? paymentMethod;
  final TransactionMetadata metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.category,
    required this.type,
    this.merchant,
    this.description,
    required this.date,
    this.paymentMethod,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      userId: data['userId'],
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'],
      category: data['category'],
      type: TransactionType.values.byName(data['type']),
      merchant: data['merchant'],
      description: data['description'],
      date: (data['date'] as Timestamp).toDate(),
      paymentMethod: data['paymentMethod'],
      metadata: TransactionMetadata.fromMap(data['metadata']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'category': category,
      'type': type.name,
      'merchant': merchant,
      'description': description,
      'date': Timestamp.fromDate(date),
      'paymentMethod': paymentMethod,
      'metadata': metadata.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

enum TransactionType { expense, income }

class TransactionMetadata {
  final String source;
  final double? confidence;
  final bool verified;
  final bool edited;
  final String? aiAgent;

  TransactionMetadata({
    required this.source,
    this.confidence,
    required this.verified,
    required this.edited,
    this.aiAgent,
  });

  factory TransactionMetadata.fromMap(Map<String, dynamic> map) {
    return TransactionMetadata(
      source: map['source'],
      confidence: map['confidence'],
      verified: map['verified'],
      edited: map['edited'],
      aiAgent: map['aiAgent'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'confidence': confidence,
      'verified': verified,
      'edited': edited,
      'aiAgent': aiAgent,
    };
  }
}
```

### Money Story Model

```dart
class MoneyStory {
  final String id;
  final String userId;
  final DateTime date;
  final String story;
  final MoneyStoryHighlights highlights;
  final List<String> transactions;
  final DateTime generatedAt;

  MoneyStory({
    required this.id,
    required this.userId,
    required this.date,
    required this.story,
    required this.highlights,
    required this.transactions,
    required this.generatedAt,
  });

  factory MoneyStory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoneyStory(
      id: doc.id,
      userId: data['userId'],
      date: (data['date'] as Timestamp).toDate(),
      story: data['story'],
      highlights: MoneyStoryHighlights.fromMap(data['highlights']),
      transactions: List<String>.from(data['transactions']),
      generatedAt: (data['generatedAt'] as Timestamp).toDate(),
    );
  }
}

class MoneyStoryHighlights {
  final double totalSpent;
  final double totalIncome;
  final String topCategory;
  final String budgetStatus;

  MoneyStoryHighlights({
    required this.totalSpent,
    required this.totalIncome,
    required this.topCategory,
    required this.budgetStatus,
  });

  factory MoneyStoryHighlights.fromMap(Map<String, dynamic> map) {
    return MoneyStoryHighlights(
      totalSpent: (map['totalSpent'] as num).toDouble(),
      totalIncome: (map['totalIncome'] as num).toDouble(),
      topCategory: map['topCategory'],
      budgetStatus: map['budgetStatus'],
    );
  }
}
```

### SMS Transaction Model

```dart
class SmsTransaction {
  final String id;
  final String userId;
  final String smsBody;
  final String sender;
  final SmsTransactionParsed parsed;
  final SmsTransactionStatus status;
  final DateTime receivedAt;
  final DateTime expiresAt;

  SmsTransaction({
    required this.id,
    required this.userId,
    required this.smsBody,
    required this.sender,
    required this.parsed,
    required this.status,
    required this.receivedAt,
    required this.expiresAt,
  });

  factory SmsTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SmsTransaction(
      id: doc.id,
      userId: data['userId'],
      smsBody: data['smsBody'],
      sender: data['sender'],
      parsed: SmsTransactionParsed.fromMap(data['parsed']),
      status: SmsTransactionStatus.values.byName(data['status']),
      receivedAt: (data['receivedAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }
}

class SmsTransactionParsed {
  final double amount;
  final String merchant;
  final DateTime date;
  final String? cardLast4;
  final double confidence;
  final String suggestedCategory;

  SmsTransactionParsed({
    required this.amount,
    required this.merchant,
    required this.date,
    this.cardLast4,
    required this.confidence,
    required this.suggestedCategory,
  });

  factory SmsTransactionParsed.fromMap(Map<String, dynamic> map) {
    return SmsTransactionParsed(
      amount: (map['amount'] as num).toDouble(),
      merchant: map['merchant'],
      date: (map['date'] as Timestamp).toDate(),
      cardLast4: map['cardLast4'],
      confidence: (map['confidence'] as num).toDouble(),
      suggestedCategory: map['suggestedCategory'],
    );
  }
}

enum SmsTransactionStatus { pending, confirmed, rejected, expired }
```

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isValidTransaction() {
      let data = request.resource.data;
      return data.amount > 0
        && data.currency is string
        && data.category is string
        && data.userId == request.auth.uid;
    }

    // Users
    match /users/{userId} {
      allow read, write: if isOwner(userId);
    }

    // Transactions
    match /transactions/{transactionId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() && isValidTransaction();
      allow update, delete: if isOwner(resource.data.userId);
    }

    // Budgets
    match /budgets/{budgetId} {
      allow read, write: if isOwner(resource.data.userId);
    }

    // Chat Messages
    match /chat_messages/{messageId} {
      allow read, write: if isOwner(resource.data.userId);
    }

    // SMS Transactions
    match /sms_transactions/{smsId} {
      allow read, write: if isOwner(resource.data.userId);
    }

    // Money Stories (read-only for users)
    match /money_stories/{storyId} {
      allow read: if isOwner(resource.data.userId);
      allow write: if false; // Only Cloud Functions
    }

    // Subscriptions
    match /subscriptions/{subscriptionId} {
      allow read, write: if isOwner(resource.data.userId);
    }

    // Financial Health Scores (read-only for users)
    match /financial_health_scores/{scoreId} {
      allow read: if isOwner(resource.data.userId);
      allow write: if false; // Only Cloud Functions
    }

    // Smart Nudges
    match /smart_nudges/{nudgeId} {
      allow read, update: if isOwner(resource.data.userId);
      allow create: if false; // Only Cloud Functions
    }

    // Stress Logs
    match /stress_logs/{logId} {
      allow read, write: if isOwner(resource.data.userId);
    }

    // Couple Accounts
    match /couple_accounts/{accountId} {
      allow read: if isAuthenticated() &&
                     resource.data.users[request.auth.uid] != null;
      allow write: if isAuthenticated() &&
                      request.resource.data.users[request.auth.uid] != null;
    }

    // Coaching Tips (read-only)
    match /coaching_tips/{tipId} {
      allow read: if isAuthenticated();
      allow write: if false; // Admin only
    }

    // Insights
    match /insights/{insightId} {
      allow read, update: if isOwner(resource.data.userId);
      allow create: if false; // Only Cloud Functions
    }

    // Watchlist
    match /watchlist/{itemId} {
      allow read, write: if isOwner(resource.data.userId);
    }

    // Notifications
    match /notifications/{notificationId} {
      allow read, update: if isOwner(resource.data.userId);
      allow create: if isAuthenticated();
    }

    // User Patterns (read-only for users)
    match /user_patterns/{userId} {
      allow read: if isOwner(userId);
      allow write: if false; // Only Cloud Functions
    }
  }
}
```

---

## Summary of v3 Changes

| Collection | Status | Purpose |
|------------|--------|---------|
| users | Updated | Added SMS permission, financial health, couple account |
| transactions | Updated | Added SMS source, AI agent tracking, price comparison |
| chat_messages | Simplified | Removed sessions, added saved transaction linking |
| sms_transactions | NEW | SMS auto-parsing pending confirmations |
| money_stories | NEW | Daily 9 PM narrative summaries |
| subscriptions | NEW | Recurring charge detection |
| financial_health_scores | NEW | Historical 0-100 score tracking |
| smart_nudges | NEW | Proactive warnings |
| stress_logs | NEW | Emotional spending tracking |
| couple_accounts | NEW | Couples Dashboard feature |
| coaching_tips | NEW | Contextual coaching library |

**Total Collections:** 16 (up from 8 in v2)

**End of DATA_MODELS.md**

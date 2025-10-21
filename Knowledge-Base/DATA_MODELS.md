# Fin Copilot v2 - Data Models
## Complete Database Schema & Data Structures

**Document Version:** 1.0
**Last Updated:** October 21, 2025

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
    currency: string;             // ISO 4217 (USD, EUR, etc.)
    locale: string;               // en-US, en-GB, etc.
    timezone: string;             // America/Los_Angeles
    theme: 'light' | 'dark' | 'system';
    notificationsEnabled: boolean;
  };

  settings: {
    budgetAlertThreshold: number; // 0-100 (percentage)
    monthlyBudget?: number;
    categories: string[];         // Custom categories
    defaultPaymentMethod?: string;
  };

  onboarding: {
    completed: boolean;
    step: number;
    completedAt?: Timestamp;
  };

  subscription?: {
    tier: 'free' | 'premium';
    status: 'active' | 'canceled' | 'expired';
    expiresAt?: Timestamp;
  };
}
```

### 2. transactions

```typescript
interface Transaction {
  id: string;                     // Auto-generated
  userId: string;                 // Owner reference
  amount: number;                 // Always positive
  currency: string;               // ISO 4217
  category: string;               // From predefined or custom
  type: 'expense' | 'income';     // Transaction type
  merchant?: string;
  description?: string;
  notes?: string;
  tags?: string[];

  date: Timestamp;                // Transaction date
  time?: string;                  // HH:MM format

  paymentMethod?: string;         // card, cash, digital_wallet
  paymentDetails?: {
    cardLast4?: string;
    cardBrand?: string;
    account?: string;
  };

  receipt?: {
    imageUrl: string;             // Firebase Storage path
    thumbnailUrl?: string;
    uploadedAt: Timestamp;
    parsedData?: ReceiptData;
  };

  location?: {
    latitude: number;
    longitude: number;
    address?: string;
  };

  metadata: {
    source: 'manual' | 'voice' | 'chat' | 'receipt' | 'import';
    confidence?: number;          // AI extraction confidence
    verified: boolean;            // User confirmed
    edited: boolean;
    editHistory?: EditRecord[];
  };

  createdAt: Timestamp;
  updatedAt: Timestamp;
  deletedAt?: Timestamp;          // Soft delete
}

interface ReceiptData {
  items: Array<{
    description: string;
    quantity: number;
    unitPrice: number;
    totalPrice: number;
    category?: string;
  }>;
  subtotal: number;
  tax: number;
  tip?: number;
  total: number;
}

interface EditRecord {
  field: string;
  oldValue: any;
  newValue: any;
  timestamp: Timestamp;
}
```

### 3. budgets

```typescript
interface Budget {
  id: string;
  userId: string;
  name: string;
  type: 'monthly' | 'weekly' | 'custom';

  amount: number;                 // Total budget amount
  currency: string;

  period: {
    start: Timestamp;
    end: Timestamp;
    recurring: boolean;
  };

  categories?: {
    [category: string]: {
      budgeted: number;
      spent: number;              // Calculated field
      percentage: number;
    };
  };

  totalSpent: number;             // Calculated field
  alerts: {
    enabled: boolean;
    thresholds: number[];         // [75, 90, 100]
    lastAlertAt?: Timestamp;
  };

  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### 4. insights

```typescript
interface Insight {
  id: string;
  userId: string;
  type: 'achievement' | 'alert' | 'recommendation' | 'trend';
  priority: 'high' | 'medium' | 'low';

  title: string;
  message: string;
  data: Record<string, any>;      // Type-specific data

  category?: string;
  period?: {
    start: Timestamp;
    end: Timestamp;
  };

  action?: {
    label: string;
    type: 'navigate' | 'external' | 'dismiss';
    target?: string;
  };

  status: 'active' | 'dismissed' | 'expired';
  generatedAt: Timestamp;
  expiresAt?: Timestamp;
  dismissedAt?: Timestamp;
}
```

### 5. watchlist (Price Intelligence)

```typescript
interface WatchlistItem {
  id: string;
  userId: string;
  productId: string;              // Barcode or unique ID
  productName: string;
  imageUrl?: string;
  category?: string;

  currentPrice: number;
  currency: string;
  targetPrice: number;

  priority: 'high' | 'medium' | 'low';
  alertEnabled: boolean;

  priceHistory: Array<{
    price: number;
    source: string;
    date: Timestamp;
  }>;

  notes?: string;
  tags?: string[];

  addedAt: Timestamp;
  lastChecked?: Timestamp;
  updatedAt: Timestamp;
}
```

### 6. notifications

```typescript
interface Notification {
  id: string;
  userId: string;
  type: 'budget' | 'price' | 'insight' | 'system';
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

### 7. chat_history

```typescript
interface ChatSession {
  id: string;
  userId: string;
  title?: string;                 // Auto-generated or user-set

  messages: ChatMessage[];

  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastMessageAt: Timestamp;
}

interface ChatMessage {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: Timestamp;

  metadata?: {
    intent?: string;
    confidence?: number;
    agentsUsed?: string[];
    extractedData?: any;
  };
}
```

### 8. user_patterns (ML Data)

```typescript
interface UserPattern {
  userId: string;                 // Document ID
  updatedAt: Timestamp;

  spendingPatterns: {
    [category: string]: {
      avgAmount: number;
      frequency: number;          // Transactions per month
      commonMerchants: string[];
      peakDays: number[];         // Day of week (0-6)
      peakTimes: number[];        // Hour of day (0-23)
    };
  };

  budgetTrends: {
    adherenceRate: number;        // 0-100
    commonOverspendCategories: string[];
    avgMonthlySpend: number;
  };

  merchants: {
    [merchant: string]: {
      visits: number;
      totalSpent: number;
      avgAmount: number;
      categories: string[];
    };
  };

  anomalies: Array<{
    transactionId: string;
    type: string;
    severity: number;
    detectedAt: Timestamp;
  }>;
}
```

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
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

    // Insights
    match /insights/{insightId} {
      allow read, write: if isOwner(resource.data.userId);
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

    // Chat History
    match /chat_history/{sessionId} {
      allow read, write: if isOwner(resource.data.userId);
    }

    // User Patterns (ML data)
    match /user_patterns/{userId} {
      allow read: if isOwner(userId);
      allow write: if false;  // Only backend can write
    }
  }
}
```

---

## Firestore Indexes

```javascript
// Required composite indexes
{
  "indexes": [
    {
      "collectionGroup": "transactions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "transactions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "budgets",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "period.start", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "insights",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "generatedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "watchlist",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "alertEnabled", "order": "ASCENDING" },
        { "fieldPath": "lastChecked", "order": "ASCENDING" }
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
  final String? notes;
  final List<String>? tags;
  final DateTime date;
  final String? time;
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
    this.notes,
    this.tags,
    required this.date,
    this.time,
    this.paymentMethod,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      userId: data['userId'] as String,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String,
      category: data['category'] as String,
      type: TransactionType.values.byName(data['type'] as String),
      merchant: data['merchant'] as String?,
      description: data['description'] as String?,
      notes: data['notes'] as String?,
      tags: (data['tags'] as List?)?.cast<String>(),
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] as String?,
      paymentMethod: data['paymentMethod'] as String?,
      metadata: TransactionMetadata.fromMap(data['metadata'] as Map<String, dynamic>),
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
      'notes': notes,
      'tags': tags,
      'date': Timestamp.fromDate(date),
      'time': time,
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

  TransactionMetadata({
    required this.source,
    this.confidence,
    required this.verified,
    required this.edited,
  });

  factory TransactionMetadata.fromMap(Map<String, dynamic> map) {
    return TransactionMetadata(
      source: map['source'] as String,
      confidence: map['confidence'] as double?,
      verified: map['verified'] as bool,
      edited: map['edited'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'confidence': confidence,
      'verified': verified,
      'edited': edited,
    };
  }
}
```

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-21 | Claude (AI Research) | Initial data models |

**End of DATA_MODELS.md**

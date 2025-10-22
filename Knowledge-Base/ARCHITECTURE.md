# Fin Copilot v3 - Technical Architecture

**Last Updated:** October 22, 2025
**Version:** 3.0 (Simplified 3-Agent System)

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Technology Stack](#technology-stack)
3. [System Architecture](#system-architecture)
4. [Frontend Architecture](#frontend-architecture)
5. [Backend Architecture](#backend-architecture)
6. [AI Infrastructure](#ai-infrastructure)
7. [Data Flow](#data-flow)
8. [Security Architecture](#security-architecture)
9. [Performance Targets](#performance-targets)
10. [Deployment Strategy](#deployment-strategy)

---

## Architecture Overview

### Design Principles

**1. Radical Simplification**
- 3 agents vs 9 agents (5x cost reduction, 3x faster)
- Direct function calling, no orchestration overhead
- Financial Copilot Agent handles 80% of interactions

**2. Serverless-First**
- Firebase Cloud Functions for backend
- Auto-scaling, pay-per-use
- Global edge distribution

**3. Offline-Capable**
- Firestore offline persistence
- Queue-based sync when online
- Optimistic UI updates

**4. SMS Auto-Parsing**
- Background monitoring (sms_advanced package)
- 80% automatic transaction capture
- One-tap confirmation notifications

**5. Security by Design**
- Biometric authentication
- AES-256 encryption at rest
- TLS 1.3 in transit
- Firestore security rules

---

## Technology Stack

### Frontend

```yaml
Platform: Flutter 3.32+
Language: Dart 3.8+

Core Packages:
  firebase_ai: ^3.4.0              # Gemini AI Logic
  firebase_core: ^3.6.0
  firebase_auth: ^5.7.0
  cloud_firestore: ^5.4.4

State Management:
  riverpod: ^3.0.0

Navigation:
  go_router: ^15.1.2

UI:
  Material Design 3
  fl_chart: ^0.68.0                # Charts

Key Features:
  mobile_scanner: ^5.2.3           # Receipt scanning
  speech_to_text: ^7.3.0           # Voice input
  flutter_local_notifications      # Push notifications
  sms_advanced: ^1.1.1             # SMS monitoring
  flutter_secure_storage: ^9.2.2   # Secure storage
  image_picker: ^1.1.2             # Camera access
```

### Backend

```yaml
Platform: Firebase + Google Cloud

Database:
  - Cloud Firestore (NoSQL, real-time sync)
  - Composite indexes for optimized queries

Functions:
  - Cloud Functions (Node.js 20)
  - Scheduled functions (cron jobs)
  - Firestore triggers

AI:
  - Firebase AI Logic (firebase_ai)
  - Gemini 2.5 Flash (primary)
  - Gemini 2.5 Flash-Lite (OCR)
  - Function calling for data access

Storage:
  - Firebase Storage (receipts, exports)

Authentication:
  - Firebase Authentication
  - Email/password, Google, Apple, Biometric

Monitoring:
  - Firebase Crashlytics
  - Firebase Performance Monitoring
  - Cloud Logging
```

---

## System Architecture

### High-Level Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   FLUTTER APPLICATION                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  iOS/Android │  │     Web      │  │   Desktop    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                               │
│  Features:                                                   │
│  • Voice/Text Chat  • SMS Monitoring  • Receipt Scanning   │
│  • Budget Tracking  • Insights        • Price Intelligence │
└─────────────────────────────────────────────────────────────┘
                           ↕
                   ┌───────────────┐
                   │  Firebase AI  │
                   │  Logic Layer  │
                   └───────────────┘
                           ↕
┌─────────────────────────────────────────────────────────────┐
│                    AI AGENTS (3 Total)                       │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  FINANCIAL COPILOT AGENT (Gemini 2.5 Flash)          │ │
│  │  • Main intelligence (80% of interactions)            │ │
│  │  • Transaction extraction + validation in 1 call      │ │
│  │  • Multi-turn conversations with context             │ │
│  │  • Function calling: saveTransaction, getBudget, etc. │ │
│  │  • Emotional intelligence & anxiety reduction         │ │
│  └───────────────────────────────────────────────────────┘ │
│                           ↓                                   │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  VISION AGENT (Gemini 2.5 Flash-Lite)                │ │
│  │  • Receipt OCR only (15% of interactions)            │ │
│  │  • Extract items, prices, merchant, date              │ │
│  │  • Pass to Copilot for price analysis                │ │
│  └───────────────────────────────────────────────────────┘ │
│                           ↓                                   │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  ANALYST AGENT (Gemini 2.5 Flash)                    │ │
│  │  • Background analysis (5% of interactions)           │ │
│  │  • Daily Money Story (9 PM scheduled)                │ │
│  │  • Weekly Pattern Analysis (Sunday 8 PM)             │ │
│  │  • Anomaly Detection (Firestore triggers)            │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────────┐
│              CLOUD FUNCTIONS (Serverless)                    │
│                                                               │
│  Scheduled Functions:                                        │
│  • generateMoneyStory()      - Daily 9 PM                   │
│  • weeklyAnalysis()          - Sunday 8 PM                  │
│  • budgetAlerts()            - Daily 8 AM                   │
│  • subscriptionDetection()   - Weekly                       │
│                                                               │
│  Firestore Triggers:                                         │
│  • onTransactionCreate()     - Anomaly detection            │
│  • onBudgetUpdate()          - Smart nudges                 │
│  • onUserSignup()            - Initialize user data         │
└─────────────────────────────────────────────────────────────┘
                           ↕
                   ┌───────────────┐
                   │   FIRESTORE   │
                   │   DATABASE    │
                   └───────────────┘
```

### Why 3 Agents Work

**OLD (9 agents):**
- Orchestrator → Extractor → Validator → Context → Response
- 4 sequential API calls for 1 transaction
- 3-5 seconds total
- $0.004 cost per transaction

**NEW (3 agents):**
- Financial Copilot does extraction + validation + context in 1 call
- 1 API call for 1 transaction
- <1 second total
- $0.0008 cost per transaction

**Result:** 5x cheaper, 3x faster, simpler codebase

---

## Frontend Architecture

### App Structure

```
lib/
├── main.dart
├── firebase_options.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── categories.dart
│   │   └── routes.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── color_schemes.dart
│   │   └── text_styles.dart
│   └── utils/
│       ├── currency_utils.dart
│       ├── date_utils.dart
│       └── validators.dart
│
├── features/
│   ├── authentication/
│   │   ├── data/repositories/
│   │   ├── domain/use_cases/
│   │   └── presentation/
│   │       ├── screens/
│   │       └── providers/
│   │
│   ├── chat/                      # Financial Copilot Chat
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── chat_repository.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── chat_screen.dart
│   │       ├── widgets/
│   │       │   ├── message_bubble.dart
│   │       │   ├── voice_input_button.dart
│   │       │   └── transaction_confirmation.dart
│   │       └── providers/
│   │           └── chat_provider.dart
│   │
│   ├── transactions/
│   ├── budgets/
│   ├── insights/
│   ├── receipt_scanner/
│   ├── price_intelligence/
│   └── dashboard/
│
├── services/
│   ├── firebase/
│   │   ├── firestore_service.dart
│   │   ├── auth_service.dart
│   │   └── storage_service.dart
│   ├── ai/
│   │   ├── financial_copilot_service.dart    # Main AI service
│   │   ├── vision_service.dart               # Receipt OCR
│   │   └── analyst_service.dart              # Background insights
│   ├── sms/
│   │   └── sms_parser_service.dart           # SMS monitoring
│   └── notifications/
│       └── notification_service.dart
│
└── shared/
    ├── models/
    │   ├── transaction.dart
    │   ├── budget.dart
    │   ├── chat_message.dart
    │   └── money_story.dart
    ├── widgets/
    └── providers/
```

### State Management (Riverpod)

```dart
// Financial Copilot Chat Provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final chatMessagesProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repository);
});

final transactionExtractionProvider =
    FutureProvider.family<TransactionData, String>((ref, userMessage) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.extractTransaction(userMessage);
});

// SMS Monitoring Provider
final smsParserProvider = Provider<SmsParserService>((ref) {
  return SmsParserService();
});

final pendingTransactionsProvider =
    StreamProvider<List<ParsedSmsTransaction>>((ref) {
  final parser = ref.watch(smsParserProvider);
  return parser.pendingTransactionsStream;
});
```

---

## Backend Architecture

### Cloud Functions Structure

```
functions/
├── package.json
├── tsconfig.json
├── index.ts                       # Exports all functions
│
├── scheduled/
│   ├── daily-money-story.ts       # 9 PM daily
│   ├── weekly-analysis.ts         # Sunday 8 PM
│   ├── budget-alerts.ts           # 8 AM daily
│   └── subscription-detection.ts  # Weekly
│
├── triggers/
│   ├── on-transaction-create.ts   # Anomaly detection
│   ├── on-budget-update.ts        # Smart nudges
│   └── on-user-signup.ts          # Initialize user
│
├── services/
│   ├── firestore.service.ts
│   ├── ai.service.ts
│   └── notification.service.ts
│
└── utils/
    ├── prompts.ts                 # Agent system prompts
    └── helpers.ts
```

### Cloud Function Examples

```typescript
// scheduled/daily-money-story.ts
import * as functions from 'firebase-functions';
import { GenerativeModel } from '@google-cloud/vertexai';
import { getFirestore } from 'firebase-admin/firestore';

export const generateMoneyStory = functions.pubsub
  .schedule('0 21 * * *')           // 9 PM daily
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const db = getFirestore();
    const users = await getActiveUsers();

    const model = new GenerativeModel({
      model: 'gemini-2.5-flash',
      systemInstruction: ANALYST_AGENT_PROMPT,
    });

    for (const user of users) {
      // Get today's transactions
      const txns = await db
        .collection('transactions')
        .where('userId', '==', user.id)
        .where('date', '>=', getTodayStart())
        .get();

      // Generate Money Story
      const story = await model.generateContent({
        contents: [{
          role: 'user',
          parts: [{
            text: `Generate Money Story for: ${JSON.stringify(txns)}`
          }]
        }]
      });

      // Send notification
      await sendNotification(user.id, {
        title: 'Today\'s Money Story 📖',
        body: story.response.text(),
      });
    }
  });

// triggers/on-transaction-create.ts
export const detectAnomalies = functions.firestore
  .document('transactions/{transactionId}')
  .onCreate(async (snap, context) => {
    const txn = snap.data();
    const db = getFirestore();

    // Get user's transaction history (last 30 days)
    const history = await db
      .collection('transactions')
      .where('userId', '==', txn.userId)
      .where('date', '>=', getLast30Days())
      .get();

    const model = new GenerativeModel({
      model: 'gemini-2.5-flash',
      systemInstruction: ANALYST_AGENT_PROMPT,
    });

    // Detect anomalies
    const analysis = await model.generateContent({
      contents: [{
        role: 'user',
        parts: [{
          text: `Check for anomalies:\nNew: ${JSON.stringify(txn)}\nHistory: ${JSON.stringify(history)}`
        }]
      }],
      generationConfig: {
        responseMimeType: 'application/json',
      }
    });

    const result = JSON.parse(analysis.response.text());

    if (result.anomalyDetected) {
      await sendAlert(txn.userId, {
        title: 'Unusual Transaction',
        body: result.message,
      });
    }
  });
```

---

## AI Infrastructure

### Agent Configuration

| Agent | Model | Temperature | Max Tokens | Use Case |
|-------|-------|-------------|------------|----------|
| Financial Copilot | Gemini 2.5 Flash | 0.7 | 512 | Main chat, extraction, advice |
| Vision | Gemini 2.5 Flash-Lite | 0.2 | 2048 | Receipt OCR |
| Analyst | Gemini 2.5 Flash | 0.4 | 1024 | Background analysis |

### Function Calling (Financial Copilot Agent)

```typescript
// Available functions for Financial Copilot Agent
const functionDeclarations = [
  {
    name: 'saveTransaction',
    description: 'Save a transaction to Firestore',
    parameters: {
      type: 'object',
      properties: {
        amount: { type: 'number', description: 'Transaction amount' },
        merchant: { type: 'string', description: 'Merchant name' },
        category: { type: 'string', description: 'Category' },
        date: { type: 'string', description: 'ISO date string' },
        description: { type: 'string', description: 'Optional notes' },
      },
      required: ['amount', 'category', 'date']
    }
  },
  {
    name: 'getTransactions',
    description: 'Query transactions',
    parameters: {
      type: 'object',
      properties: {
        startDate: { type: 'string' },
        endDate: { type: 'string' },
        category: { type: 'string' },
      },
      required: ['startDate', 'endDate']
    }
  },
  {
    name: 'getBudget',
    description: 'Get budget info for category',
    parameters: {
      type: 'object',
      properties: {
        category: { type: 'string' }
      },
      required: ['category']
    }
  },
  {
    name: 'getCurrentBalance',
    description: 'Get current cash balance',
    parameters: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'getPredictedCashFlow',
    description: 'Get cash flow prediction',
    parameters: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'getSpendingPatterns',
    description: 'Get spending patterns',
    parameters: {
      type: 'object',
      properties: {
        category: { type: 'string' },
        timeframe: { type: 'string', enum: ['week', 'month'] }
      },
      required: ['category', 'timeframe']
    }
  }
];
```

### Flutter AI Service

```dart
// lib/services/ai/financial_copilot_service.dart
import 'package:firebase_ai/firebase_ai.dart';

class FinancialCopilotService {
  late final GenerativeModel _model;

  FinancialCopilotService() {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(COPILOT_SYSTEM_PROMPT),
      tools: [
        Tool(functionDeclarations: [
          FunctionDeclaration(
            name: 'saveTransaction',
            description: 'Save a transaction to Firestore',
            parameters: {...}
          ),
          // ... other function declarations
        ])
      ],
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 512,
      ),
    );
  }

  Future<String> sendMessage(String userMessage, ChatHistory history) async {
    // Build conversation with history
    final contents = [
      ...history.map((msg) => Content.text(msg)),
      Content.text(userMessage),
    ];

    // Generate response (may include function calls)
    final response = await _model.generateContent(contents);

    // Handle function calls if any
    if (response.functionCalls != null) {
      for (final call in response.functionCalls!) {
        await _executeFunctionCall(call);
      }
    }

    return response.text ?? '';
  }

  Future<void> _executeFunctionCall(FunctionCall call) async {
    switch (call.name) {
      case 'saveTransaction':
        await _firestoreService.saveTransaction(call.args);
        break;
      case 'getTransactions':
        final txns = await _firestoreService.getTransactions(call.args);
        // Return to model for next turn
        break;
      // ... other functions
    }
  }
}
```

---

## Data Flow

### Transaction Entry via Voice

```
User taps microphone button
    ↓
Flutter: speech_to_text starts
    ↓
User: "I spent $15 on lunch at Chipotle"
    ↓
Flutter: Convert speech → text
    ↓
Call FinancialCopilotService.sendMessage()
    ↓
Firebase AI: Gemini 2.5 Flash receives message
    ↓
Copilot Agent:
  - Extracts: amount=$15, merchant=Chipotle, category=Dining
  - Validates: all required fields present
  - Calls saveTransaction() function
    ↓
Flutter: Executes function call → Save to Firestore
    ↓
Copilot Agent: Generates response
  "Got it! $15 for lunch at Chipotle 🌯 That's $45 on dining this week"
    ↓
Flutter: Display response in chat
    ↓
Done (1 agent, <1 second)
```

### Receipt Scanning

```
User taps "Scan Receipt"
    ↓
Flutter: Open camera (image_picker)
    ↓
User captures receipt photo
    ↓
Call VisionService.scanReceipt(imageBytes)
    ↓
Vision Agent (Gemini 2.5 Flash-Lite):
  - OCR extracts all items, prices, merchant, date
  - Returns JSON
    ↓
Call FinancialCopilotService.analyzeReceipt(receiptData)
    ↓
Copilot Agent:
  - Compares prices to market averages
  - Generates insights
  "You paid $4.99 for milk - $1.20 more than Trader Joe's"
    ↓
Flutter: Display receipt breakdown + price analysis
    ↓
Done (2 agents, <5 seconds)
```

### SMS Auto-Parsing

```
Bank sends SMS: "Charged $5.50 at STARBUCKS on 10/22"
    ↓
Android: SMS received (SmsReceiver)
    ↓
SmsParserService:
  - Detect bank SMS format
  - Extract: amount=$5.50, merchant=Starbucks, date=10/22
    ↓
Call FinancialCopilotService.confirmTransaction(parsedData)
    ↓
Copilot Agent:
  - Auto-categorizes: Coffee
  - Generates confirmation message
    ↓
Show notification: "☕ $5.50 at Starbucks - Coffee? [YES] [NO]"
    ↓
User taps YES
    ↓
Save to Firestore
    ↓
Done (80% automatic, <2 seconds)
```

### Daily Money Story (Background)

```
9 PM daily (Cloud Function scheduled)
    ↓
generateMoneyStory() function runs
    ↓
For each active user:
  - Query today's transactions from Firestore
  - Call Analyst Agent (Gemini 2.5 Flash)
  - Generate narrative Money Story
  - Send push notification
    ↓
User receives notification:
  "Today's Money Story 📖
   You spent $87 today
   • $5.50 - Coffee ☕ Starbucks
   • $15 - Lunch 🌯 Chipotle
   • $66.50 - Groceries 🛒 Whole Foods

   Top category: Groceries ($66.50)
   This week: $342

   You're $58 under budget this week! Keep it up! 🎉"
    ↓
Done (background, doesn't block user)
```

---

## Security Architecture

### Authentication Flow

1. User opens app
2. Check Firebase Auth session
3. If no session → Sign In screen
4. User chooses: Email/Password, Google, Apple, or Biometric
5. Firebase Auth validates
6. On success:
   - Store ID token in flutter_secure_storage
   - Set up Firestore listeners
   - Navigate to Dashboard

### Data Encryption

**At Rest:**
- Firestore: AES-256 (default)
- Firebase Storage: AES-256 (default)
- Local storage: flutter_secure_storage (platform Keychain/Keystore)

**In Transit:**
- All connections: TLS 1.3
- Firebase AI calls: HTTPS with API key auth

### Firestore Security Rules

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

    match /users/{userId} {
      allow read, write: if isOwner(userId);
    }

    match /transactions/{transactionId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() &&
                       request.resource.data.userId == request.auth.uid;
      allow update, delete: if isOwner(resource.data.userId);
    }

    match /budgets/{budgetId} {
      allow read, write: if isOwner(resource.data.userId);
    }

    match /money_stories/{storyId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if false; // Only Cloud Functions
    }

    match /subscriptions/{subscriptionId} {
      allow read, write: if isOwner(resource.data.userId);
    }
  }
}
```

---

## Performance Targets

| Metric | Target | How Measured |
|--------|--------|--------------|
| App Launch | <2 sec | Firebase Performance |
| AI Response (simple) | <1 sec | Cloud Trace |
| Voice Input Processing | <3 sec | Custom trace |
| Receipt OCR | <5 sec | Cloud Trace |
| SMS Auto-Parse | <2 sec | Custom trace |
| Transaction List Load | <1 sec (100 items) | Firebase Performance |
| Firestore Query | <500 ms | Firebase Console |
| API Success Rate | >99.5% | Cloud Monitoring |
| Crash Rate | <0.5% | Firebase Crashlytics |

### Optimization Strategies

**Frontend:**
- Lazy loading routes (go_router)
- Pagination (50 items/page)
- Image caching (cached_network_image)
- ListView.builder for virtual scrolling
- Local cache with expiration (1 hour)

**Backend:**
- Cloud Functions auto-scale
- Firestore composite indexes
- Denormalization for read-heavy data
- Batch writes (max 500)

**AI:**
- Function calling reduces round trips
- Response caching (1-hour TTL)
- Rate limiting (10 requests/min per user)

---

## Deployment Strategy

### Environments

| Environment | Firebase Project | Gemini API | Purpose |
|-------------|------------------|------------|---------|
| Development | fin-copilot-dev | Developer API (free) | Local testing |
| Staging | fin-copilot-staging | Vertex AI (quota) | Pre-production |
| Production | fin-copilot-prod | Vertex AI (full) | Live users |

### CI/CD Pipeline

**On Pull Request:**
- `flutter analyze`
- Unit tests
- Widget tests
- Build APK (dev flavor)

**On Merge to main:**
- All tests
- Deploy Cloud Functions → staging
- E2E tests
- Generate release notes

**On Tag (v*):**
- Build production artifacts
- Deploy Cloud Functions → production
- Submit to App Stores (manual approval)
- Create GitHub release

---

## Monitoring

```yaml
Application Performance:
  - Firebase Performance Monitoring
  - Custom traces for critical paths

Error Tracking:
  - Firebase Crashlytics
  - Cloud Error Reporting

Logging:
  - Cloud Logging (structured)
  - Log levels: DEBUG, INFO, WARN, ERROR

Analytics:
  - Firebase Analytics
  - Custom events (transaction_created, receipt_scanned, etc.)
  - Retention cohorts

Alerts:
  - Error rate >1%
  - Latency >3s (95th percentile)
  - Crash rate >0.5%
  - AI quota exceeded
```

---

## Summary

**v3 Architecture Improvements:**

| Aspect | v2 (Old) | v3 (New) | Improvement |
|--------|----------|----------|-------------|
| Agents | 9 agents | 3 agents | 5x cost reduction |
| Response Time | 3-5 sec | <1 sec | 3x faster |
| Cost per Transaction | $0.004 | $0.0008 | 5x cheaper |
| Code Complexity | High (ADK/Genkit) | Low (Direct Firebase AI) | Simpler maintenance |
| SMS Auto-Capture | None | 80% automatic | Killer feature |

**End of Architecture Document**

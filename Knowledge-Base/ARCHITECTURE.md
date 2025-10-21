# Fin Copilot v2 - Technical Architecture
## Complete System Design & Implementation Guide

**Document Version:** 1.0
**Last Updated:** October 21, 2025
**Status:** Active Development Blueprint

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Technology Stack](#technology-stack)
3. [System Architecture](#system-architecture)
4. [Frontend Architecture (Flutter)](#frontend-architecture)
5. [Backend Architecture (Genkit + ADK)](#backend-architecture)
6. [AI Infrastructure](#ai-infrastructure)
7. [Data Flow](#data-flow)
8. [Security Architecture](#security-architecture)
9. [Deployment Strategy](#deployment-strategy)
10. [Scalability & Performance](#scalability--performance)

---

## Architecture Overview

### Design Principles

1. **Hybrid AI Processing**
   - Sensitive operations → On-device (Gemini Nano)
   - Complex analysis → Cloud (Gemini 2.5 Pro/Flash)
   - Automatic failover and optimization

2. **Multi-Agent Intelligence**
   - Google Agent Development Kit (ADK) for agent orchestration
   - Specialized agents for specific domains
   - Agent-to-Agent (A2A) communication protocol
   - Shared tool registry via Model Context Protocol (MCP)

3. **Serverless-First**
   - Firebase Cloud Functions for backend logic
   - Auto-scaling based on load
   - Pay only for what you use
   - Global distribution

4. **Offline-Capable**
   - Local SQLite cache for transactions
   - Firebase Firestore offline persistence
   - Queue-based sync when reconnected
   - Optimistic UI updates

5. **Security by Design**
   - PCI DSS compliant architecture
   - AES-256 encryption at rest
   - TLS 1.3 for data in transit
   - Biometric authentication
   - Secure enclaves for sensitive data

---

## Technology Stack

### Frontend Stack

```yaml
Platform: Flutter 3.32+
Language: Dart 3.8+

UI Framework:
  - Material Design 3 (useMaterial3: true)
  - Custom design system components
  - Responsive layouts (mobile, tablet, web)

State Management:
  - Riverpod 3.0 (primary)
  - Providers for dependency injection
  - StateNotifier for complex state
  - FutureProvider/StreamProvider for async data

Navigation:
  - go_router (declarative routing)
  - Deep linking support
  - Route guards for authentication

Key Packages:
  - firebase_core: ^3.6.0
  - firebase_auth: ^5.7.0
  - cloud_firestore: ^5.4.4
  - firebase_ai: ^1.0.0  # NEW - replaces firebase_vertexai
  - google_generative_ai: ^0.4.7
  - riverpod: ^3.0.0
  - go_router: ^15.1.2
  - fl_chart: ^0.68.0
  - mobile_scanner: ^5.2.3
  - cached_network_image: ^3.4.1
  - flutter_secure_storage: ^9.2.2
  - speech_to_text: ^7.3.0
  - image_picker: ^1.1.2
```

### Backend Stack

```yaml
Platform: Firebase + Google Cloud

Database:
  - Cloud Firestore (primary NoSQL database)
  - Firestore indexes for optimized queries
  - Real-time synchronization

Functions:
  - Cloud Functions (Node.js 20)
  - Firebase Genkit flows
  - Google ADK agents (Python)
  - Scheduled functions for background jobs

AI Services:
  - Firebase AI Logic (Gemini 2.5)
  - Gemini Developer API (free tier)
  - Vertex AI Gemini API (production)
  - ML Kit (on-device OCR)

Storage:
  - Firebase Storage (receipt images, exports)
  - Cloud Storage buckets

Authentication:
  - Firebase Authentication
  - Email/password, Google Sign-In, Apple Sign-In
  - Biometric (platform native)

Monitoring:
  - Firebase Crashlytics
  - Firebase Performance Monitoring
  - Cloud Logging
  - Cloud Trace
```

### AI Infrastructure

```yaml
Agent Framework:
  - Google Agent Development Kit (ADK)
  - Multi-agent orchestration
  - Agent-to-Agent (A2A) protocol

Flow Orchestration:
  - Firebase Genkit
  - RAG, chat, tool use primitives
  - Tracing and observability

Model Context Protocol:
  - MCP Dart client
  - Custom MCP servers
  - Ecosystem tool integration

Models:
  - Gemini 2.5 Pro (complex analysis)
  - Gemini 2.5 Flash (real-time chat)
  - Gemini 2.5 Flash-Lite (simple tasks)
  - Gemini Nano (on-device)
```

---

## System Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      CLIENT APPLICATIONS                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │   iOS    │  │  Android │  │   Web    │  │  Desktop │      │
│  │  Flutter │  │  Flutter │  │  Flutter │  │  Flutter │      │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘      │
│                              ↕                                  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │           Firebase AI Logic (firebase_ai)                │  │
│  │  ┌──────────────┐              ┌──────────────────┐     │  │
│  │  │ Gemini Dev   │              │ Vertex AI Gemini │     │  │
│  │  │ API (Free)   │              │  API (Enterprise)│     │  │
│  │  └──────────────┘              └──────────────────┘     │  │
│  │         ↓                              ↓                  │  │
│  │  ┌──────────────┐              ┌──────────────────┐     │  │
│  │  │  On-Device   │              │   Cloud Models   │     │  │
│  │  │ Gemini Nano  │              │ Gemini 2.5 Flash │     │  │
│  │  └──────────────┘              └──────────────────┘     │  │
│  └─────────────────────────────────────────────────────────┘  │
│                              ↕                                  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │      Model Context Protocol (MCP) Layer                  │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────┐          │  │
│  │  │   Dart   │  │Financial │  │   Custom     │          │  │
│  │  │   MCP    │  │MCP Tools │  │ MCP Servers  │          │  │
│  │  │  Server  │  │          │  │              │          │  │
│  │  └──────────┘  └──────────┘  └──────────────┘          │  │
│  └─────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                               ↕
┌─────────────────────────────────────────────────────────────────┐
│               BACKEND (Firebase + Google Cloud)                 │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │          Google Agent Development Kit (ADK)              │  │
│  │                                                           │  │
│  │  ┌────────────────────────────────────────────────┐    │  │
│  │  │     Multi-Agent Orchestrator (Coordinator)     │    │  │
│  │  │    (Agent-to-Agent Communication via A2A)      │    │  │
│  │  └────────────────────────────────────────────────┘    │  │
│  │                         ↓                                │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────┐ │  │
│  │  │Financial │  │ Receipt  │  │  Price   │  │Context│ │  │
│  │  │ Analyst  │  │  Parser  │  │  Intel   │  │ Agent │ │  │
│  │  │  Agent   │  │  Agent   │  │  Agent   │  │       │ │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └───────┘ │  │
│  │                         ↓                                │  │
│  │  ┌───────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │  │
│  │  │Extrac-│  │Validator │  │ Pattern  │  │ Coaching │ │  │
│  │  │ tor   │  │  Agent   │  │ Learner  │  │  Agent   │ │  │
│  │  └───────┘  └──────────┘  └──────────┘  └──────────┘ │  │
│  │                         ↓                                │  │
│  │  ┌────────────────────────────────────────────────┐    │  │
│  │  │         Shared Tool Registry (MCP)             │    │  │
│  │  │  • Firestore Access   • External APIs          │    │  │
│  │  │  • ML Kit OCR         • Exchange Rate APIs     │    │  │
│  │  │  • Price Comparison   • Function Calling       │    │  │
│  │  └────────────────────────────────────────────────┘    │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │             Firebase Genkit Flows                        │  │
│  │                                                           │  │
│  │  analyzeTransaction()   │  generateInsights()           │  │
│  │  parseReceipt()         │  findBestPrice()              │  │
│  │  coachUser()            │  detectAnomalies()            │  │
│  │  categor izeExpense()    │  optimizeBudget()             │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                   │
│  Deployment: Cloud Functions for Firebase / Cloud Run          │
└─────────────────────────────────────────────────────────────────┘
                               ↕
                  ┌───────────────────────┐
                  │   Firebase Services   │
                  │  • Firestore          │
                  │  • Authentication     │
                  │  • Storage            │
                  │  • Analytics          │
                  │  • Crashlytics        │
                  └───────────────────────┘
```

---

## Frontend Architecture

### Flutter App Structure

```
lib/
├── main.dart                           # App entry point
├── firebase_options.dart               # Firebase configuration
│
├── core/                               # Core app functionality
│   ├── constants/
│   │   ├── app_constants.dart          # App-wide constants
│   │   ├── categories.dart             # Transaction categories
│   │   └── routes.dart                 # Route names
│   ├── theme/
│   │   ├── app_theme.dart              # Material Design 3 theme
│   │   ├── color_schemes.dart          # Light/dark color schemes
│   │   └── text_styles.dart            # Typography
│   ├── utils/
│   │   ├── currency_utils.dart         # Currency formatting
│   │   ├── date_utils.dart             # Date/time helpers
│   │   ├── haptic_utils.dart           # Haptic feedback
│   │   └── validators.dart             # Input validation
│   └── navigation/
│       └── app_router.dart             # go_router configuration
│
├── features/                           # Feature modules
│   ├── authentication/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── models/
│   │   │       └── user_model.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── sign_in_use_case.dart
│   │   │       └── sign_out_use_case.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── sign_in_screen.dart
│   │       │   └── sign_up_screen.dart
│   │       ├── widgets/
│   │       └── providers/
│   │           └── auth_provider.dart
│   │
│   ├── transactions/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── transaction_repository.dart
│   │   │   └── models/
│   │   │       └── transaction_model.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── add_transaction_use_case.dart
│   │   │       ├── get_transactions_use_case.dart
│   │   │       └── delete_transaction_use_case.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── transactions_list_screen.dart
│   │       │   ├── transaction_detail_screen.dart
│   │       │   └── transaction_edit_screen.dart
│   │       ├── widgets/
│   │       │   ├── transaction_list_item.dart
│   │       │   └── category_selector.dart
│   │       └── providers/
│   │           ├── transactions_provider.dart
│   │           └── transaction_filter_provider.dart
│   │
│   ├── financial_copilot/              # AI Chat Interface
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── ai_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── send_message_use_case.dart
│   │   │       └── extract_transaction_use_case.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── financial_copilot_screen.dart
│   │       ├── widgets/
│   │       │   ├── chat_bubble.dart
│   │       │   ├── message_input_bar.dart
│   │       │   └── typing_indicator.dart
│   │       └── providers/
│   │           └── chat_provider.dart
│   │
│   ├── budgeting/
│   │   └── [similar structure]
│   │
│   ├── insights/
│   │   └── [similar structure]
│   │
│   ├── price_finder/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── enhanced_price_finder_home.dart
│   │   │   │   ├── barcode_scanner_screen.dart
│   │   │   │   ├── product_detail_screen.dart
│   │   │   │   └── wishlist_screen.dart
│   │   │   └── widgets/
│   │   └── data/
│   │       └── repositories/
│   │
│   └── dashboard/
│       └── [similar structure]
│
├── services/                           # Business logic services
│   ├── firebase/
│   │   ├── firestore_service.dart      # Firestore operations
│   │   ├── auth_service.dart           # Authentication
│   │   └── storage_service.dart        # File storage
│   ├── ai/
│   │   ├── firebase_ai_service.dart    # Firebase AI Logic client
│   │   ├── genkit_client.dart          # Genkit flow client
│   │   └── mcp_client.dart             # MCP client
│   ├── agents/                         # Local agent coordinators
│   │   ├── orchestrator_coordinator.dart
│   │   └── agent_communication.dart
│   ├── enhanced_price_service.dart
│   ├── price_alert_service.dart
│   ├── notification_service.dart
│   ├── analytics_service.dart
│   └── sync_service.dart               # Offline sync
│
├── shared/                             # Shared components
│   ├── models/
│   │   ├── transaction.dart
│   │   ├── budget.dart
│   │   ├── product_price_data.dart
│   │   └── user_preferences.dart
│   ├── widgets/
│   │   ├── custom_button.dart
│   │   ├── loading_indicator.dart
│   │   ├── error_widget.dart
│   │   └── gradient_fab.dart
│   ├── extensions/
│   │   ├── string_extensions.dart
│   │   ├── date_extensions.dart
│   │   └── number_extensions.dart
│   └── providers/
│       ├── theme_provider.dart
│       └── locale_provider.dart
│
└── generated/                          # Generated files
    ├── intl/                           # Internationalization
    └── assets.dart                     # Asset references
```

### State Management with Riverpod

```dart
// Example: Transaction List Provider
import 'package:riverpod/riverpod.dart';

// Repository provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final auth = ref.watch(authServiceProvider);
  return TransactionRepository(firestore: firestore, auth: auth);
});

// Transactions stream provider
final transactionsStreamProvider = StreamProvider.autoDispose<List<Transaction>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return Stream.value([]);
  }

  return repository.getTransactionsStream(userId);
});

// Filtered transactions provider
final filteredTransactionsProvider = Provider.autoDispose<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final filter = ref.watch(transactionFilterProvider);

  return transactions.where((txn) {
    if (filter.category != null && txn.category != filter.category) {
      return false;
    }
    if (filter.dateRange != null &&
        !filter.dateRange!.contains(txn.date)) {
      return false;
    }
    return true;
  }).toList();
});

// Transaction actions provider
final transactionActionsProvider = Provider<TransactionActions>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionActions(repository);
});

class TransactionActions {
  final TransactionRepository repository;

  TransactionActions(this.repository);

  Future<void> addTransaction(Transaction transaction) async {
    await repository.add(transaction);
  }

  Future<void> updateTransaction(String id, Transaction transaction) async {
    await repository.update(id, transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await repository.delete(id);
  }
}
```

---

## Backend Architecture

### Firebase Genkit Flows

#### Project Structure

```
backend/
├── package.json
├── genkit.config.ts                   # Genkit configuration
├── tsconfig.json
│
├── src/
│   ├── index.ts                       # Cloud Function entry point
│   │
│   ├── flows/                         # Genkit flows
│   │   ├── transaction-analysis.ts    # Analyze transaction data
│   │   ├── receipt-parsing.ts         # Parse receipt images
│   │   ├── insights-generation.ts     # Generate financial insights
│   │   ├── price-comparison.ts        # Price intelligence
│   │   ├── budget-optimization.ts     # Budget recommendations
│   │   └── coaching.ts                # Financial coaching
│   │
│   ├── agents/                        # ADK agents
│   │   ├── orchestrator.ts            # Main coordinator
│   │   ├── financial-analyst.ts
│   │   ├── receipt-parser.ts
│   │   ├── price-intelligence.ts
│   │   ├── context-agent.ts
│   │   ├── extractor.ts
│   │   ├── validator.ts
│   │   └── pattern-learner.ts
│   │
│   ├── tools/                         # Shared tools
│   │   ├── firestore-tools.ts         # Database access
│   │   ├── ml-kit-tools.ts            # OCR processing
│   │   ├── price-api-tools.ts         # Price comparison APIs
│   │   ├── exchange-rate-tools.ts     # Currency conversion
│   │   └── notification-tools.ts      # Push notifications
│   │
│   ├── mcp/                           # MCP servers
│   │   ├── financial-tools-server.ts
│   │   └── custom-mcp-tools.ts
│   │
│   ├── services/
│   │   ├── firestore.service.ts
│   │   ├── storage.service.ts
│   │   └── auth.service.ts
│   │
│   └── utils/
│       ├── prompts.ts                 # Prompt templates
│       ├── validation.ts
│       └── helpers.ts
│
└── functions/                         # Additional Cloud Functions
    ├── scheduled/
    │   ├── daily-insights.ts          # Generate daily insights
    │   ├── budget-alerts.ts           # Check budget thresholds
    │   └── price-monitoring.ts        # Monitor wishlist prices
    └── triggers/
        ├── on-transaction-create.ts   # Auto-categorize
        └── on-user-signup.ts          # Initialize user data
```

#### Example Genkit Flow

```typescript
// flows/transaction-analysis.ts
import { defineFlow, runFlow } from '@genkit-ai/flow';
import { gemini25Flash } from '@genkit-ai/googleai';
import { z } from 'zod';

// Input/Output schemas
const TransactionInputSchema = z.object({
  userId: z.string(),
  description: z.string(),
  context: z.object({
    recentTransactions: z.array(z.any()).optional(),
    userPreferences: z.record(z.any()).optional(),
  }).optional(),
});

const TransactionOutputSchema = z.object({
  amount: z.number(),
  category: z.string(),
  merchant: z.string().nullable(),
  date: z.string(),
  paymentMethod: z.string().nullable(),
  confidence: z.number(),
  needsClarification: z.array(z.string()).optional(),
});

// Define the flow
export const analyzeTransactionFlow = defineFlow(
  {
    name: 'analyzeTransaction',
    inputSchema: TransactionInputSchema,
    outputSchema: TransactionOutputSchema,
  },
  async (input) => {
    // Step 1: Extract transaction data using Extractor Agent
    const extractedData = await runFlow(extractDataSubFlow, {
      description: input.description,
      context: input.context,
    });

    // Step 2: Validate extracted data using Validator Agent
    const validation = await runFlow(validateDataSubFlow, {
      data: extractedData,
      userId: input.userId,
    });

    // Step 3: Enrich with historical context using Context Agent
    const enrichedData = await runFlow(enrichDataSubFlow, {
      data: validation.data,
      userId: input.userId,
    });

    // Step 4: Learn patterns using Pattern Learner Agent
    await runFlow(learnPatternsSubFlow, {
      userId: input.userId,
      transaction: enrichedData,
    });

    return enrichedData;
  }
);

// Sub-flow: Extract transaction data
const extractDataSubFlow = defineFlow(
  {
    name: 'extractData',
    inputSchema: z.object({
      description: z.string(),
      context: z.any().optional(),
    }),
    outputSchema: TransactionOutputSchema,
  },
  async (input) => {
    const prompt = `Extract transaction details from this description:

    "${input.description}"

    Context: ${JSON.stringify(input.context || {})}

    Extract: amount, category, merchant, date, payment method.
    Return JSON matching the schema.`;

    const response = await gemini25Flash.generateContent({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.2,
        responseMimeType: 'application/json',
      },
    });

    const result = JSON.parse(response.response.text());
    return result;
  }
);
```

### Google ADK Multi-Agent System

#### Agent Configuration

```python
# agents/orchestrator.py
from google_adk import Agent, Tool
from google_adk.models import GeminiModel

# Define tools
def analyze_spending(user_id: str, period: str) -> dict:
    """Analyze user spending for a given period."""
    # Query Firestore, calculate metrics
    return {...}

def categorize_transaction(description: str) -> str:
    """Determine the appropriate category for a transaction."""
    # Use ML model or rules
    return "category"

def get_user_context(user_id: str) -> dict:
    """Get user's financial context and preferences."""
    # Load from Firestore
    return {...}

# Define Orchestrator Agent
orchestrator = Agent(
    name="Orchestrator",
    model=GeminiModel("gemini-2.5-pro"),
    system_prompt="""
    You are the Orchestrator agent for Fin Copilot, a personal finance app.
    Your role is to coordinate specialized agents to fulfill user requests.

    You have access to these agents as tools:
    - Financial Analyst: Deep financial analysis and insights
    - Receipt Parser: Extract data from receipt images
    - Price Intelligence: Find best prices and deals
    - Context Agent: Understand user preferences and history

    Route requests to the appropriate agent(s) and synthesize results.
    Always provide clear, actionable responses to users.
    """,
    tools=[
        "financial_analyst_agent",  # Agent as tool
        "receipt_parser_agent",
        "price_intelligence_agent",
        "context_agent",
        analyze_spending,
        categorize_transaction,
        get_user_context,
    ],
)

# Define Financial Analyst Agent
financial_analyst = Agent(
    name="Financial Analyst",
    model=GeminiModel("gemini-2.5-pro"),
    system_prompt="""
    You are a financial analyst specializing in personal finance.
    Analyze spending patterns, identify trends, and provide actionable insights.

    Use provided tools to access transaction data, budget information, and historical trends.
    Generate clear, data-driven recommendations.
    """,
    tools=[
        analyze_spending,
        get_user_context,
        # Firestore access tools
    ],
)

# Enable Agent-to-Agent communication
from google_adk import enable_a2a

enable_a2a([
    orchestrator,
    financial_analyst,
    receipt_parser,
    price_intelligence,
    context_agent,
    extractor,
    validator,
    pattern_learner,
])
```

---

## AI Infrastructure

### Model Selection Strategy

| Use Case | Model | Reasoning |
|----------|-------|-----------|
| Quick chat responses | Gemini 2.5 Flash-Lite | Ultra-fast, low cost, 50% fewer tokens |
| Transaction extraction | Gemini 2.5 Flash | Good accuracy, fast, JSON mode |
| Financial analysis | Gemini 2.5 Pro | Deep reasoning, complex calculations |
| Receipt OCR | ML Kit + Gemini 2.5 Flash | On-device OCR + AI parsing |
| Price predictions | Gemini 2.5 Pro | Multi-step reasoning, trend analysis |
| Coaching tips | Gemini 2.5 Flash | Contextual, conversational |
| Sensitive calculations | Gemini Nano (on-device) | Privacy-preserving |

### Hybrid Processing Decision Tree

```
User Request
    ↓
Is data sensitive? (PINs, passwords, etc.)
    ├─ YES → On-Device (Gemini Nano)
    └─ NO  → Continue
              ↓
Is immediate response needed? (<1s)
    ├─ YES → On-Device if model available
    │         ↓ (or fallback)
    │        Cloud (Gemini Flash-Lite)
    └─ NO  → Continue
              ↓
Is complex reasoning required?
    ├─ YES → Cloud (Gemini 2.5 Pro)
    └─ NO  → Cloud (Gemini 2.5 Flash)
```

---

## Data Flow

### Transaction Entry Flow (Voice Input Example)

```
User taps microphone
    ↓
Flutter: speech_to_text starts listening
    ↓
User speaks: "I spent 50 dollars on groceries"
    ↓
Flutter: STT converts to text
    ↓
Flutter: Send text to Financial Copilot chat
    ↓
Chat Service: Call Genkit flow analyzeTransaction()
    ↓
Genkit Flow: Orchestrator Agent receives request
    ↓
Orchestrator: Route to Extractor Agent
    ↓
Extractor: Parse natural language → structured data
    {amount: 50, category: "groceries", date: "today"}
    ↓
Orchestrator: Route to Validator Agent
    ↓
Validator: Check completeness, validate ranges
    ↓
Orchestrator: Route to Context Agent
    ↓
Context: Enhance with user history (usual grocery store, etc.)
    ↓
Genkit Flow: Return enriched transaction data
    ↓
Flutter: Display confirmation UI
    ↓
User: Confirms
    ↓
Flutter: Save to Firestore
    ↓
Firestore Trigger: on-transaction-create
    ↓
Cloud Function: Update budgets, generate insights
    ↓
Flutter: Real-time update via Firestore listener
    ↓
UI updates: transaction list, budget progress, insights
```

---

## Security Architecture

### Authentication Flow

```
1. User opens app
2. Check for existing session (Firebase Auth persistence)
3. If no session → Navigate to Sign In screen
4. User chooses sign-in method:
   - Email/Password
   - Google Sign-In (OAuth)
   - Apple Sign-In (OAuth)
   - Biometric (after initial setup)

5. Firebase Authentication validates credentials
6. On success:
   - Receive ID token
   - Store securely in flutter_secure_storage
   - Set up Firestore listeners with authenticated user ID
   - Navigate to Dashboard

7. Token refresh:
   - Firebase SDK auto-refreshes tokens
   - Handle refresh errors (re-authenticate)
```

### Data Encryption

**At Rest:**
- Firestore: Encrypted by default (AES-256)
- Firebase Storage: Encrypted by default
- Local storage: flutter_secure_storage (platform Keychain/Keystore)
- Sensitive fields: Additional AES-256 encryption layer

**In Transit:**
- All Firebase connections: TLS 1.3
- Cloud Function calls: HTTPS only
- Gemini API calls: HTTPS with API key auth

### Access Control

**Firestore Security Rules:**

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

    // Users collection
    match /users/{userId} {
      allow read, write: if isOwner(userId);
    }

    // Transactions collection
    match /transactions/{transactionId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() &&
                       request.resource.data.userId == request.auth.uid;
      allow update, delete: if isOwner(resource.data.userId);
    }

    // Budgets collection
    match /budgets/{budgetId} {
      allow read, write: if isOwner(resource.data.userId);
    }

    // Watchlist collection
    match /watchlist/{itemId} {
      allow read, write: if isOwner(resource.data.userId);
    }

    // User preferences
    match /user_preferences/{userId} {
      allow read, write: if isOwner(userId);
    }
  }
}
```

---

## Deployment Strategy

### Development Environment

```yaml
Firebase Project: fin-copilot-dev
Cloud Functions: dev region (us-central1)
Firestore: Dev database
Gemini: Developer API (free tier)

Build Configuration:
  - Debug mode
  - Verbose logging
  - Test data seeding
  - Local emulators
```

### Staging Environment

```yaml
Firebase Project: fin-copilot-staging
Cloud Functions: us-central1
Firestore: Staging database
Gemini: Vertex AI (with quotas)

Build Configuration:
  - Release mode
  - Limited logging
  - Real data (sanitized)
  - Performance monitoring
```

### Production Environment

```yaml
Firebase Project: fin-copilot-prod
Cloud Functions: Multi-region (us-central1, europe-west1)
Firestore: Production database (multi-region)
Gemini: Vertex AI (production quotas)
CDN: Firebase Hosting

Build Configuration:
  - Release mode (obfuscated)
  - Error-only logging
  - Real data
  - Full monitoring & alerting
  - Rate limiting
  - DDoS protection (Cloud Armor)
```

### CI/CD Pipeline

```yaml
GitHub Actions Workflow:

1. On Pull Request:
   - Run Flutter analyze
   - Run unit tests
   - Run widget tests
   - Run integration tests
   - Check code coverage (>80%)
   - Build APK/IPA (dev flavor)

2. On Merge to main:
   - Run all tests
   - Build release APK/IPA
   - Deploy Cloud Functions to staging
   - Run E2E tests against staging
   - Generate release notes

3. On Tag (v*):
   - Build production artifacts
   - Deploy Cloud Functions to production
   - Deploy Genkit flows
   - Deploy ADK agents
   - Submit to App Stores (manual approval)
   - Create GitHub release
```

---

## Scalability & Performance

### Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| App Launch Time | <2s | Firebase Performance |
| Transaction List Load | <1s for 100 txns | Firebase Performance |
| AI Response (simple) | <1s | Cloud Trace |
| AI Response (complex) | <3s | Cloud Trace |
| Receipt OCR | <5s | Cloud Trace |
| Firestore Query | <500ms | Firebase Console |
| API Success Rate | >99.5% | Cloud Monitoring |
| Crash Rate | <0.5% | Firebase Crashlytics |

### Scaling Strategies

**Frontend:**
- Lazy loading of routes
- Image caching (cached_network_image)
- Pagination for large lists (50 items per page)
- Virtual scrolling (ListView.builder)
- Local caching with expiration

**Backend:**
- Cloud Functions auto-scale (0 to 1000s of instances)
- Firestore auto-shards at high load
- Genkit flows containerized for horizontal scaling
- Redis cache for frequently accessed data (future)
- CDN for static assets

**Database:**
- Composite indexes for common queries
- Denormalization for read-heavy data
- Batch writes (max 500 per batch)
- Pagination with cursors
- Delete old data (retention policy)

**AI:**
- Request batching where possible
- Response caching (1-hour TTL)
- Fallback to simpler models under load
- Rate limiting per user
- On-device processing for simple tasks

---

## Monitoring & Observability

### Monitoring Stack

```yaml
Application Performance:
  - Firebase Performance Monitoring
  - Custom traces for critical paths
  - Network request monitoring
  - Screen rendering metrics

Error Tracking:
  - Firebase Crashlytics
  - Cloud Error Reporting
  - Custom error boundaries
  - User feedback integration

Logging:
  - Cloud Logging (structured logs)
  - Log levels: DEBUG, INFO, WARN, ERROR
  - User action logs (anonymized)

Tracing:
  - Cloud Trace for backend
  - Genkit built-in tracing
  - End-to-end request tracing

Analytics:
  - Firebase Analytics (user behavior)
  - Custom events
  - Conversion funnels
  - Retention cohorts

Alerts:
  - Error rate spikes
  - Latency degradation
  - Quota exceeded
  - Security anomalies
```

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-21 | Claude (AI Research) | Initial architecture document |

**Next Steps:** Review architecture with engineering team, validate technology choices, begin implementation.

---

**End of Architecture Document**

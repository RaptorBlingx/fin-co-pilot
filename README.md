# FinCoPilot

> Your AI-powered personal finance companion — chat naturally, track smarter, spend better.

FinCoPilot is a cross-platform mobile and web app that puts a genuinely intelligent financial assistant in your pocket. Instead of filling out forms, you just talk: *"I spent $18 on breakfast at Costa"* and FinCoPilot handles the rest — categorized, logged, and learned from. Powered by Google Gemini through Firebase AI, it gets progressively smarter about your habits, goals, and financial patterns over time.

---

## What makes it different

Most finance apps are glorified spreadsheets. FinCoPilot is built around a **multi-agent AI architecture** where specialized Gemini models work together — one extracts transaction data from your words, one validates it, one builds rich context about your financial life, and the main orchestrator decides the best action to take. The result is a conversation that actually feels intelligent.

---

## Core features

### Conversational transaction capture
Say or type anything natural — *"paid rent, $1,200"*, *"grabbed coffee, $4.50"*, *"got my salary today"* — and Gemini's function-calling layer parses the amount, merchant, category, and tags in one step. No dropdowns, no manual forms.

### Voice input
Press to talk anywhere in the app. `speech_to_text` transcribes your voice in real time and feeds it straight into the AI pipeline.

### Receipt scanning
Photograph a receipt and Google Vision AI extracts the text. Gemini then parses the structured data — merchant, items, totals, tax — and maps it to a transaction ready for your confirmation.

### Smart budgets & real-time alerts
Set monthly budgets by category. Firebase Cloud Functions run daily to check spend vs. limit and push notifications before you overshoot.

### Spending insights & charts
Interactive charts across configurable date ranges. See top categories, month-over-month trends, and daily burn patterns — backed by Firebase aggregation queries, not client-side math.

### Financial health score
A 0–100 composite score updated weekly, built from four equally-weighted pillars: budget adherence, savings rate, debt management, and spending stability. Tracks the trend so you know if you're improving.

### Predictive cash flow
Projects your balance 7–30 days forward by calculating your daily burn rate and factoring in detected recurring expenses. Designed to surface overdraft risk before it happens.

### AI coaching
`ProactiveCoachAgent` delivers personalized, time-aware financial tips using behavioral psychology principles — anchoring, loss aversion, social proof — calibrated against your actual spending patterns, goals, and even the time of day.

### Long-term memory (Pro)
`MemoryService` builds a persistent behavioral dossier across five Firestore documents: behavior profile, spending patterns, preferences, financial goals, and life context. Every transaction enriches it. The AI reads this before every response so it always knows who it's talking to.

### Cross-session conversation memory (Pro)
`ConversationMemoryService` summarizes each chat session using Gemini Lite, stores up to 10 compressed summaries, and injects the last 3 into every new session. The AI remembers what you talked about last week.

### Price intelligence
`PriceIntelligenceAgent` uses Gemini with Google Search grounding to find real-time prices for products, compare costs, and surface deals — localized to your country and currency with a built-in cache.

### PDF & CSV report export
`ReportGeneratorAgent` uses Gemini Flash to analyze your transactions and generate a narrative financial summary, then compiles it into a downloadable PDF or CSV.

### Persistent chat history
Every conversation thread is saved to Firestore. Your chat history loads instantly in the sidebar — browse, continue, or delete past sessions. Pro users get unlimited sessions; free users get the last 7.

### Behavioral nudges (Pro)
After a transaction is saved, `NudgeService` checks whether a contextual encouragement is appropriate — rate-limited to 2 per day, 1 per 5 transactions — drawing on your behavior profile to keep it relevant, not annoying.

---

## Premium tier

FinCoPilot is free to use with a **Pro tier at $4.99/month** that unlocks the full AI-powered experience:

| Feature | Free | Pro |
|---|---|---|
| Transaction capture & budgets | ✓ | ✓ |
| Chat history | 7 sessions | Unlimited |
| Spending insights history | 7 days | 1 year |
| Financial goals | 1 goal | Unlimited |
| Long-term behavioral memory | — | ✓ |
| Cross-session conversation recall | — | ✓ |
| Behavioral nudges | — | ✓ |
| Coaching tips per day | 1 | Unlimited |
| AI model tier | Gemini Flash Lite | Gemini Flash + Pro for deep analysis |
| Full context builder | — | ✓ |

---

## Tech stack

| Layer | Technology |
|---|---|
| UI framework | Flutter / Dart |
| State management | Riverpod |
| Navigation | GoRouter |
| AI models | Google Gemini (Flash Lite, Flash, Pro) via Firebase AI SDK |
| Database | Cloud Firestore |
| Auth | Firebase Authentication |
| File storage | Firebase Storage |
| Push notifications | Firebase Cloud Messaging |
| Scheduled jobs | Firebase Cloud Functions (Node.js 18) |
| Analytics & crash reporting | Firebase Analytics + Crashlytics |
| OCR | Google Cloud Vision AI (Firebase Extension) |
| Charts | fl_chart |
| Animations | flutter_animate, Lottie |
| Voice | speech_to_text |
| Exports | pdf, csv |

---

## AI architecture

The AI layer is built as a pipeline of specialized agents, not a single monolithic prompt:

```
User message
    │
    ▼
FinancialCopilotOrchestrator        ← Gemini Flash (function calling)
    │  decides action via tool use
    ├─► save_transaction             ← synchronous (no extra API call)
    ├─► get_budget_status            ← executes → Gemini writes response
    ├─► get_spending_summary         ← executes → Gemini writes response
    ├─► search_prices                ← PriceIntelligenceAgent (Gemini + Google Search)
    ├─► set_financial_goal           ← writes to Firestore → Gemini confirms
    └─► get_coaching_tip             ← ProactiveCoachAgent (Gemini Flash)

Transaction add flow (multi-agent):
  OrchestratorAgent → ExtractorAgent → ValidatorAgent → ContextAgent

Background intelligence:
  UserContextBuilder      ← parallel Firestore reads, 5-min cache
  MemoryService           ← behavioral dossier (5 Firestore docs)
  ConversationMemoryService ← session summarization + recall
  NudgeService            ← post-save behavioral encouragement
  ReportGeneratorAgent    ← Gemini Flash → PDF/CSV
```

The orchestrator uses `ThinkingConfig` with `ThinkingLevel.minimal` so chain-of-thought reasoning runs in the background — fast responses without sacrificing intelligence.

---

## Platform targets

- Android
- iOS
- Web

---

## Getting started

### Prerequisites

- Flutter SDK (Dart `^3.5.4`)
- Firebase CLI
- Node.js 18 (for Cloud Functions)
- A Firebase project with Auth, Firestore, Storage, Cloud Messaging, Analytics, Crashlytics, Hosting, and Firebase AI enabled

### Local setup

```bash
# 1. Install Flutter dependencies
flutter pub get

# 2. Install Cloud Functions dependencies
cd functions && npm install && cd ..

# 3. Point the app at your own Firebase project
#    Generate firebase_options.dart with:
flutterfire configure

# 4. Run
flutter run
```

### Common commands

```bash
flutter analyze
flutter test
flutter run
flutter build apk

cd functions
npm run serve                        # local emulator
firebase deploy --only functions
firebase deploy --only hosting
```

---

## Repository layout

```
lib/
  core/           app theme, routing, config, utilities
  features/       auth, dashboard, budget, insights, reports,
                  receipts, coaching, financial_copilot, settings, …
  models/         data models (Transaction, UserContext, MemoryModels, …)
  services/       AI agents, orchestrators, Firebase integrations
  shared/         cross-feature widgets and models
functions/        Firebase Cloud Functions (scheduled tips, budget alerts)
assets/           fonts, images, Lottie animations
test/
```

The main entry points for understanding the codebase:

- `lib/main.dart` — app bootstrap
- `lib/core/config/features_config.dart` — feature flags
- `lib/services/financial_copilot_orchestrator.dart` — core AI orchestration
- `lib/services/user_context_builder.dart` — how user context is assembled
- `lib/features/financial_copilot/` — the main chat screen and flow

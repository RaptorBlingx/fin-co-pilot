<div align="center">

# 🤖 Fin Co-Pilot

### Your AI-Powered Personal Finance Companion

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Powered-FFCA28?logo=firebase)](https://firebase.google.com)
[![Gemini AI](https://img.shields.io/badge/Gemini-2.5_Flash-4285F4?logo=google)](https://ai.google.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)](https://flutter.dev/multi-platform)
[![License](https://img.shields.io/badge/License-Private-red)](LICENSE)

*Reduce financial anxiety through zero-effort, AI-first transaction tracking*

</div>

---

## 📖 Overview

**Fin Co-Pilot** is a premium Flutter application that transforms personal finance management into an effortless, conversational experience. Instead of wrestling with spreadsheets or clunky forms, you simply chat with your AI copilot — just like texting a friend — and it handles the rest.

Powered by **Google's Gemini 2.5 Flash** and a multi-agent architecture, Fin Co-Pilot learns your spending patterns, detects anomalies in real-time, provides actionable coaching, and helps you find the best deals — all from a beautifully designed Material Design 3 interface.

---

## ✨ Key Features

### 🧠 AI Financial Copilot (Conversational Interface)
A premium chat interface that acts as your personal financial advisor. Just describe your transaction in plain English — the AI handles intent classification, data extraction, and confirmation.

- **Natural Language Transactions** — *"I spent $45 at Target on groceries"* → instantly categorized and saved
- **Intent Classification** — automatically routes to the right handler: add expense, get advice, check budget, find prices, generate reports, or just chat
- **Smart Follow-up Questions** — asks only what it needs, one question at a time
- **Contextual Greetings** — time-aware, personalized welcome based on your history
- **Quick Action Chips** — adapts dynamically to your usage stage (beginner → power user)
- **Animated Typing Indicator** — premium pulsing dots while AI thinks

### 🏠 Intelligent Dashboard
A hero-first layout designed for instant financial clarity at a glance.

- **Hero Spending Card** — gradient card showing monthly total, budget gauge, and sparkline chart
- **AI Insight Carousel** — up to 3 rotating smart insights powered by real transaction data
- **Recent Transactions** — compact, emoji-tagged transaction feed
- **Quick Actions** — one-tap shortcuts to Reports and Shopping
- **Shimmer Loading** — professional skeleton screens during data fetch

### 💳 Transaction Management
Rich transaction tracking that goes beyond simple amounts.

- **Conversational Input** — add expenses by chatting, not filling forms
- **Voice Input** — dictate transactions hands-free via `speech_to_text`
- **Receipt Scanning** — photograph receipts; the AI extracts every line item automatically (Gemini Vision)
- **Item-Level Tracking** — *"Groceries $47: Milk, eggs, bread, chicken"* — track individual items, not just totals
- **Full Transaction History** — filterable, searchable list with category filters
- **Transaction Editing** — edit or delete any logged transaction
- **Multi-Currency Support** — configurable during onboarding

### 📊 Insights & Analytics
Turn raw spending data into meaningful intelligence.

- **Spending Trends** — month-over-month comparison with percentage changes
- **Category Breakdown** — interactive pie/bar charts via `fl_chart`
- **Anomaly Detection** — flags unusual spending spikes
- **Top Categories** — ranked by spend with trend arrows
- **Chart Skeleton Loading** — smooth professional loading states

### 💰 Budget Manager
Proactive budget monitoring that keeps you on track.

- **Category Budgets** — set monthly limits per spending category
- **Real-time Alerts** — push notifications at 50%, 80%, and 100% thresholds
- **Budget vs. Actual** — visual progress bars for every category
- **Monthly Reset** — automated resets via Firebase Cloud Functions

### 🔍 Price Intelligence & Finder
A sophisticated price tracking system that saves you money.

- **Barcode / QR Scanner** — scan any product for instant price lookup
- **Price History Tracking** — monitors price changes over time across stores
- **Deal of the Day** — featured best deals surfaced automatically
- **Price Drops** — horizontal feed of tracked items with recent drops
- **Trending Deals** — community/AI-surfaced trending bargains
- **Wishlist / Watchlist** — save items and get notified when prices fall
- **Store Comparison** — ranks stores cheapest-to-most-expensive per item
- **Purchase Predictions** — *"You usually buy milk every 4 days — need it soon?"*
- **Price Trend Indicators** — ↗ up, ↘ down, → stable with color coding

### 🛒 Smart Shopping
AI-assisted shopping to complement your spending habits.

- **Product Search** — intelligent search with category filters
- **Popular Suggestions** — smart chips for quick searches
- **Price Card Skeletons** — realistic loading UI

### 🎓 Financial Coaching
Personalized, AI-driven financial coaching delivered proactively.

- **Proactive Coach Agent** — monitors patterns and surfaces timely tips
- **Tips Library** — curated coaching tips across savings, budgeting, investing
- **Daily Wisdom** — automated daily financial tip via push notification
- **Goal-Oriented Advice** — tips aligned to your actual spending behavior
- **Haptic Feedback** — tactile confirmation on actions

### 🔔 Push Notifications System
Intelligent, non-spammy notifications that add real value.

- **Budget Threshold Alerts** — 50% / 80% / 100% spend warnings
- **Coaching Tips** — weekly AI-personalized financial wisdom (Sundays 9 AM)
- **Daily Budget Check** — evening spending summary (8 PM)
- **Price Drop Alerts** — monitored every 6 hours via Cloud Functions
- **Milestone Achievements** — celebrate financial wins
- **Quiet Hours** — configurable do-not-disturb schedule
- **Granular Toggles** — individual on/off per notification type

### 🔐 Authentication & Security
Enterprise-grade security built in from day one.

- **Google Sign-In** — frictionless OAuth
- **Apple Sign-In** — native iOS experience
- **Biometric Authentication** — Face ID / fingerprint via `local_auth`
- **Secure Token Storage** — encrypted with `flutter_secure_storage`
- **Firebase Authentication** — battle-tested auth backbone

### ⚙️ Settings & Personalization
Full control over your experience.

- **Dark / Light Mode** — Material Design 3 theming, persisted across sessions
- **Currency Selection** — configurable during onboarding
- **Notification Controls** — per-type toggles with quiet hours
- **Haptic Feedback Toggle** — enable / disable tactile responses
- **Language Support** — localization-ready

### 📄 Reports & Export
Professional financial reports when you need them.

- **Monthly Summary Reports** — AI-generated narrative summaries
- **PDF Export** — print-ready reports via `pdf` + `printing`
- **CSV Export** — raw data export for spreadsheet analysis
- **Share** — share reports directly via `share_plus`

---

## 🏗️ Architecture

### Multi-Agent AI Swarm
The intelligence layer is built as a **7-agent fault-tolerant swarm** where each agent specializes in one task:

```
User Input
    │
    ▼
┌─────────────────────────────────────────────────┐
│  RobustAIService (Entry Point)                  │
│  • Routes to Agent Swarm OR Single Model        │
│  • Manages conversation history & fallbacks     │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│  Agent 1: ORCHESTRATOR  ← The Brain             │
│  Coordinates agents · Synthesizes responses     │
└────────┬──────────┬──────────┬──────────────────┘
         │          │          │
         ▼          ▼          ▼
   ┌──────────┐ ┌──────────┐ ┌──────────┐
   │Agent 2   │ │Agent 3   │ │Agent 4   │
   │EXTRACTOR │ │VALIDATOR │ │CONTEXT   │
   │Parses NL │ │Checks    │ │Suggests  │
   │→ data    │ │required  │ │receipt   │
   └──────────┘ │fields    │ │uploads   │
                └──────────┘ └──────────┘
         │          │          │
         ▼          ▼          ▼
   ┌──────────┐ ┌──────────┐ ┌──────────┐
   │Agent 5   │ │Agent 6   │ │Agent 7   │
   │RECEIPT   │ │ITEM      │ │PATTERN   │
   │Gemini    │ │TRACKER   │ │LEARNER   │
   │Vision OCR│ │Item-level│ │Behavioral│
   │→ items   │ │profiles  │ │insights  │
   └──────────┘ └──────────┘ └──────────┘
```

### App Architecture
Clean, feature-first Flutter architecture:

```
lib/
├── core/
│   ├── navigation/          # GoRouter + page transitions
│   ├── providers/           # Riverpod theme provider
│   ├── theme/               # Material Design 3 tokens
│   └── utils/               # Haptic utilities
├── features/
│   ├── add_transaction/     # Conversational transaction input
│   ├── auth/                # Sign-in screens
│   ├── budget/              # Budget management
│   ├── coaching/            # Financial coaching
│   ├── dashboard/           # Home screen + widgets
│   ├── financial_copilot/   # AI chat interface
│   ├── insights/            # Analytics & charts
│   ├── notifications/       # Notification feed
│   ├── onboarding/          # First-run experience
│   ├── price_finder/        # Deal finder + barcode scanner
│   ├── price_intelligence/  # Price tracking dashboard
│   ├── reports/             # Report generation
│   ├── settings/            # App preferences
│   ├── shopping/            # Smart shopping search
│   └── transactions/        # Transaction list + detail
├── services/
│   ├── agents/              # 7-agent AI swarm
│   ├── sms/                 # Bank SMS parsing
│   └── *.dart               # Core business services
├── shared/
│   ├── models/              # Data models (Transaction, etc.)
│   └── widgets/             # Reusable UI components
└── widgets/
    ├── animated/            # Custom animation widgets
    ├── loading/             # Loading state components
    └── lottie/              # Lottie animation wrappers
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x (Dart 3.5+) |
| **State Management** | Flutter Riverpod 2.x |
| **Navigation** | GoRouter 15.x |
| **AI / LLM** | Google Gemini 2.5 Flash via `firebase_ai` + `google_generative_ai` |
| **Backend** | Firebase (Firestore, Auth, Storage, Functions, Crashlytics, Analytics) |
| **Charts** | fl_chart 0.68 |
| **Animations** | flutter_animate, Lottie, shimmer |
| **Notifications** | Firebase Cloud Messaging + flutter_local_notifications |
| **Biometrics** | local_auth |
| **Secure Storage** | flutter_secure_storage |
| **Barcode Scanning** | mobile_scanner |
| **Voice Input** | speech_to_text |
| **Image Handling** | image_picker, cached_network_image |
| **Export** | pdf, csv, share_plus, printing |
| **Fonts** | Google Fonts (Inter, Manrope) |
| **OTA Updates** | Shorebird |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.5.4`
- [Dart SDK](https://dart.dev/get-dart) `^3.5.4`
- [Firebase CLI](https://firebase.google.com/docs/cli)
- An active [Firebase project](https://console.firebase.google.com) with the following services enabled:
  - Authentication (Google + Apple sign-in providers)
  - Cloud Firestore
  - Firebase Storage
  - Firebase Cloud Messaging
  - Firebase AI (Gemini)
  - Firebase Analytics + Crashlytics

### 1. Clone & Install

```bash
git clone https://github.com/RaptorBlingx/fin-co-pilot.git
cd fin-co-pilot
flutter pub get
```

### 2. Firebase Setup

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This generates `lib/firebase_options.dart` with your project credentials.

### 3. Firestore Indexes

Deploy the required Firestore composite indexes:

```bash
firebase deploy --only firestore:indexes
```

### 4. Firestore Security Rules

```bash
firebase deploy --only firestore:rules
```

### 5. Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

### 6. Run the App

```bash
# Debug mode
flutter run

# Release build
flutter build apk --release        # Android
flutter build ipa --release        # iOS
```

### 7. Native Splash Screen (optional rebuild)

```bash
dart run flutter_native_splash:create
```

---

## 📁 Project Structure Highlights

| Path | Purpose |
|---|---|
| `lib/main.dart` | App entry point, Firebase init |
| `lib/core/theme/app_theme.dart` | Material Design 3 tokens (light + dark) |
| `lib/core/navigation/app_navigation.dart` | Bottom nav + FAB orchestration |
| `lib/services/financial_copilot_orchestrator.dart` | AI intent routing brain |
| `lib/services/agents/` | 7-agent swarm (orchestrator, extractor, validator, context, receipt, item-tracker, pattern-learner) |
| `lib/features/financial_copilot/` | Premium AI chat UI |
| `lib/features/price_intelligence/` | Price tracking dashboard |
| `lib/services/notification_service.dart` | FCM + local notifications |
| `lib/services/budget_monitoring_service.dart` | Real-time budget alerts |
| `functions/index.js` | Firebase Cloud Functions (scheduled jobs) |
| `firestore.rules` | Firestore security rules |
| `firestore.indexes.json` | Composite index definitions |

---

## 🎨 Design System

| Token | Value | Usage |
|---|---|---|
| **Primary** | Indigo-600 `#4F46E5` | Intelligence, trust |
| **Accent** | Emerald-500 `#10B981` | Growth, money |
| **Display Font** | Manrope Bold | Headlines |
| **Body Font** | Inter Regular/Semibold | Body text |
| **Number Font** | SF Mono Medium | Financial figures |
| **Border Radius** | 12–20 dp | Cards, chips |
| **Splash Color** | `#1976D2` | Native splash |

Dark mode is fully supported with a dedicated Indigo-900 background palette.

---

## 🔒 Security & Privacy

- All user data is scoped by Firebase UID — users can only access their own records
- Sensitive tokens stored with `flutter_secure_storage` (AES-256 on Android, Keychain on iOS)
- Biometric authentication gate available before accessing the app
- Firebase Security Rules enforce server-side authorization
- No raw financial credentials are ever stored
- GDPR / CCPA compliant data model — user data deletion on account removal

---

## 🤝 Contributing

This is a private project. For collaboration inquiries, please open an issue or contact the maintainer directly.

---

## 📄 License

Private — All rights reserved © RaptorBlingx

---

<div align="center">
  <sub>Built with ❤️ using Flutter · Firebase · Gemini AI</sub>
</div>

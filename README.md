# Fin Co-Pilot

Fin Co-Pilot is an AI-assisted personal finance application built with Flutter, Firebase, and Gemini through Firebase AI. The current product focuses on fast transaction capture, receipt scanning, budgeting, coaching, and reporting across Android, iOS, and web targets.

## What the app does

- Conversational transaction entry from natural language
- Manual transaction entry
- Push-to-talk voice input inside transaction capture
- Receipt OCR and AI-assisted extraction
- Dashboard with recent activity, spending summary, and insight cards
- Monthly budgets and category allocation
- Spending insights with charts and period filters
- AI coaching plus a curated tip library
- Notification preferences, budget alerts, and scheduled coaching tips
- PDF and CSV report export

## Current scope

The repository includes exploratory or partially implemented modules for price intelligence, shopping, subscriptions, health score, cash flow, and other future-facing ideas. Those areas are not the current public product scope and should be treated as feature-flagged or in-progress code unless they are explicitly enabled and verified.

## Platform targets

- Android
- iOS
- Web

## Stack

- Flutter and Dart
- Riverpod for state management
- GoRouter for navigation
- Firebase Auth, Firestore, Storage, Cloud Messaging, Cloud Functions, Hosting, Analytics, and Crashlytics
- Firebase AI with Gemini models for orchestration, coaching, receipt parsing, and report generation
- fl_chart, shimmer, lottie, speech_to_text, and related UI and input packages

## Architecture snapshot

- `lib/features/` contains user-facing flows such as auth, dashboard, budget, insights, reports, receipts, coaching, notifications, and settings.
- `lib/services/` contains orchestration, AI agents, transaction and report helpers, notification handling, and backend integration.
- `functions/` contains scheduled Firebase Cloud Functions for weekly coaching tips and daily budget alert workflows.
- `lib/core/config/features_config.dart` is the main place to check which features are actually enabled.

## Getting started

### Prerequisites

- Flutter SDK compatible with Dart `^3.5.4`
- Firebase CLI
- Node.js 18 if you want to run or deploy Cloud Functions
- A Firebase project with the services you plan to use enabled

### Local setup

1. Install Flutter dependencies:

	```bash
	flutter pub get
	```

2. Install Cloud Functions dependencies:

	```bash
	cd functions
	npm install
	cd ..
	```

3. Configure Firebase for your own project.

	- This repository is wired to Firebase services, but public contributors should point the app at their own Firebase project.
	- Regenerate `lib/firebase_options.dart` and the platform Firebase config files with the FlutterFire CLI, or replace them with your own project configuration.
	- If you want the full feature set locally, enable Auth, Firestore, Storage, Cloud Messaging, Analytics, Crashlytics, Hosting, and Firebase AI in Firebase.

4. Run the app:

	```bash
	flutter run
	```

## Common commands

```bash
flutter analyze
flutter test
flutter run
flutter build apk

cd functions
npm run serve

firebase deploy --only functions
firebase deploy --only hosting
```

## Repository layout

```text
lib/
  core/
  features/
  models/
  services/
  shared/
functions/
assets/
test/
```

## Notes

- Public documentation is intentionally lean. The codebase and feature flags are the source of truth.
- Good starting points for code review are `lib/main.dart`, `lib/core/config/features_config.dart`, `lib/services/financial_copilot_orchestrator.dart`, and the screens under `lib/features/`.

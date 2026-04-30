# FinCoPilot Agent Guide

## Start Here

- Read [README.md](README.md) for product overview, setup, and standard commands.
- Read [VOICE_INPUT_INTEGRATION.md](VOICE_INPUT_INTEGRATION.md) before changing speech input or transcription flows.
- Use these anchors before broad exploration:
  - [lib/main.dart](lib/main.dart) for app bootstrap, Firebase initialization, routing, and theme wiring
  - [lib/core/providers/app_providers.dart](lib/core/providers/app_providers.dart) for shared Riverpod providers
  - [lib/core/config/features_config.dart](lib/core/config/features_config.dart) for feature flags and release gating
  - [lib/core/navigation/app_navigation.dart](lib/core/navigation/app_navigation.dart) for shell navigation
  - [lib/services/financial_copilot_orchestrator.dart](lib/services/financial_copilot_orchestrator.dart) for the main AI orchestration flow
  - [functions/index.js](functions/index.js) for scheduled Firebase Functions

## Commands

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run`
- `flutter build apk`
- `cd functions && npm install`
- `cd functions && npm run serve`
- `cd functions && npm run deploy`

## Architecture

- Treat `lib/features/` as the primary unit of organization. Prefer extending the owning feature instead of creating new top-level layers.
- Shared app services live in `lib/services/`; global providers live in `lib/core/providers/`; app-wide config, navigation, and theming live in `lib/core/`.
- The Flutter app uses Riverpod and GoRouter throughout. Match existing provider and routing patterns before introducing new abstractions.
- Respect [lib/core/config/features_config.dart](lib/core/config/features_config.dart) when enabling routes, UI, or services. Several v2 features exist in code but are intentionally gated off.

## Project-Specific Gotchas

- The `record_platform_interface: 1.2.0` override in `pubspec.yaml` is intentional. Do not remove it casually when touching audio dependencies.
- Android builds are configured for Java 17 and `minSdkVersion 23`; keep Android and plugin changes compatible with that toolchain.
- Firestore field naming is not fully uniform across older code paths. Check the owning model, query, and function before renaming or reusing fields across app and Functions code.
- Do not regenerate `lib/firebase_options.dart` unless the task explicitly involves Firebase project reconfiguration.
---
description: "Use when editing Flutter app code in lib/ or test/, including Riverpod providers, GoRouter routes, screens, services, Firebase integration, or UI flows."
applyTo: lib/**/*.dart, test/**/*.dart
---

# Dart App Guidelines

- Keep feature work inside the owning `lib/features/<feature>/` module when possible. Move code into `lib/services/`, `lib/shared/`, or `lib/core/` only when it is genuinely cross-feature.
- Match existing Riverpod patterns before introducing new state objects. Shared dependencies usually live in [lib/core/providers/app_providers.dart](../../lib/core/providers/app_providers.dart).
- Follow the main GoRouter setup in [lib/main.dart](../../lib/main.dart) and the navigation shell in [lib/core/navigation/app_navigation.dart](../../lib/core/navigation/app_navigation.dart) instead of adding ad hoc navigation paths.
- Check [lib/core/config/features_config.dart](../../lib/core/config/features_config.dart) before exposing unfinished features. If a feature is flagged off, keep UI, routes, and services gated the same way.
- Preserve the existing naming pattern: `*_screen.dart`, `*_service.dart`, and `*_agent.dart`.
- Preserve the existing Material 3 theme and shared widgets instead of introducing a parallel styling system.
- Validate Dart changes with the smallest relevant command first, usually `flutter analyze` and then a focused `flutter test` when behavior changes.
- For voice or transcription work, consult [VOICE_INPUT_INTEGRATION.md](../../VOICE_INPUT_INTEGRATION.md) instead of re-deriving the pipeline.
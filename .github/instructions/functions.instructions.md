---
description: "Use when editing Firebase Cloud Functions code in functions/, including scheduled jobs, notification delivery, Firestore maintenance, or functions/package.json scripts."
applyTo: functions/**/*.js, functions/package.json
---

# Firebase Functions Guidelines

- Runtime is Node 18. Use the scripts in [functions/package.json](../../functions/package.json): `npm install`, `npm run serve`, `npm run deploy`, and `npm run logs`.
- Keep the current CommonJS style in [functions/index.js](../../functions/index.js) unless the task is an explicit module-system migration.
- This codebase currently uses a single [functions/index.js](../../functions/index.js) entrypoint with scheduled Pub/Sub jobs. Extend the existing structure carefully instead of splitting files by default.
- Scheduled jobs set an explicit timezone. Preserve the current timezone behavior unless the task is specifically about scheduling semantics.
- Follow the existing notification pattern: send through the Admin SDK, then log the sent notification to Firestore when that flow already exists for the job.
- Check Firestore field names against the client and service code before changing queries. Older paths mix camelCase and snake_case style fields.
- Validate Functions changes with the narrowest relevant command first, usually `cd functions && npm run serve` when behavior depends on the emulator.
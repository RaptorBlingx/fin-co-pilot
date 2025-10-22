# Fin Copilot v3 - Knowledge Base
## Complete Development Blueprint & Technical Documentation

**Version:** 3.0
**Last Updated:** October 22, 2025
**Status:** Active - MVP Ready for Development

---

## Overview

This Knowledge Base contains **comprehensive documentation** for Fin Copilot v3, a financial wellness companion that reduces anxiety through zero-effort tracking.

**What's New in v3:**
- Simplified 3-agent architecture (from 9 agents)
- SMS auto-parsing (80% automatic capture)
- Daily Money Story (9 PM engagement)
- Financial Health Score (0-100 metric)
- Couples Dashboard + AI Mediator
- 12-week MVP roadmap (from 28 weeks)
- Direct Firebase AI (removed ADK/Genkit complexity)

**Core Differentiation:**
- 87% have financial anxiety → We reduce it
- Zero manual entry via SMS parsing
- Proactive warnings before problems
- Emotional intelligence (detect stress spending)
- Supportive tone, never judgmental

---

## Core Documentation

### 1. [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)
**Vision & Strategic Foundation**

- Problem: 87% have financial anxiety, 48% couples fight about money
- Solution: Financial wellness companion (not just tracker)
- Target users: 5 research-based personas
- Competitive analysis: vs Mint, YNAB, Monarch, Rocket Money
- Success metrics: Anxiety reduction, not feature count
- Technology: Firebase AI Logic + Gemini 2.5

**Key Insights:**
- Users want less anxiety, not more features
- 80% automatic capture = killer feature
- Proactive > reactive (prevent problems before they happen)
- Couples features = 48% market opportunity

---

### 2. [FEATURES_SPECIFICATION.md](FEATURES_SPECIFICATION.md)
**10 Core Features (All P0 for MVP)**

**Weeks 1-3:**
1. **SMS Auto-Parsing** - 80% automatic transaction capture
2. **Voice Entry** - Zero-friction voice input
3. **Financial Health Score** - 0-100 metric with breakdown

**Weeks 4-6:**
4. **Smart Nudges** - Proactive warnings before overspending
5. **Predictive Cash Flow** - Days until $0, prevent overdrafts

**Weeks 7-9:**
6. **Money Story** - Daily 9 PM narrative summary
7. **Subscription Detection** - Find $500/year waste

**Weeks 10-12:**
8. **Receipt Intelligence** - Price comparison, market averages
9. **Couples Dashboard** - Shared visibility, financial transparency
10. **AI Mediator** - Conflict resolution for couples

**For Each Feature:**
- User story
- Functional requirements
- UI flow examples
- Acceptance criteria
- Success metrics

---

### 3. [ARCHITECTURE.md](ARCHITECTURE.md)
**Simplified 3-Agent System**

**High-Level:**
- Flutter 3.32+ → Firebase AI Logic → 3 Agents → Cloud Functions → Firestore
- No orchestration overhead
- Direct function calling
- <1 sec response times

**Technology Stack:**
- Frontend: Flutter 3.32+, firebase_ai ^3.4.0, riverpod, go_router
- Backend: Cloud Functions (Node.js 20), Firestore, Firebase Storage
- AI: Gemini 2.5 Flash (Copilot + Analyst), Gemini 2.5 Flash-Lite (Vision)

**3-Agent Architecture:**

1. **Financial Copilot Agent** (Gemini 2.5 Flash)
   - Main intelligence (80% of interactions)
   - Transaction extraction + validation in 1 call
   - Multi-turn conversations with context
   - Function calling: saveTransaction, getBudget, getPredictedCashFlow, etc.
   - Emotional intelligence, anxiety reduction
   - Temp: 0.7, TopK: 40, MaxTokens: 512

2. **Vision Agent** (Gemini 2.5 Flash-Lite)
   - Receipt OCR only (15% of interactions)
   - Extract items, prices, merchant, date
   - Pass to Copilot for price analysis
   - Temp: 0.2 (low for accuracy), MaxTokens: 2048

3. **Analyst Agent** (Gemini 2.5 Flash)
   - Background analysis (5% of interactions)
   - Daily Money Story (9 PM scheduled)
   - Weekly Pattern Analysis (Sunday 8 PM)
   - Anomaly Detection (Firestore triggers)
   - Temp: 0.4, MaxTokens: 1024

**Why 3 Agents Work:**
- OLD (9 agents): 4 sequential API calls, 3-5 sec, $0.004/transaction
- NEW (3 agents): 1 API call, <1 sec, $0.0008/transaction
- Result: 5x cheaper, 3x faster, simpler codebase

**Performance Targets:**
- App launch: <2 sec
- AI response (simple): <1 sec
- Voice processing: <3 sec
- Receipt OCR: <5 sec
- SMS parsing: <2 sec

---

### 4. [AI_AGENTS_SPECIFICATION.md](AI_AGENTS_SPECIFICATION.md)
**Complete Agent System Prompts & Configuration**

**Financial Copilot Agent:**
```
CORE PERSONALITY:
- Supportive and encouraging, never judgmental
- Reduce anxiety, don't increase it
- Celebrate wins, gentle on overspending
- Like a friend who genuinely cares

PRIMARY FUNCTIONS:
1. Transaction Extraction - Parse natural language
2. Financial Queries - "How much on coffee this week?"
3. Guidance & Support - Budget checks before purchases

EXTRACTION RULES:
- Categories: Coffee, Dining, Groceries, Transport, etc.
- Infer merchant from context
- Handle various amount formats

RESPONSE STYLE:
- Conversational, warm, brief (2-3 sentences)
- Use 1 emoji max per response
- "Got it! $15 for lunch at Chipotle 🌯"

EMOTIONAL INTELLIGENCE:
- Detect stress spending patterns
- Offer pause prompts
- Celebrate restraint

ANXIETY REDUCTION:
- Frame everything positively
- "You're doing great" > "You're overspending"
```

**All 3 Agents Include:**
- Complete system prompts (production-ready)
- Function declarations (saveTransaction, getTransactions, getBudget, etc.)
- Configuration parameters (temperature, topK, topP, maxOutputTokens)
- Usage examples (1-agent, 2-agent, background scenarios)
- Cloud Function schedules (9 PM daily, Sunday 8 PM weekly)

---

### 5. [DATA_MODELS.md](DATA_MODELS.md)
**16 Firestore Collections (Up from 8 in v2)**

**Core Collections:**
1. `users` - User profiles + SMS permission + Financial Health + Couple account
2. `transactions` - Transaction data + SMS source + AI agent tracking
3. `budgets` - Budget configurations
4. `chat_messages` - AI conversations (simplified, no sessions)

**NEW in v3:**
5. `sms_transactions` - SMS auto-parsing pending confirmations
6. `money_stories` - Daily 9 PM narrative summaries
7. `subscriptions` - Recurring charge detection
8. `financial_health_scores` - Historical 0-100 score tracking
9. `smart_nudges` - Proactive warnings
10. `stress_logs` - Emotional spending tracking
11. `couple_accounts` - Couples Dashboard feature
12. `coaching_tips` - Contextual coaching library

**Existing (Updated):**
13. `insights` - AI-generated insights (now includes agent attribution)
14. `watchlist` - Price Intelligence (receipt price tracking)
15. `notifications` - Push notifications log
16. `user_patterns` - ML-generated spending patterns

**For Each Collection:**
- TypeScript interfaces
- Dart model classes
- Field descriptions
- Firestore indexes
- Security rules

---

### 6. [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md)
**12-Week MVP Plan (Down from 28 Weeks)**

**Weeks 1-3: Foundation + Killer Features**
- Week 1: Project setup, authentication, core infrastructure
- Week 2: SMS auto-parsing (80% automatic capture)
- Week 3: Voice entry + Financial Health Score

**Weeks 4-6: Proactive Intelligence**
- Week 4: Smart Nudges (real-time budget warnings)
- Week 5: Predictive Cash Flow (days until $0)
- Week 6: Enhanced Insights (weekly pattern analysis)

**Weeks 7-9: Daily Engagement**
- Week 7: Money Story (9 PM daily summaries)
- Week 8: Subscription Detection ($500/year savings)
- Week 9: Coaching Tips (100+ tips library)

**Weeks 10-12: Social + Launch**
- Week 10: Receipt Intelligence (price comparison)
- Week 11: Couples Dashboard + AI Mediator
- Week 12: Polish + Launch Prep

**For Each Week:**
- Day-by-day tasks
- Deliverables
- Success metrics
- Risk mitigation

**Launch Target:** Week 12, all features operational, >99.5% stability

---

## Supporting Documentation

### 7. GLOBAL_PAIN_POINTS_ANALYSIS.md ✅
**Research Foundation**
- 87% have financial anxiety
- 70% experience it weekly
- 48% couples fight about money
- $500/year wasted on subscriptions
- 50% emotionally spend when stressed
- 24% reverted to spreadsheets (apps too complex)

### 8. AGENT_ARCHITECTURE_V2_SIMPLIFIED.md ✅
**Architecture Decision Record**
- Why 9 agents is wrong
- 3-agent solution rationale
- Cost analysis (94% savings)
- 10 killer features fully specified

### 9. UI_UX_DESIGN_SYSTEM.md
*(To be created Week 1)*
- Material Design 3 implementation
- Color schemes (light/dark)
- Typography scale
- Component library
- Animation guidelines

### 10. SECURITY_PRIVACY.md
*(To be created Week 1)*
- Encryption standards (AES-256, TLS 1.3)
- Biometric authentication
- Firestore security rules
- GDPR compliance
- Privacy policy

### 11. TESTING_STRATEGY.md
*(To be created Week 2)*
- Unit tests (>80% coverage)
- Widget tests
- Integration tests
- E2E tests
- AI agent evaluation

---

## How to Use This Knowledge Base

### For New Team Members

**Day 1: Strategic Context**
1. Read [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) - Vision, problem, solution
2. Read [GLOBAL_PAIN_POINTS_ANALYSIS.md](GLOBAL_PAIN_POINTS_ANALYSIS.md) - Research foundation

**Day 2: Product Understanding**
3. Read [FEATURES_SPECIFICATION.md](FEATURES_SPECIFICATION.md) - What we're building
4. Read [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md) - 12-week plan

**Day 3: Technical Deep Dive**
5. Read [ARCHITECTURE.md](ARCHITECTURE.md) - 3-agent system, tech stack
6. Read [AI_AGENTS_SPECIFICATION.md](AI_AGENTS_SPECIFICATION.md) - Agent prompts
7. Read [DATA_MODELS.md](DATA_MODELS.md) - Database schema

**Day 4: Start Building**
8. Review current week's tasks in roadmap
9. Implement according to specifications

### For AI Development Assistants

**Context Loading Order:**
1. PROJECT_OVERVIEW.md - Mission and vision
2. FEATURES_SPECIFICATION.md - Feature requirements
3. ARCHITECTURE.md - Technical architecture
4. AI_AGENTS_SPECIFICATION.md - Agent system
5. DATA_MODELS.md - Database schema
6. IMPLEMENTATION_ROADMAP.md - Current phase

**When Implementing:**
1. Find feature in FEATURES_SPECIFICATION.md
2. Review architecture in ARCHITECTURE.md
3. Check data models in DATA_MODELS.md
4. Review agent specs in AI_AGENTS_SPECIFICATION.md
5. Follow roadmap in IMPLEMENTATION_ROADMAP.md
6. Implement according to specifications

### Development Workflows

**Implementing SMS Auto-Parsing:**
```
1. FEATURES_SPECIFICATION.md → Section 1 (SMS Auto-Parsing)
2. ARCHITECTURE.md → SMS Monitoring Architecture
3. DATA_MODELS.md → sms_transactions Collection
4. AI_AGENTS_SPECIFICATION.md → Financial Copilot Agent
5. IMPLEMENTATION_ROADMAP.md → Week 2 Tasks
6. Implement: SMS listener → Parse → Confirm → Save
7. Test: 80% capture rate, 95% accuracy, <2 sec
```

**Creating Money Story Feature:**
```
1. FEATURES_SPECIFICATION.md → Section 6 (Money Story)
2. ARCHITECTURE.md → Cloud Functions Schedule
3. DATA_MODELS.md → money_stories Collection
4. AI_AGENTS_SPECIFICATION.md → Analyst Agent
5. IMPLEMENTATION_ROADMAP.md → Week 7 Tasks
6. Implement: Cloud Function (9 PM) → Generate → Save → Notify
7. Test: Daily generation, >60% open rate
```

---

## Project Status

### Current Phase
**Phase 0: Documentation** ✅ COMPLETE
- All v3 documentation updated
- 3-agent architecture finalized
- 12-week roadmap approved
- Ready to begin Week 1

### Next Milestone
**Week 1: Foundation** (Days 1-5)
- Project setup
- Firebase configuration
- Authentication
- Core infrastructure
- Theme system

### Overall Progress
```
Documentation:    ████████████████████ 100%
Week 1:           ░░░░░░░░░░░░░░░░░░░░   0%
Week 2:           ░░░░░░░░░░░░░░░░░░░░   0%
Week 3:           ░░░░░░░░░░░░░░░░░░░░   0%
Week 4-6:         ░░░░░░░░░░░░░░░░░░░░   0%
Week 7-9:         ░░░░░░░░░░░░░░░░░░░░   0%
Week 10-12:       ░░░░░░░░░░░░░░░░░░░░   0%
Overall:          ████░░░░░░░░░░░░░░░░  20%
```

---

## v3 Improvements Summary

| Aspect | v2 (Old) | v3 (New) | Improvement |
|--------|----------|----------|-------------|
| **Agents** | 9 agents (Orchestrator + 8 specialized) | 3 agents (Copilot, Vision, Analyst) | 5x cost reduction |
| **Response Time** | 3-5 sec (4 sequential calls) | <1 sec (1 call) | 3x faster |
| **Cost** | $0.004 per transaction | $0.0008 per transaction | 5x cheaper |
| **Architecture** | ADK + Genkit (complex) | Direct Firebase AI (simple) | Simpler maintenance |
| **Features** | 5 core features | 10 killer features | 2x more value |
| **Roadmap** | 28 weeks (6 phases) | 12 weeks (1 MVP) | 2.3x faster to market |
| **Killer Feature** | Price Intelligence | SMS Auto-Parsing (80% capture) | True differentiation |
| **Value Prop** | "Track spending" | "Reduce anxiety" | Emotional connection |
| **Target Users** | General users | 5 specific personas | Focused positioning |
| **Collections** | 8 Firestore collections | 16 collections | Richer features |

**Result:** Faster, cheaper, simpler, more valuable.

---

## Success Metrics

### Development Metrics
- Sprint velocity: 1 feature per week
- Code coverage: >80%
- Bug density: <1 per 100 LOC
- CI/CD: <15 min build
- PR review: <24 hours

### Performance Metrics
- App launch: <2 sec
- AI response: <1 sec (simple), <3 sec (complex)
- Voice processing: <3 sec
- Receipt OCR: <5 sec
- SMS parsing: <2 sec
- Crash-free: >99.5%

### User Engagement Metrics
- DAU/MAU: >30%
- 30-day retention: >70%
- SMS auto-capture rate: >80%
- Daily Money Story open rate: >60%
- Financial Health Score improvement: >15 points in 30 days

### Business Metrics
- App store rating: >4.5 stars
- NPS: >60
- Feature adoption: >60% within 1 week
- Average session time: >5 min

---

## Related Resources

### External Documentation

**Google AI:**
- [Firebase AI Logic](https://firebase.google.com/docs/ai-logic)
- [Gemini API](https://ai.google.dev/docs)
- [Vertex AI](https://cloud.google.com/vertex-ai/docs)

**Flutter:**
- [Flutter Docs](https://docs.flutter.dev/)
- [Material Design 3](https://m3.material.io/develop/flutter)
- [Riverpod](https://riverpod.dev/)
- [go_router](https://pub.dev/packages/go_router)

**Firebase:**
- [Firebase Docs](https://firebase.google.com/docs)
- [Cloud Functions](https://firebase.google.com/docs/functions)
- [Firestore](https://firebase.google.com/docs/firestore)
- [Cloud Scheduler](https://cloud.google.com/scheduler/docs)

### Internal Research
- [GOOGLE_AI_SOTA_RESEARCH_AND_MIGRATION_PLAN.md](../GOOGLE_AI_SOTA_RESEARCH_AND_MIGRATION_PLAN.md)
- [GLOBAL_PAIN_POINTS_ANALYSIS.md](GLOBAL_PAIN_POINTS_ANALYSIS.md)
- [AGENT_ARCHITECTURE_V2_SIMPLIFIED.md](AGENT_ARCHITECTURE_V2_SIMPLIFIED.md)

---

## Quality Standards

### Documentation
✅ Consistent formatting across all documents
✅ Code examples tested and verified
✅ Clear diagrams and flow charts
✅ Accurate cross-references
✅ Version control maintained

### Implementation
- Code coverage: >80%
- Documentation coverage: 100%
- Performance targets met
- Security standards followed
- Accessibility compliance (WCAG 2.1 AA)

---

## Document Control

| Document | Version | Last Updated | Status |
|----------|---------|--------------|--------|
| README.md | 3.0 | 2025-10-22 | Active |
| PROJECT_OVERVIEW.md | 3.0 | 2025-10-22 | Active |
| FEATURES_SPECIFICATION.md | 3.0 | 2025-10-22 | Active |
| ARCHITECTURE.md | 3.0 | 2025-10-22 | Active |
| AI_AGENTS_SPECIFICATION.md | 3.0 | 2025-10-22 | Active |
| DATA_MODELS.md | 3.0 | 2025-10-22 | Active |
| IMPLEMENTATION_ROADMAP.md | 3.0 | 2025-10-22 | Active |
| GLOBAL_PAIN_POINTS_ANALYSIS.md | 1.0 | 2025-10-21 | Active |
| AGENT_ARCHITECTURE_V2_SIMPLIFIED.md | 1.0 | 2025-10-21 | Active |

---

## Quick Reference

### Most Referenced Sections
- [SMS Auto-Parsing](FEATURES_SPECIFICATION.md#1-sms-auto-parsing)
- [Financial Copilot Agent Prompt](AI_AGENTS_SPECIFICATION.md#financial-copilot-agent)
- [3-Agent Architecture Diagram](ARCHITECTURE.md#system-architecture)
- [Firestore Collections](DATA_MODELS.md#firestore-collections)
- [Week-by-Week Tasks](IMPLEMENTATION_ROADMAP.md#weeks-1-3-foundation--killer-features)

### Critical Workflows
- [Transaction Entry Flow](ARCHITECTURE.md#transaction-entry-via-voice)
- [Receipt Scanning Flow](ARCHITECTURE.md#receipt-scanning)
- [SMS Auto-Parsing Flow](ARCHITECTURE.md#sms-auto-parsing)
- [Daily Money Story Generation](ARCHITECTURE.md#daily-money-story-background)

### Key Decisions
- [Why 3 Agents vs 9](AGENT_ARCHITECTURE_V2_SIMPLIFIED.md)
- [Why SMS Auto-Parsing First](FEATURES_SPECIFICATION.md#priority-matrix)
- [Why 12 Weeks vs 28](IMPLEMENTATION_ROADMAP.md#overview)
- [Why Anxiety Reduction](GLOBAL_PAIN_POINTS_ANALYSIS.md)

---

**Welcome to Fin Copilot v3 Development!** 🚀

This Knowledge Base provides everything needed to build a financial wellness companion that reduces anxiety through zero-effort tracking. The simplified 3-agent architecture enables rapid development while the 12-week roadmap keeps us focused on MVP delivery.

**Core Mission:** Reduce financial anxiety for 87% of users through proactive intelligence and zero-effort tracking.

**Launch Target:** 12 weeks, all 10 killer features operational, >99.5% stability.

Let's build something that genuinely helps people! 💙

---

**Last Updated:** October 22, 2025
**Next Review:** Week 1 Start

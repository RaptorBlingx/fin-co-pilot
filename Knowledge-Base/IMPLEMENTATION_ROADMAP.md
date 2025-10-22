# Fin Copilot v3 - Implementation Roadmap

**Last Updated:** October 22, 2025
**Version:** 3.0 (12-Week MVP Plan)

---

## Overview

12-week sprint to MVP focusing on anxiety reduction and zero-effort tracking. All features are P0 (must-have for launch).

### Timeline Summary

```
Weeks 1-3:   Foundation + Killer Features (SMS, Voice, Health Score)
Weeks 4-6:   Proactive Intelligence (Nudges, Cash Flow, Insights)
Weeks 7-9:   Daily Engagement (Money Story, Subscriptions, Patterns)
Weeks 10-12: Social + Launch (Couples, Polish, Launch Prep)
```

### Core Principles

**1. Simplicity First**
- 3 agents (not 9)
- Direct Firebase AI (no ADK/Genkit complexity)
- Feature complete > feature rich

**2. Speed Matters**
- <1 sec AI responses
- <3 sec voice input
- <5 sec receipt OCR

**3. Anxiety Reduction**
- Every feature reduces stress
- Proactive > reactive
- Supportive tone always

---

## Weeks 1-3: Foundation + Killer Features 🚀

### Objective
Launch with SMS auto-parsing (80% capture) + voice entry + Financial Health Score.

### Week 1: Foundation

**Days 1-2: Project Setup**
- [x] Firebase project (dev, staging, prod)
- [x] Flutter 3.32+ project init
- [x] firebase_ai: ^3.4.0 configured
- [x] Firestore collections created
- [x] Security rules deployed
- [ ] CI/CD pipeline (GitHub Actions)

**Days 3-5: Core Infrastructure**
- [ ] Authentication (Email, Google, Apple, Biometric)
- [ ] Onboarding flow (4 screens max)
- [ ] Dashboard shell
- [ ] Navigation (go_router)
- [ ] Theme system (Material Design 3)
- [ ] Error handling & logging

### Week 2: SMS Auto-Parsing (Killer Feature #1)

**Days 1-2: SMS Permission & Monitoring**
- [ ] SMS permission request (onboarding step 3)
- [ ] sms_advanced package integration
- [ ] Background SMS listener
- [ ] Bank SMS format detection (10+ banks)

**Days 3-5: Parsing & Confirmation**
- [ ] Financial Copilot Agent: SMS parsing
- [ ] Extract: amount, merchant, date, card last 4
- [ ] Save to sms_transactions collection
- [ ] Push notification: "☕ $5.50 at Starbucks - Coffee? [YES] [NO]"
- [ ] One-tap confirmation → save to transactions
- [ ] Test with 10 bank formats

**Target:** 80% automatic capture, 95%+ accuracy, <2 sec processing

### Week 3: Voice Entry + Financial Health Score

**Days 1-2: Voice Entry (Killer Feature #2)**
- [ ] speech_to_text integration
- [ ] Voice input button (FAB)
- [ ] Recording UI animation
- [ ] Text preview + edit
- [ ] Send to Financial Copilot Agent
- [ ] Extract transaction + save

**Days 3-5: Financial Health Score (Killer Feature #3)**
- [ ] Score calculation algorithm (0-100)
  - Budget adherence: 0-25
  - Savings rate: 0-25
  - Debt management: 0-25
  - Spending stability: 0-25
- [ ] financial_health_scores collection
- [ ] Dashboard score display (circular progress)
- [ ] Breakdown screen (tap to see details)
- [ ] Weekly recalculation (Cloud Function)

**Target:** <3 sec voice processing, Health Score updates weekly

### Week 3 Deliverables
✅ SMS auto-parsing live (80% capture)
✅ Voice entry functional
✅ Financial Health Score displayed
✅ 3-agent system operational
✅ Core transactions + budgets working

---

## Weeks 4-6: Proactive Intelligence 🧠

### Objective
Make app proactive with Smart Nudges + Predictive Cash Flow + Enhanced Insights.

### Week 4: Smart Nudges (Killer Feature #4)

**Days 1-3: Nudge Detection**
- [ ] Real-time budget monitoring
- [ ] Firestore trigger: onTransactionCreate
- [ ] Smart nudge generation (Analyst Agent)
- [ ] Nudge types:
  - Budget warning: "You're at 90% of your dining budget"
  - Impulse alert: "You've spent $200 on shopping in 3 days"
  - Bill reminder: "Netflix due tomorrow"
  - Savings opportunity: "You could save $50/month"

**Days 4-5: Nudge UI**
- [ ] Push notifications
- [ ] In-app banner
- [ ] Nudge screen (history)
- [ ] Dismiss/act actions
- [ ] Snooze functionality

### Week 5: Predictive Cash Flow (Killer Feature #5)

**Days 1-3: Prediction Algorithm**
- [ ] Calculate daily burn rate
- [ ] Project balance to $0
- [ ] Factor in recurring expenses
- [ ] Factor in expected income
- [ ] getPredictedCashFlow() function (Copilot Agent)

**Days 4-5: Cash Flow UI**
- [ ] Dashboard card: "X days until $0"
- [ ] Cash flow chart (fl_chart)
- [ ] Color-coded warnings (red <7 days, yellow <14 days)
- [ ] "What if" scenarios
- [ ] Alert notifications

**Target:** 85%+ prediction accuracy, 7-day lookahead minimum

### Week 6: Enhanced Insights

**Days 1-3: Pattern Detection**
- [ ] Pattern Learner Agent (runs weekly)
- [ ] Detect spending patterns by category
- [ ] Detect peak days/times
- [ ] Detect stress spending triggers
- [ ] Save to user_patterns collection

**Days 4-5: Insight Generation**
- [ ] Weekly insights (Cloud Function: Sunday 8 PM)
- [ ] Analyst Agent: analyze patterns + generate insights
- [ ] Insight types: achievements, trends, recommendations
- [ ] Insights screen UI
- [ ] Insight cards with actions

### Week 6 Deliverables
✅ Smart Nudges operational
✅ Predictive Cash Flow live
✅ Weekly insights generated
✅ Pattern detection working
✅ <1 sec nudge delivery

---

## Weeks 7-9: Daily Engagement 📖

### Objective
Daily Money Story + Subscription Detection + Coaching Tips.

### Week 7: Money Story (Killer Feature #6)

**Days 1-3: Story Generation**
- [ ] Cloud Function: generateMoneyStory (9 PM daily)
- [ ] Analyst Agent: create narrative from today's transactions
- [ ] money_stories collection
- [ ] Story format:
  ```
  Today's Money Story 📖
  You spent $87 today
  • $5.50 - Coffee ☕ Starbucks
  • $15 - Lunch 🌯 Chipotle
  • $66.50 - Groceries 🛒 Whole Foods

  Top category: Groceries ($66.50)
  This week: $342

  You're $58 under budget this week! Keep it up! 🎉
  ```

**Days 4-5: Story UI**
- [ ] Push notification (9 PM)
- [ ] Story screen (inbox)
- [ ] Story history (calendar view)
- [ ] Share story (social media)
- [ ] Story settings (enable/disable, time)

### Week 8: Subscription Detection (Killer Feature #7)

**Days 1-3: Detection Algorithm**
- [ ] Cloud Function: detectSubscriptions (weekly)
- [ ] Analyze recurring charges (same merchant, similar amount)
- [ ] Frequency detection (weekly, monthly, yearly)
- [ ] subscriptions collection
- [ ] Next charge prediction

**Days 4-5: Subscription UI**
- [ ] Subscriptions screen (list view)
- [ ] Subscription card: merchant, amount, frequency, next charge
- [ ] Total monthly cost (prominent display)
- [ ] "Cancel" links (if found)
- [ ] Potential savings calculator
- [ ] Alert: "You're spending $500/year on subscriptions you rarely use"

### Week 9: Coaching Tips (Killer Feature #8)

**Days 1-3: Coaching Library**
- [ ] coaching_tips collection (pre-populate 100 tips)
- [ ] Categories: budgeting, impulse, savings, debt, stress
- [ ] Trigger conditions (over_budget, impulse_spending, etc.)
- [ ] Copilot Agent: context-aware tip selection

**Days 4-5: Coaching UI**
- [ ] Tips screen (browse library)
- [ ] Tip cards with actions
- [ ] Contextual tips in chat
- [ ] Tip bookmarking
- [ ] Tip effectiveness rating

### Week 9 Deliverables
✅ Daily Money Story at 9 PM
✅ Subscription detection working
✅ Coaching tips library live
✅ 100+ tips pre-populated
✅ Daily user engagement >60%

---

## Weeks 10-12: Social + Launch 👥

### Objective
Receipt Intelligence + Couples Dashboard + AI Mediator + Launch Prep.

### Week 10: Receipt Intelligence (Killer Feature #9)

**Days 1-2: Receipt Scanning**
- [ ] Camera integration (image_picker)
- [ ] Receipt capture screen
- [ ] Vision Agent: OCR extraction
- [ ] Extract: items, prices, merchant, date, subtotal, tax, total
- [ ] Save to Firebase Storage

**Days 3-5: Price Intelligence**
- [ ] Price comparison (Financial Copilot Agent)
- [ ] Market average calculation (across all users)
- [ ] Price analysis: "You paid $4.99 for milk - $1.20 more than Trader Joe's"
- [ ] watchlist collection
- [ ] Receipt review screen (confirm items)
- [ ] Save items to watchlist

**Target:** <5 sec OCR processing, 90%+ extraction accuracy

### Week 11: Couples Dashboard + AI Mediator (Killer Feature #10)

**Days 1-2: Couples Pairing**
- [ ] Invite partner flow (email/link)
- [ ] couple_accounts collection
- [ ] Accept/decline invitation
- [ ] Shared visibility settings (full/summary)
- [ ] Connect accounts

**Days 3-5: Couples Features**
- [ ] Couples Dashboard (shared view)
- [ ] "Your Spending" vs "Partner's Spending"
- [ ] Shared budgets
- [ ] Large spend notifications
- [ ] AI Mediator: detect conflicts (e.g., "Partner overspent on dining")
- [ ] AI Mediator: generate advice
- [ ] Mediator screen (conflict history + resolutions)

**Target:** <1 sec conflict detection, supportive tone always

### Week 12: Launch Prep 🚀

**Days 1-2: Polish**
- [ ] UI/UX refinement
- [ ] Animations (page transitions, loading states)
- [ ] Haptic feedback
- [ ] Empty states
- [ ] Error states
- [ ] Accessibility audit (WCAG 2.1 AA)

**Days 3-4: Testing**
- [ ] Unit tests (>80% coverage)
- [ ] Widget tests
- [ ] Integration tests
- [ ] E2E tests (critical flows)
- [ ] Manual QA (checklist)
- [ ] Performance testing
- [ ] Bug fixes

**Day 5: Launch**
- [ ] App store listings (iOS + Android)
- [ ] Screenshots (5 per platform)
- [ ] App preview videos
- [ ] Privacy policy
- [ ] Terms of service
- [ ] Beta release (TestFlight + Play Console)
- [ ] Monitor crash rates & performance
- [ ] Public launch

### Week 12 Deliverables
✅ Receipt Intelligence live
✅ Couples Dashboard operational
✅ AI Mediator working
✅ All tests passing
✅ App store submitted
✅ <0.5% crash rate

---

## Feature Priority Matrix

All features are P0 (MVP). Order of implementation:

| Week | Feature | Why First |
|------|---------|-----------|
| 2 | SMS Auto-Parsing | 80% automatic capture - killer differentiation |
| 3 | Voice Entry + Health Score | Zero-friction entry + core value metric |
| 4 | Smart Nudges | Proactive anxiety reduction |
| 5 | Predictive Cash Flow | Prevent overdrafts (high anxiety trigger) |
| 6 | Enhanced Insights | Weekly value delivery |
| 7 | Money Story | Daily engagement hook |
| 8 | Subscription Detection | $500/year savings opportunity |
| 9 | Coaching Tips | Anxiety reduction + education |
| 10 | Receipt Intelligence | Price comparison = tangible savings |
| 11 | Couples Dashboard + AI Mediator | 48% fight about money - huge market |

---

## Technical Stack Checklist

### Frontend
- [x] Flutter 3.32+
- [x] firebase_ai: ^3.4.0
- [x] firebase_core: ^3.6.0
- [x] firebase_auth: ^5.7.0
- [x] cloud_firestore: ^5.4.4
- [ ] go_router: ^15.1.2
- [ ] riverpod: ^3.0.0
- [ ] fl_chart: ^0.68.0
- [ ] mobile_scanner: ^5.2.3
- [ ] speech_to_text: ^7.3.0
- [ ] sms_advanced: ^1.1.1
- [ ] image_picker: ^1.1.2
- [ ] flutter_local_notifications
- [ ] flutter_secure_storage: ^9.2.2

### Backend
- [ ] Cloud Functions (Node.js 20)
- [ ] Firestore (16 collections)
- [ ] Firebase Storage (receipts)
- [ ] Firebase Authentication
- [ ] Cloud Scheduler (cron jobs)

### AI
- [ ] Firebase AI Logic
- [ ] Gemini 2.5 Flash (Copilot + Analyst)
- [ ] Gemini 2.5 Flash-Lite (Vision)
- [ ] Function calling setup

---

## Cloud Functions Schedule

| Function | Schedule | Purpose |
|----------|----------|---------|
| generateMoneyStory | 9 PM daily | Daily Money Story notifications |
| weeklyAnalysis | Sunday 8 PM | Pattern analysis + insights |
| budgetAlerts | 8 AM daily | Morning budget check-ins |
| detectSubscriptions | Saturday 6 AM | Find recurring charges |
| calculateHealthScore | Monday 6 AM | Update Financial Health Score |

---

## Success Metrics

### Development
- Sprint velocity: Complete 1 feature per week
- Code coverage: >80%
- Bug density: <1 bug per 100 LOC
- PR review: <24 hours
- CI/CD: <15 min build

### Performance
- App launch: <2 sec
- AI response: <1 sec (simple), <3 sec (complex)
- Voice processing: <3 sec
- Receipt OCR: <5 sec
- SMS parsing: <2 sec
- Crash-free: >99.5%

### User Engagement
- DAU/MAU: >30%
- 30-day retention: >70%
- SMS auto-capture rate: >80%
- Daily Money Story open rate: >60%
- Financial Health Score improvement: >15 points in 30 days

### Business
- App store rating: >4.5 stars
- NPS: >60
- Feature adoption: >60% within 1 week
- Average session time: >5 min

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| SMS permissions denied | High | High | Fallback to voice/chat, emphasize value |
| AI accuracy below 95% | Medium | High | Continuous prompt tuning, user feedback |
| Performance issues | Medium | Medium | Early benchmarking, optimization sprints |
| Scope creep | High | High | Strict 12-week timeline, no feature adds |
| Timeline delays | Medium | High | 2 developers minimum, buffer tasks |

---

## Team Requirements

**Minimum Team:**
- 2 Flutter developers (full-time)
- 1 Backend developer (Cloud Functions, part-time)
- 1 UI/UX designer (part-time)
- 1 QA engineer (week 12 only)

**Recommended Team:**
- 3 Flutter developers
- 1 Backend developer (full-time)
- 1 UI/UX designer (full-time)
- 1 QA engineer (weeks 10-12)

---

## Post-MVP Roadmap (Weeks 13+)

### Week 13-16: Monetization (P1)
- Premium tier features
- Advanced insights
- Custom categories
- Data export (PDF/CSV)
- Ad-free experience

### Week 17-20: Expansion (P2)
- Multi-currency support
- Investment tracking
- Debt payoff planner
- Savings goals
- Bill splitting

### Week 21-24: Social (P2)
- Community features
- Shared budgets (beyond couples)
- Challenges (e.g., "No coffee for 7 days")
- Leaderboards
- Referral program

---

## Launch Checklist

### Technical
- [ ] All features tested (unit + integration + E2E)
- [ ] Performance targets met
- [ ] Security audit passed
- [ ] Privacy policy reviewed
- [ ] Terms of service finalized
- [ ] App store guidelines compliant
- [ ] Crashlytics configured
- [ ] Analytics configured
- [ ] Push notifications tested

### Marketing
- [ ] App store listings written
- [ ] Screenshots designed (5 per platform)
- [ ] App preview video recorded
- [ ] Landing page live
- [ ] Social media accounts created
- [ ] Press kit prepared
- [ ] Beta testers recruited (50+)
- [ ] Launch announcement ready

### Business
- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] GDPR compliance verified
- [ ] Support email set up
- [ ] Feedback mechanism in-app
- [ ] Pricing strategy finalized
- [ ] Refund policy defined

---

## Conclusion

This 12-week roadmap delivers a complete MVP focused on anxiety reduction through zero-effort tracking. Every feature is P0 (must-have). The simplified 3-agent architecture enables rapid development while maintaining quality.

**Key Differentiation:**
- SMS auto-parsing (80% automatic)
- Financial Health Score (0-100 metric)
- Daily Money Story (9 PM engagement)
- Couples features (48% market)
- Proactive anxiety reduction

**Launch Target:** Week 12, all features operational, >99.5% stability.

**End of Roadmap**

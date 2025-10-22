# Features Specification v3

**Last Updated:** October 22, 2025
**Status:** Ready for Implementation

---

## Priority Matrix

| Feature | Impact | Effort | Week |
|---------|--------|--------|------|
| SMS Auto-Parsing | Critical | M | 1-3 |
| Voice Entry | Critical | L | 1-3 |
| Financial Health Score | High | L | 4-6 |
| Smart Nudges | High | M | 4-6 |
| Predictive Cash Flow | High | M | 4-6 |
| Money Story | High | M | 4-6 |
| Subscription Detection | Medium | M | 7-9 |
| Receipt Scanning | Medium | M | 7-9 |
| Couples Dashboard | Medium | M | 10-12 |

---

## 1. SMS Auto-Parsing 🔥

**Goal:** Capture 80% of transactions automatically

**User Story:**
```
As a busy user
I want spending tracked via SMS
So I never manually log transactions
```

**Requirements:**
- One-time SMS permission at onboarding
- Background monitoring for bank/card SMS
- AI extraction: amount, merchant, date, card digits (95%+ accuracy)
- One-tap confirmation notification
- Learn bank formats and improve over time

**UI Flow:**
1. SMS arrives: "Charged $5.50 at STARBUCKS"
2. Notification: "☕ $5.50 at Starbucks - Coffee? [YES] [NO]"
3. Tap YES → saved

**Acceptance:**
- 80%+ transactions captured automatically
- 95%+ extraction accuracy
- <2 sec processing
- Works with 10+ major banks

---

## 2. Voice Transaction Entry

**Goal:** 3-second transaction logging

**User Story:**
```
As someone making quick purchases
I want to log by voice
So I track spending in 3 seconds
```

**Requirements:**
- Widget "Tap to speak"
- NLP: "five bucks coffee" → $5.00, Coffee category
- Voice response confirmation
- Context retention: "another coffee" uses last merchant
- Offline capable

**UI:**
```
🎙️ Listening...
"Five dollars coffee at Starbucks"
→ ✓ Got it! $5 Coffee at Starbucks
```

**Acceptance:**
- 90%+ voice recognition
- <3 sec total time
- Widget on lock screen

---

## 3. Financial Health Score

**Goal:** Single anxiety-reducing metric

**User Story:**
```
As an anxious user
I want one score showing if I'm okay
So I don't analyze complex data
```

**Calculation:**
```
Score (0-100) =
  Budget adherence (40%) +
  Savings rate (30%) +
  Consistency (15%) +
  Debt management (15%)
```

**Messaging:**
- 0-40: "Let's build better habits 💪"
- 41-60: "You're on track 📈"
- 61-80: "Great job ⭐"
- 81-100: "Amazing! 🔥"

**UI:**
```
Financial Health: 73/100 ⭐
↑ +5 this month

What's Helping:
✅ Under dining budget
✅ Saved $200

Opportunities:
💡 Coffee up 40% → Skip 2 runs = +3 pts
```

**Acceptance:**
- Real-time updates
- Clear component breakdown
- Actionable recommendations
- Positive tone

---

## 4. Smart Nudges

**Goal:** Prevent overspending before it happens

**User Story:**
```
As someone who overspends
I want warnings before purchases
So I make better decisions
```

**Triggers:**
- Pattern: "3rd Starbucks this week"
- Budget: "At $145/$150 dining budget"
- Time: "You usually run low day 25"
- Location: Near mall + impulse history

**Messaging (Gentle):**
- "3rd coffee this week! $15 total ☕"
- "You're close to dining budget. Still good today! 👍"
- "Skip this → save $100 this month"

**Notification:**
```
☕ Third Starbucks run this week!
$15 total on coffee
💡 Brew at home → save $50/month
[✓ Proceed] [✗ Skip It]
```

**Acceptance:**
- 20%+ reduction in overspending
- <10% find annoying
- 70%+ find helpful
- Smart frequency adjustment

---

## 5. Predictive Cash Flow

**Goal:** Prevent overdrafts

**User Story:**
```
As someone who runs out of money
I want to know when I'll hit $0
So I adjust spending early
```

**Requirements:**
- Analyze 30-day spending patterns
- Calculate daily burn rate
- Project to next payday
- 85%+ accuracy

**Warnings:**
- Red: "You'll hit $0 by March 15" (7+ days out)
- Yellow: "Running low - $120 for 5 days"
- Green: "On track to end month with $500"

**Affordability Check:**
```
Can I afford $200 shoes?

Current: $847
Bills due: $450 (Oct 25)
Daily spend: $30
Days left: 10

⚠️ Not Recommended
You'll have $197 for 10 days ($19/day vs usual $30)

Alternatives:
• Wait 10 days (after payday)
• Buy under $100
• Skip 3 lunches out
```

**Acceptance:**
- 85%+ prediction accuracy
- 80% overdraft reduction
- Real-time updates
- Actionable advice

---

## 6. Money Story

**Goal:** Daily spending awareness

**User Story:**
```
As someone losing track
I want daily spending summaries
So I see where money goes
```

**Requirements:**
- Generated at 9 PM daily
- AI narrative with emojis
- Push notification + in-app feed
- Conversational, non-judgmental

**Example:**
```
Today's Money Story 📖
Tuesday, Oct 22

You spent $67.43 today

• $5.50 - Morning coffee ☕ Starbucks
• $15.00 - Lunch 🌯 Chipotle
• $12.93 - Groceries 🛒 Whole Foods
• $4.00 - Parking 🅿️ Downtown
• $30.00 - Gas ⛽ Shell

Top category: Dining ($20.50)
This week: $312.80

💭 More than usual Tuesday. Everything okay?
```

**Acceptance:**
- 9 PM delivery
- 90%+ find valuable
- Engaging tone
- Increases awareness

---

## 7. Subscription Detection

**Goal:** Find $500/year in waste

**User Story:**
```
As someone with forgotten subscriptions
I want automatic detection
So I stop wasting $400/month
```

**Requirements:**
- Auto-detect recurring charges
- Track usage (Netflix: last opened, Gym: visit count)
- Proactive alerts before renewal
- One-tap cancellation help

**Alerts:**
- "Netflix: No activity 60 days - $12.99/mo"
- "Gym: 2 visits in 90 days - $44.99/mo"
- "Both Apple Music AND Spotify - duplicate $9.99"

**UI:**
```
💸 Subscriptions: $219/month

🔴 Wasting Money (3)
Netflix $12.99/mo ⚠️ 60 days inactive
[Cancel] [Keep]

Planet Fitness $44.99/mo ⚠️ 2 visits/90 days
[Cancel] [Keep]

💰 Potential Savings: $67.97/mo = $815/year

✅ Active & Used (4)
Spotify, YouTube Premium, iCloud...
```

**Acceptance:**
- 90%+ detection rate
- $500/year average savings
- 60%+ actually cancel
- Zero false positives

---

## 8. Receipt Scanning

**Goal:** Itemized tracking + price intel

**User Story:**
```
As a grocery shopper
I want to scan receipts
So I know if I overpaid
```

**Requirements:**
- Auto-edge detection
- Vision Agent OCR (95%+ accuracy)
- Price comparison to local markets
- Build price memory per item

**Result:**
```
📸 Whole Foods - Oct 22

🔴 Organic Milk $4.99
    Trader Joe's: $3.79 (-$1.20)

✅ Avocados $6.99
    Great deal! Usually $8.99

Total: $45.23
Potential Savings: $3.50

💡 Shop at TJ's for milk/yogurt → save $3.50/trip
```

**Acceptance:**
- 95%+ item extraction
- <5 sec processing
- Price comp for 50%+ items
- Works with wrinkled receipts

---

## 9. Couples Dashboard

**Goal:** Stop money fights

**User Story:**
```
As a couple fighting about money
We want shared visibility
So we work together
```

**Requirements:**
- Account linking via invitation
- Combined spending overview
- Individual breakdowns side-by-side
- Privacy controls (hide gifts)
- No blame language

**UI:**
```
Our Finances 💑
Mike & Jessica

Combined: $3,240 / $3,500 (93%)
Mike: $1,640 (51%)
Jessica: $1,600 (49%)

✅ Great teamwork! Both under budget

Shared Goals:
🏖️ Vacation: $2,450 / $5,000 (49%)
```

**Acceptance:**
- 60% reduction in money fights
- Both partners feel it's fair
- Privacy respected
- Strengthens partnership

---

## 10. AI Mediator

**Goal:** Facilitate money conversations

**User Story:**
```
As a couple about to fight
We want neutral mediation
So we have productive talks
```

**Requirements:**
- Both partners initiate "money talk"
- AI reviews recent spending
- Identifies conflict areas
- Provides neutral perspective

**Example:**
```
💬 Money Talk

Mike: Concerned about Jessica's shopping ($240)
Jessica: Concerned about Mike's gaming ($200)

Reality:
• Both overspent equally
• Combined, you're $200 UNDER overall budget
• Better than last month together

💡 Suggestion: Increase both by $100. You can afford it!

[Mike Agrees] [Jessica Agrees]
```

**Acceptance:**
- Both feel heard
- Reduces conflict intensity
- 80%+ find helpful
- Leads to agreements

---

## Supporting Features

### Budgeting
- Conversational setup
- AI suggests realistic amounts
- Real-time tracking
- Rollover option
- Shared budgets for couples

### Analytics
- Spending by category (pie chart)
- Trends over time
- Compare to previous month
- Anonymous user comparison
- Auto anomaly detection

### Notifications
- SMS confirmations
- Budget warnings (80%, 90%, 100%)
- Unusual spending alerts
- Bill reminders
- Customizable frequency

### Security
- Biometric auth (Face ID/Fingerprint)
- PIN backup
- Auto-lock 30 sec
- Encrypted storage
- 2FA optional

---

## Performance Targets

- App launch: <2 sec
- Transaction save: <1 sec
- Voice processing: <3 sec
- Receipt scan: <5 sec
- API response: <1 sec

## Reliability

- 99.9% uptime
- Offline transaction entry
- Background sync
- Zero data loss

---

**End of Features Specification v3**

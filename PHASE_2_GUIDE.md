# PHASE 2: POLISH & CONSOLIDATION

**Time:** 15-20 hours  
**Goal:** Production-quality codebase

---

## TASK SUMMARY

| # | Task | Time | Priority |
|---|------|------|----------|
| 1 | Pattern Learner Agent | 3h | High |
| 2 | Context Agent | 2h | High |
| 3 | Merge Shopping → Price Intelligence | 2h | High |
| 4 | Enhanced Insights Charts | 3h | Medium |
| 5 | Expanded Coaching Tips | 2h | Medium |
| 6 | Code Cleanup | 3h | Medium |

---

## IMPLEMENTATION

### 1. PATTERN LEARNER AGENT

**Replace:** `lib/services/agents/pattern_learner_agent.dart`  
**With:** `pattern_learner_agent.dart`

**Features added:**
- Predict next purchase date based on history
- Calculate average purchase intervals
- Confidence scoring
- Notify when items need replenishing

**Test:**
```dart
final agent = PatternLearnerAgent();
final prediction = await agent.predictNextPurchase(userId, 'milk');
print(prediction['daysUntil']); // 3 (buy milk in 3 days)
```

---

### 2. CONTEXT AGENT

**Replace:** `lib/services/agents/context_agent.dart`  
**With:** `context_agent.dart`

**Features added:**
- Evaluate transaction richness (rich/adequate/minimal)
- Suggest missing fields
- Generate follow-up questions
- Check if enough context for insights

**Test:**
```dart
final agent = ContextAgent();
final richness = agent.evaluateTransactionRichness(transaction);
if (richness == 'minimal') {
  final question = agent.generateFollowUpQuestion(transaction);
  // Ask user for more details
}
```

---

### 3. MERGE SHOPPING → PRICE INTELLIGENCE

**Replace:** `lib/features/price_intelligence/presentation/price_intelligence_screen.dart`  
**With:** `enhanced_price_intelligence_screen.dart`

**Features added:**
- Two tabs: "Tracked Items" + "Search Prices"
- Tracked items with price charts (existing)
- Price search functionality (from Shopping)
- Unified "Smart Shopping" experience

**Remove:**
- `lib/features/shopping/presentation/screens/shopping_screen.dart`

**Update `more_screen.dart`:**
```dart
// Change Shopping to Smart Shopping
_buildFeatureCard(
  context,
  icon: Icons.shopping_cart,
  title: 'Smart Shopping',
  subtitle: 'Track prices & find deals',
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => EnhancedPriceIntelligenceScreen()),
  ),
),
```

---

### 4. ENHANCED INSIGHTS

**Replace:** `lib/features/insights/presentation/screens/insights_screen.dart`  
**With:** `enhanced_insights_screen.dart`

**New charts added:**
- Summary card (total, count, average)
- Category pie chart
- Spending trend line chart
- Top merchants bar chart
- Daily average card
- Time period selector (week/month/year)

**Test:** Open Insights tab, switch between Week/Month/Year views.

---

### 5. EXPANDED COACHING TIPS

**Create:** `lib/services/coaching_tips_library.dart`  
**From:** `coaching_tips_library.dart`

**Tips added:**
- Groceries: 4 actionable tips
- Dining: 4 tips
- Transport: 4 tips
- Entertainment: 4 tips
- Shopping: 4 tips
- General: 5 tips
- Budget alerts
- Trend analysis

**Integrate with `proactive_coach_agent.dart`:**
```dart
import 'package:fin_co_pilot/services/coaching_tips_library.dart';

final tips = CoachingTipsLibrary.getTipsForCategory(category, data);
// Use tips in coaching generation
```

---

### 6. CODE CLEANUP

**Follow:** `PHASE_2_CLEANUP_CHECKLIST.md`

**Key removals:**
- `lib/test_firestore_screen.dart`
- `lib/features/shopping/` (entire folder)
- `main.dart` lines 111-165 (GoRouter)
- Debug print statements

**Run:**
```bash
# Remove files
rm lib/test_firestore_screen.dart
rm -rf lib/features/shopping/

# Clean & rebuild
flutter clean
flutter pub get
flutter analyze
flutter run
```

---

## TESTING CHECKLIST

### Pattern Learner
- [ ] Predictions generated for recurring items
- [ ] Confidence scores calculated
- [ ] Notifications trigger when needed

### Context Agent
- [ ] Transactions evaluated correctly
- [ ] Follow-up questions generated
- [ ] Missing fields identified

### Smart Shopping
- [ ] Both tabs work (Tracked + Search)
- [ ] Price charts display
- [ ] Search functionality integrated
- [ ] No Shopping screen in More menu

### Enhanced Insights
- [ ] All 5 charts display
- [ ] Week/Month/Year selector works
- [ ] Data calculates correctly
- [ ] Empty state shows when no data

### Coaching Tips
- [ ] Tips vary by category
- [ ] Budget alerts work
- [ ] Trend tips appear
- [ ] More variety than before

### Code Quality
- [ ] No build errors
- [ ] No unused imports
- [ ] `flutter analyze` clean
- [ ] App size reduced

---

## SUCCESS CRITERIA

✅ **Pattern Learner:** Predicts purchases, no placeholders  
✅ **Context Agent:** Evaluates richness, no placeholders  
✅ **Smart Shopping:** Single unified feature  
✅ **Insights:** 5+ distinct charts  
✅ **Coaching:** 25+ unique tips  
✅ **Clean Code:** No test files, no unused routes

**Result:** 85% → 95% complete 🎯

---

## NEXT: PHASE 3

After Phase 2 completion:
- Testing & bug fixes
- Security audit
- App Store preparation
- Production launch

**Phase 3 starts when Phase 2 tested and verified!**

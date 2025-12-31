# AUTH & ONBOARDING TESTING GUIDE

**Date:** December 31, 2025  
**Branch:** refactor-2026  
**Tasks Completed:** 4.2.1, 4.2.2

---

## 🎯 WHAT WAS FIXED

### Issue 1: Forced Re-Login Every Session
**Before:** User had to sign in with Google every time they opened the app
**Root Cause:** GoRouter used synchronous `currentUser` check (null on app restart)
**Solution:** Stream-based auth state management with `AuthStateNotifier`

### Issue 2: Onboarding Repeating for Existing Users
**Before:** Welcome screen and currency selection shown every time
**Root Cause:** `setOnboardingComplete()` only called on manual completion screen
**Solution:** Added flag setting to all sign-in methods (Google, Email, Anonymous)

---

## 🔧 TECHNICAL CHANGES

### New File: `lib/services/auth_state_notifier.dart`
```dart
// Stream-based auth state listener
class AuthStateNotifier extends ChangeNotifier {
  - Listens to Firebase authStateChanges
  - Notifies GoRouter when auth state changes
  - Reactive architecture (best practice)
}
```

### Updated: `lib/main.dart`
```dart
// Before
final _router = GoRouter(
  redirect: (context, state) {
    final isLoggedIn = authService.currentUser != null; // ❌ Synchronous
    ...
  }
);

// After
final _router = GoRouter(
  refreshListenable: _authStateNotifier, // ✅ Stream-based
  redirect: (context, state) {
    final isLoggedIn = _authStateNotifier.isLoggedIn; // ✅ Reactive
    ...
  }
);
```

### Updated: `lib/services/auth_service.dart`
```dart
// signInWithGoogle()
if (!isNewUser) {
  await PreferencesService.setOnboardingComplete(true); // ✅ Skip onboarding
}

// signInWithEmail()
await PreferencesService.setOnboardingComplete(true); // ✅ All sign-ins

// signInAnonymously()
if (!isNewUser) {
  await PreferencesService.setOnboardingComplete(true); // ✅ Existing users
}
```

---

## 📱 TESTING PROTOCOL

### Test 1: Auth Persistence (New User - Google)
1. ✅ **Sign Up:**
   - Open app → Sign In screen
   - Tap "Sign in with Google"
   - Complete Google sign-in flow
   - **Expected:** Welcome screen appears (onboarding)
   
2. ✅ **Complete Onboarding:**
   - Go through welcome slides
   - Select currency
   - Tap "Get Started"
   - **Expected:** Dashboard appears

3. ✅ **Close & Reopen:**
   - Close app completely (swipe away from recent apps)
   - Wait 10 seconds
   - Open app again
   - **Expected:** Dashboard appears immediately (no sign-in, no onboarding)
   - **Timing:** <1 second to dashboard

### Test 2: Auth Persistence (Existing User - Google)
1. ✅ **Sign In:**
   - Open app → Sign In screen
   - Tap "Sign in with Google"
   - Select existing Google account
   - **Expected:** Dashboard appears immediately (no onboarding)

2. ✅ **Close & Reopen:**
   - Close app completely
   - Wait 10 seconds
   - Open app again
   - **Expected:** Dashboard appears immediately
   - **Timing:** <1 second to dashboard

### Test 3: Email Sign-In
1. ✅ **Sign In:**
   - Open app → Sign In screen
   - Tap "Sign in with Email"
   - Enter credentials
   - **Expected:** Dashboard appears (no onboarding)
   - Note: Email users are treated as existing users

2. ✅ **Close & Reopen:**
   - Close app
   - Open app again
   - **Expected:** Dashboard appears immediately

### Test 4: Sign Out & Sign In
1. ✅ **Sign Out:**
   - Go to Settings
   - Tap "Sign Out"
   - **Expected:** Sign In screen appears

2. ✅ **Sign In Again:**
   - Tap "Sign in with Google"
   - **Expected:** Dashboard appears (no onboarding)

3. ✅ **Close & Reopen:**
   - **Expected:** Dashboard appears (still logged in)

### Test 5: Multiple Sessions
1. ✅ **Day 1:** Sign in → Use app → Close
2. ✅ **Day 2:** Open app → **Expected:** Dashboard (no sign-in)
3. ✅ **Day 3:** Open app → **Expected:** Dashboard (no sign-in)
4. ✅ **Day 7:** Open app → **Expected:** Dashboard (no sign-in)

---

## ✅ SUCCESS CRITERIA

### Auth Persistence
- [ ] New Google users: Sign in once → Stay logged in forever
- [ ] Existing Google users: Dashboard on first sign-in
- [ ] Email users: Dashboard immediately, stay logged in
- [ ] App restart: No sign-in required (<1s to dashboard)
- [ ] Multi-day sessions: Auth persists for 30+ days

### Onboarding
- [ ] New Google users: See onboarding once
- [ ] Existing Google users: Skip onboarding entirely
- [ ] After onboarding: Never see it again
- [ ] Sign out → Sign in: Skip onboarding

### Router Behavior
- [ ] No flicker/redirect loops on app start
- [ ] Smooth navigation (no visible redirects)
- [ ] Auth state changes trigger immediate UI update
- [ ] Deep links work with auth state

---

## 🐛 KNOWN ISSUES (NOT FIXED YET)

### Task 4.2.3: Google Sign-In Speed
- **Issue:** Still takes 3-5 seconds
- **Status:** Requires profiling (next task)
- **Target:** <1.5 seconds

### Task 4.2.4: Auth State Caching
- **Issue:** No local cache, waits for Firebase on start
- **Status:** Future enhancement
- **Target:** <500ms to cached dashboard

---

## 🔍 DEBUG TIPS

### If Auth Doesn't Persist:
1. Check `_authStateNotifier` initialized in main.dart
2. Verify GoRouter has `refreshListenable: _authStateNotifier`
3. Check Firebase Console → Authentication → Settings → Session duration

### If Onboarding Repeats:
1. Check SharedPreferences: `PreferencesService.isOnboardingComplete()`
2. Add debug log in signInWithGoogle(): `print('isNewUser: $isNewUser')`
3. Verify `setOnboardingComplete(true)` is called
4. Check if PreferencesService.init() is called in main()

### If Router Redirects Loop:
1. Add debug logs to redirect logic in main.dart
2. Check isLoggedIn and isOnboardingComplete values
3. Verify no circular redirects (SignIn → Onboarding → SignIn)

---

## 📊 PERFORMANCE METRICS

### Before Fixes
- Auth persistence: ❌ 0% (forced re-login every time)
- Onboarding skip: ❌ 0% (repeated every time)
- Time to dashboard: ~8-12 seconds (sign-in + onboarding)

### After Fixes (Expected)
- Auth persistence: ✅ 100% (stays logged in)
- Onboarding skip: ✅ 100% (only new users)
- Time to dashboard: <1 second (app restart)

### Still To Optimize (4.2.3)
- Initial Google Sign-In: 3-5 seconds (target: <1.5s)

---

## 🚀 NEXT STEPS

### Immediate Testing
1. Deploy to test device
2. Run all 5 test scenarios above
3. Document results in this file
4. Report any issues

### Task 4.2.3: Sign-In Speed Optimization
1. Add performance monitoring to signInWithGoogle()
2. Measure each step: Google API, Firebase auth, Firestore writes
3. Identify bottleneck
4. Optimize (batch writes, minimize queries)
5. Re-test until <1.5 seconds

### Task 4.2.4: Auth State Caching
1. Cache user profile in SharedPreferences
2. Show cached dashboard immediately
3. Sync with Firebase in background
4. Add "Syncing..." indicator

---

## 📝 TEST RESULTS

**Tester:** _Your Name_  
**Device:** _Device Model_  
**Date:** _Test Date_

### Test 1: Auth Persistence (New User - Google)
- Sign Up: ⏳ NOT TESTED / ✅ PASS / ❌ FAIL
- Complete Onboarding: ⏳ NOT TESTED / ✅ PASS / ❌ FAIL
- Close & Reopen: ⏳ NOT TESTED / ✅ PASS / ❌ FAIL
- Notes: _Any issues?_

### Test 2: Auth Persistence (Existing User - Google)
- Sign In: ⏳ NOT TESTED / ✅ PASS / ❌ FAIL
- Close & Reopen: ⏳ NOT TESTED / ✅ PASS / ❌ FAIL
- Notes: _Any issues?_

### Test 3: Email Sign-In
- Sign In: ⏳ NOT TESTED / ✅ PASS / ❌ FAIL
- Close & Reopen: ⏳ NOT TESTED / ✅ PASS / ❌ FAIL
- Notes: _Any issues?_

### Test 4: Sign Out & Sign In
- Sign Out: ⏳ NOT TESTED / ✅ PASS / ❌ FAIL
- Sign In Again: ⏳ NOT TESTED / ✅ PASS / ❌ FAIL
- Close & Reopen: ⏳ NOT TESTED / ✅ PASS / ❌ FAIL
- Notes: _Any issues?_

### Test 5: Multiple Sessions
- Day 1: ⏳ NOT TESTED / ✅ PASS / ❌ FAIL
- Day 2: ⏳ NOT TESTED / ✅ PASS / ❌ FAIL
- Day 3: ⏳ NOT TESTED / ✅ PASS / ❌ FAIL
- Notes: _Any issues?_

---

**OVERALL RESULT:** ⏳ AWAITING TESTING

---

## 💡 ARCHITECTURE NOTES (For Future Reference)

### Why Stream-Based Auth State?
- **Before:** Router called `currentUser` on every navigation (synchronous)
- **After:** Router listens to auth stream (reactive)
- **Benefit:** Automatic UI updates, no manual checks, persists correctly

### Why ChangeNotifier?
- GoRouter's `refreshListenable` requires a `Listenable`
- `ChangeNotifier` implements `Listenable`
- Notifies router when auth state changes
- Router re-runs redirect logic automatically

### Why Set Flag in Sign-In Methods?
- **Before:** Flag only set in OnboardingCompleteScreen
- **Problem:** Existing users bypass completion screen
- **After:** Flag set immediately for existing users
- **Result:** Existing users skip onboarding entirely

### Firebase Auth Persistence
- Firebase Auth persists by default on mobile (IndexedDB on web)
- Our issue was GoRouter not listening to auth stream
- `currentUser` is null until first auth state change event
- Stream-based approach solves this correctly

---

**END OF TESTING GUIDE**

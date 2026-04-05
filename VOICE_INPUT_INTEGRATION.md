# 🎤 Voice Input Button - Integration Guide

**Status:** Code ready, needs UI integration  
**Time:** 5 minutes  
**File:** `lib/features/add_transaction/presentation/add_transaction_screen.dart`

---

## 📍 Where to Add VoiceInputButton

Your app already has a `MessageInputBar` widget. Add the `VoiceInputButton` next to it.

### Step 1: Add Import

Add this at the top of `add_transaction_screen.dart`:

```dart
import '../widgets/voice_input_button.dart';
```

### Step 2: Find MessageInputBar

Look for this code in your screen (around line 340-360):

```dart
MessageInputBar(
  onSendMessage: _handleSendMessage,
  onCameraPressed: _handleCameraPressed,
)
```

### Step 3: Add Voice Button

**Option A: Inside MessageInputBar** (if it supports trailing widget)
- Check if `MessageInputBar` has a `trailing` or `actions` parameter
- If yes, pass `VoiceInputButton` there

**Option B: Wrap with Row** (simpler)

Replace the MessageInputBar with:

```dart
Row(
  children: [
    // Voice input button (left side)
    Padding(
      padding: const EdgeInsets.only(left: 8, right: 4),
      child: VoiceInputButton(
        onTranscriptReceived: (transcript) {
          // Send transcript as message
          _handleSendMessage(transcript);
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    ),
    
    // Existing message input bar (expands)
    Expanded(
      child: MessageInputBar(
        onSendMessage: _handleSendMessage,
        onCameraPressed: _handleCameraPressed,
      ),
    ),
  ],
)
```

### Step 4: Test

1. **Run app:** `flutter run`
2. **Go to Add Transaction screen**
3. **Press microphone button** (should see pulsing animation)
4. **Say:** "I spent twenty dollars on lunch"
5. **Wait 2-3 seconds** (transcription)
6. **Check:** Text should appear and transaction created

---

## 🎯 What VoiceInputButton Does

- ✅ Records audio (max 10 seconds)
- ✅ Shows countdown timer (10, 9, 8...)
- ✅ Pulsing animation while recording
- ✅ Uploads to Cloud Storage automatically
- ✅ Waits for Speech-to-Text extension (20s timeout)
- ✅ Returns transcript via callback
- ✅ Handles errors gracefully

---

## 🔧 After Speech-to-Text Extension Installs

**Test Flow:**
```
User presses mic button
    ↓
Records: "I spent fifty dollars on groceries at Walmart"
    ↓
Uploads to: voice_inputs/{userId}/audio/1704297600000.wav
    ↓
Speech-to-Text extension transcribes
    ↓
Firestore: transcriptions/{userId}/results/1704297600000
    └─ transcript: "I spent fifty dollars on groceries at Walmart"
    ↓
App receives transcript → Creates transaction
```

---

## 📱 Permissions

**Android:** Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**iOS:** Add to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to record voice transactions</string>
```

---

## ✅ Next Steps

1. ⏳ Wait for Vision AI extension to finish installing
2. ⏳ Install Speech-to-Text extension
3. ✅ Add VoiceInputButton to Add Transaction screen (5 min)
4. ✅ Add microphone permissions
5. ✅ Test voice input end-to-end
6. ✅ Mark Task 4.4.4 complete in TODO.md

**Ready to integrate once extensions are active!** 🚀

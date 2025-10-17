# Conversational Add Transaction - Architecture Diagram

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    ADD TRANSACTION SCREEN                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                     Chat Messages                         │   │
│  │  ┌────────────────────────────────────────────────┐     │   │
│  │  │ AI: "Hi! What did you buy? 💰"                 │     │   │
│  │  └────────────────────────────────────────────────┘     │   │
│  │                                    ┌─────────────────┐   │   │
│  │                                    │ User: "Coffee"  │   │   │
│  │                                    └─────────────────┘   │   │
│  │  ┌────────────────────────────────────────────────┐     │   │
│  │  │ AI: "Got your coffee! ☕                        │     │   │
│  │  │     How much did it cost?"                     │     │   │
│  │  └────────────────────────────────────────────────┘     │   │
│  │                                    ┌─────────────────┐   │   │
│  │                                    │ User: "$5"      │   │   │
│  │                                    └─────────────────┘   │   │
│  │  ┌─────────────────────────────────────────────────────┐│   │
│  │  │ ✓ Got it!                                           ││   │
│  │  │ ┌─────────────────────────────────────────────────┐ ││   │
│  │  │ │  ☕ Coffee                                       │ ││   │
│  │  │ │     Just now • Coffee                           │ ││   │
│  │  │ │                                                 │ ││   │
│  │  │ │     $5.00                                       │ ││   │
│  │  │ └─────────────────────────────────────────────────┘ ││   │
│  │  │ [Add Transaction]  [Edit]                          ││   │
│  │  └─────────────────────────────────────────────────────┘│   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  [Message Input Bar]  📷 🎤                             │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow Diagram

```
┌──────────────────┐
│  User Types      │
│  "Coffee"        │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│  ConversationProvider                                     │
│  • Adds user message to chat                             │
│  • Shows loading indicator                               │
│  • Calls AI service                                      │
└────────┬─────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│  ConversationAIService                                    │
│  • Manages conversation state                            │
│  • Processes AI responses                                │
│  • Creates appropriate ChatMessage types                 │
└────────┬─────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│  RobustAIService (NEW!)                                   │
│  • Builds system prompt with context                     │
│  • Calls Gemini 2.5 Flash API                           │
│  • Parses structured JSON response                       │
│  • Returns AIResponse with extracted data                │
└────────┬─────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│  Gemini 2.5 Flash API                                     │
│  • Receives system prompt + conversation history         │
│  • Analyzes user input                                   │
│  • Extracts transaction fields                           │
│  • Returns JSON response                                 │
└────────┬─────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│  AI Response Processing                                   │
│                                                           │
│  If hasAllRequiredFields:                                │
│    → Create TransactionPreview                           │
│    → Show beautiful preview card                         │
│                                                           │
│  Else:                                                    │
│    → Create text message with follow-up question         │
│    → Continue conversation                               │
└────────┬─────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│  UI Updates                                               │
│  • Removes loading indicator                             │
│  • Adds AI message/preview to chat                       │
│  • Updates transaction data state                        │
│  • Auto-scrolls to bottom                                │
└──────────────────────────────────────────────────────────┘
```

## 🧠 AI Processing Pipeline

```
User Input: "Coffee $5"
        │
        ▼
┌────────────────────────────────────────────────────────────┐
│  STEP 1: Build Context                                     │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ System Prompt:                                        │ │
│  │ • Required fields definition                         │ │
│  │ • Conversation rules                                 │ │
│  │ • Response format specification                      │ │
│  │                                                       │ │
│  │ Conversation History:                                │ │
│  │ • Last 5 messages for context                        │ │
│  │                                                       │ │
│  │ Current Transaction State:                           │ │
│  │ • amount: null                                       │ │
│  │ • item: null                                         │ │
│  │ • category: null                                     │ │
│  │                                                       │ │
│  │ User's Message: "Coffee $5"                          │ │
│  └──────────────────────────────────────────────────────┘ │
└────────────────────────┬───────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│  STEP 2: Gemini AI Processing                             │
│  • Analyzes: "Coffee $5"                                  │
│  • Extracts: item="Coffee", amount=5.0                    │
│  • Infers: category="Coffee"                              │
│  • Validates: All required fields present ✓               │
│  • Decision: ready_to_save = true                         │
└────────────────────────┬───────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│  STEP 3: JSON Response                                     │
│  {                                                         │
│    "message": "Perfect! Got your coffee.",                │
│    "extracted_fields": {                                  │
│      "amount": 5.0,                                       │
│      "item": "Coffee",                                    │
│      "category": "Coffee",                                │
│      "merchant": null                                     │
│    },                                                      │
│    "missing_required": [],                                │
│    "next_question": null,                                 │
│    "ready_to_save": true,                                 │
│    "confidence": 0.95                                     │
│  }                                                         │
└────────────────────────┬───────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│  STEP 4: Create ChatMessage                               │
│  • Type: TransactionPreview                               │
│  • Contains: All extracted data                           │
│  • Triggers: Beautiful preview card in UI                 │
└────────────────────────┬───────────────────────────────────┘
                         │
                         ▼
┌────────────────────────────────────────────────────────────┐
│  STEP 5: Render Preview Card                              │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ ✓ Got it!                                            │ │
│  │ ┌────────────────────────────────────────────────┐   │ │
│  │ │  ☕ Coffee                                       │   │ │
│  │ │     Just now • Coffee                           │   │ │
│  │ │                                                 │   │ │
│  │ │     $5.00                                       │   │ │
│  │ └────────────────────────────────────────────────┘   │ │
│  │ [Add Transaction]  [Edit]                            │ │
│  └──────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘
```

## 🎭 State Management Flow

```
┌─────────────────────────────────────────────────────────────┐
│  ConversationData (State)                                    │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  messages: List<ChatMessage>                          │  │
│  │    • User messages                                    │  │
│  │    • AI text messages                                 │  │
│  │    • Transaction preview messages                     │  │
│  │    • Loading indicators                               │  │
│  │                                                        │  │
│  │  conversationState: ConversationState                 │  │
│  │    • initial                                          │  │
│  │    • collecting (gathering fields)                    │  │
│  │    • confirming (preview shown)                       │  │
│  │    • completed (transaction saved)                    │  │
│  │                                                        │  │
│  │  transactionData: TransactionData                     │  │
│  │    • amount: double?                                  │  │
│  │    • item: String?                                    │  │
│  │    • category: String?                                │  │
│  │    • merchant: String?                                │  │
│  │    • hasRequiredFields: bool                          │  │
│  │    • missingRequiredFields: List<String>              │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                             │
                             │ Updates on each message
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  UI Rebuilds                                                 │
│  • Messages list updates                                     │
│  • Preview card appears/disappears                           │
│  • Input bar enabled/disabled                                │
└─────────────────────────────────────────────────────────────┘
```

## 🔀 Message Type Routing

```
                    ChatMessage
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
  MessageType.text  MessageType.    MessageType.
                    transactionPreview  loading
        │               │               │
        ▼               ▼               ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Text Bubble  │  │   Preview    │  │   Loading    │
│              │  │   Card       │  │   Spinner    │
│ "Got your    │  │ ┌──────────┐ │  │   "..."      │
│  coffee!☕"  │  │ │ ☕ Coffee │ │  │              │
│              │  │ │  $5.00   │ │  │              │
└──────────────┘  │ └──────────┘ │  └──────────────┘
                  │ [Add] [Edit] │
                  └──────────────┘
```

## 🛡️ Error Handling Strategy

```
User Input
    │
    ▼
Try: RobustAIService.processMessage()
    │
    ├─ Success → Return structured AIResponse
    │
    └─ Failure
        │
        ▼
    Fallback: Regex Extraction
        │
        ├─ Extract what we can
        │   • Amount patterns
        │   • Item patterns
        │   • Category inference
        │   • Merchant patterns
        │
        └─ Generate smart question
            • "How much did it cost?"
            • "What did you buy?"
            • "I didn't catch that..."
```

## 📊 Field Validation Logic

```
TransactionData
    │
    ├─ amount != null? ──┐
    │                    │
    ├─ item != null? ────┼─→ All present?
    │                    │       │
    └─ category != null? ┘       │
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                   YES                       NO
                    │                         │
                    ▼                         ▼
          hasRequiredFields = true   missingRequiredFields = [...]
                    │                         │
                    ▼                         ▼
          Show Preview Card         Ask Follow-up Question
```

## 🎨 UI Component Hierarchy

```
AddTransactionScreen (ConsumerStatefulWidget)
    │
    ├─ AppBar
    │   ├─ Close button
    │   ├─ Title: "Add Expense"
    │   └─ Reset button
    │
    ├─ ListView (Chat Messages)
    │   │
    │   ├─ ChatBubble (message 1)
    │   │   └─ _buildTextBubble() or _buildTransactionPreview()
    │   │
    │   ├─ ChatBubble (message 2)
    │   │
    │   └─ ChatBubble (message n)
    │
    └─ MessageInputBar
        ├─ TextField (input)
        ├─ Camera button 📷
        ├─ Voice button 🎤
        └─ Send button ➤
```

---

**Key Insight:** The RobustAIService is the **single source of truth** for AI processing. All extraction, validation, and conversation logic flows through it, ensuring consistent behavior and easy maintenance.

import '../models/transaction_data.dart';

/// Master AI prompt builder for robust conversation handling
class AIPromptBuilder {
  
  /// Build the master system prompt for the AI assistant
  static String buildMasterPrompt() {
    return '''
You are FinCoPilot, an intelligent financial assistant helping users log their expenses. Your job is to extract transaction details and ensure completeness while being conversational and helpful.

CORE MISSION: Help users create complete, accurate transaction records for better financial insights.

REQUIRED FIELDS (Must have before creating transaction):
- Amount: The price/cost in any currency format
- Item: What was purchased (product, service, meal, etc.)
- Category: Type of expense (will be auto-inferred but can be corrected)

OPTIONAL FIELDS (Encourage but don't require):
- Merchant: Store/restaurant/service provider name
- Date/Time: When the purchase happened (defaults to now)
- Location: City, area, or specific location
- Description: Additional context or details
- Payment Method: Cash, card, mobile payment, etc.

CONVERSATION PRINCIPLES:
1. EXTRACT SMARTLY: Pull out whatever information you can from user input
2. ASK SPECIFICALLY: If required fields are missing, ask targeted questions
3. ACKNOWLEDGE PROGRESS: Always confirm what you understood before asking for more
4. ENCOURAGE CONTEXT: Gently suggest optional fields that improve insights
5. BE CONVERSATIONAL: Natural, friendly tone - not robotic or formal
6. SHOW COMPLETION: Once you have required fields, immediately show transaction preview
7. HANDLE COMPLEXITY: Parse natural language, multiple currencies, various formats

RESPONSE BEHAVIOR:
- For incomplete required data: Ask specific, single question
- For complete required data: Create transaction preview immediately
- For optional data: Encourage but don't block transaction creation
- For unclear input: Ask for clarification while acknowledging what you understood

NATURAL LANGUAGE EXAMPLES:
User: "Coffee" → "Got your coffee! ☕ How much did it cost?"
User: "I spent 20 bucks" → "Nice! What did you buy for \$20? 🛍️"
User: "Lunch at McDonald's 15 dollars" → [Show transaction preview] + "Perfect! Got everything."
User: "Uber ride yesterday" → "Got the Uber ride! 🚗 How much was the fare?"

CATEGORY INFERENCE RULES:
- Coffee/Starbucks/Café → Coffee
- McDonald's/Restaurant/Lunch/Dinner → Dining  
- Costco/Groceries/Supermarket → Groceries
- Uber/Taxi/Gas/Parking → Transport
- Movie/Netflix/Entertainment → Entertainment
- Clothes/Shopping/Store → Shopping
- Doctor/Pharmacy/Health → Health
- Rent/Bills/Utilities → Bills

CURRENCY HANDLING:
- Accept any format: \$5, 5 USD, 5 dollars, €5, 5 euros, £5, 5 pounds
- Always convert to user's preferred currency (default USD)
- Handle decimal formats: 5.50, 5,50 (European), 5.5, 5

TONE & PERSONALITY:
- Friendly and encouraging
- Use relevant emojis sparingly
- Celebrate when users provide rich context
- Never sound frustrated or demanding
- Make financial tracking feel positive and rewarding
''';
  }

  /// Build contextual prompt for current conversation state
  static String buildContextualPrompt({
    required String userMessage,
    required TransactionData currentData,
    required List<String> conversationHistory,
  }) {
    final context = StringBuffer();
    
    // Add master prompt
    context.writeln(buildMasterPrompt());
    context.writeln('\n--- CURRENT CONVERSATION CONTEXT ---');
    
    // Add conversation history
    if (conversationHistory.isNotEmpty) {
      context.writeln('RECENT MESSAGES:');
      for (final message in conversationHistory.take(5)) {
        context.writeln('- $message');
      }
      context.writeln();
    }
    
    // Add current transaction state
    context.writeln('CURRENT TRANSACTION DATA:');
    context.writeln('Complete Fields: ${currentData.completeFields.join(', ')}');
    context.writeln('Missing Required: ${currentData.missingRequiredFields.join(', ')}');
    context.writeln('Completion: ${(currentData.completionPercentage * 100).toInt()}%');
    
    if (currentData.amount != null) {
      context.writeln('Amount: \$${currentData.amount}');
    }
    if (currentData.item != null) {
      context.writeln('Item: ${currentData.item}');
    }
    if (currentData.category != null) {
      context.writeln('Category: ${currentData.category}');
    }
    if (currentData.merchant != null) {
      context.writeln('Merchant: ${currentData.merchant}');
    }
    context.writeln();
    
    // Add current user message
    context.writeln('USER\'S NEW MESSAGE: "$userMessage"');
    context.writeln();
    
    // Add instructions for this specific context
    if (currentData.hasRequiredFields) {
      context.writeln('INSTRUCTION: User has provided all required fields. Show transaction preview and optionally encourage additional context.');
    } else if (currentData.missingRequiredFields.length == 1) {
      context.writeln('INSTRUCTION: Almost complete! Ask for the single missing required field: ${currentData.missingRequiredFields.first}');
    } else {
      context.writeln('INSTRUCTION: Extract what you can from the user\'s message and ask for the most important missing field.');
    }
    
    // Add response format instruction
    context.writeln();
    context.writeln('RESPONSE FORMAT: Respond naturally as FinCoPilot. Include extracted data in your response for processing.');
    
    return context.toString();
  }

  /// Build encouragement prompts for optional fields
  static String buildEncouragementPrompt({
    required TransactionData transactionData,
    required List<String> missingOptionalFields,
  }) {
    if (missingOptionalFields.isEmpty) {
      return 'Perfect! You\'ve provided comprehensive details. This will give you great spending insights! 🎯';
    }
    
    final suggestions = <String>[];
    
    if (missingOptionalFields.contains('merchant') && transactionData.item != null) {
      suggestions.add('Where did you get the ${transactionData.item?.toLowerCase()}?');
    }
    
    if (missingOptionalFields.contains('location')) {
      suggestions.add('Which area/city was this in?');
    }
    
    if (missingOptionalFields.contains('description') && transactionData.item != null) {
      suggestions.add('Any specific details about the ${transactionData.item?.toLowerCase()}?');
    }
    
    if (suggestions.isEmpty) return '';
    
    return 'Great transaction! Want to add ${suggestions.first} (Helps with better insights!)';
  }

  /// Build smart follow-up questions based on context
  static List<String> buildSmartFollowUps({
    required TransactionData transactionData,
  }) {
    final followUps = <String>[];
    
    // Smart follow-ups based on category
    switch (transactionData.category?.toLowerCase()) {
      case 'dining':
        if (transactionData.merchant == null) {
          followUps.add('Which restaurant was this at?');
        }
        if (transactionData.description == null) {
          followUps.add('What did you order?');
        }
        break;
      case 'transport':
        if (transactionData.description == null) {
          followUps.add('Where did you travel to/from?');
        }
        break;
      case 'groceries':
        if (transactionData.merchant == null) {
          followUps.add('Which store did you shop at?');
        }
        break;
      case 'coffee':
        if (transactionData.merchant == null) {
          followUps.add('Which café was this at?');
        }
        break;
    }
    
    return followUps;
  }

  /// Extract expected data format for AI response
  static String buildExpectedResponseFormat() {
    return '''
EXPECTED AI RESPONSE FORMAT:
{
  "message": "Your conversational response to the user",
  "extracted_data": {
    "amount": 15.50,
    "item": "lunch",
    "category": "dining",
    "merchant": "McDonald's",
    "confidence": 0.95
  },
  "next_action": "ask_for_missing" | "show_preview" | "encourage_optional",
  "missing_fields": ["field1", "field2"],
  "follow_up_question": "Specific question if needed"
}
''';
  }
}
import 'dart:convert';
import '../models/transaction_data.dart';

/// Smart data extraction engine for parsing user input and AI responses
class SmartDataExtractor {
  
  /// Extract transaction data from user input using advanced parsing
  static TransactionData extractFromUserInput(String userInput) {
    final input = userInput.toLowerCase().trim();
    
    return TransactionData(
      amount: _extractAmount(input),
      item: _extractItem(input),
      category: _inferCategory(input),
      merchant: _extractMerchant(input),
      date: _extractDate(input),
      description: _extractDescription(input),
      location: _extractLocation(input),
      paymentMethod: _extractPaymentMethod(input),
      currency: _extractCurrency(input),
    );
  }

  /// Extract transaction data from AI response
  static TransactionData extractFromAIResponse(Map<String, dynamic> aiResponse) {
    try {
      final extractedData = aiResponse['extracted_data'] as Map<String, dynamic>?;
      if (extractedData == null) return const TransactionData();
      
      return TransactionData(
        amount: _parseAmount(extractedData['amount']),
        item: extractedData['item']?.toString(),
        category: extractedData['category']?.toString(),
        merchant: extractedData['merchant']?.toString(),
        date: _parseDate(extractedData['date']),
        description: extractedData['description']?.toString(),
        location: extractedData['location']?.toString(),
        paymentMethod: extractedData['payment_method']?.toString(),
        currency: extractedData['currency']?.toString(),
      );
    } catch (e) {
      // Fallback to basic extraction
      return extractFromUserInput(aiResponse['message']?.toString() ?? '');
    }
  }

  /// Advanced amount extraction with multiple format support
  static double? _extractAmount(String input) {
    // Patterns for various amount formats
    final patterns = [
      // Specific currency formats
      RegExp(r'\$\s*(\d+(?:[.,]\d{1,2})?)', caseSensitive: false),           // $5.50, $ 5.50
      RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*\$', caseSensitive: false),           // 5.50$, 5.50 $
      RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:usd|dollars?)', caseSensitive: false), // 5.50 USD, 5.50 dollars
      RegExp(r'€\s*(\d+(?:[.,]\d{1,2})?)', caseSensitive: false),           // €5.50
      RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:€|euros?)', caseSensitive: false), // 5.50€, 5.50 euros
      RegExp(r'£\s*(\d+(?:[.,]\d{1,2})?)', caseSensitive: false),           // £5.50
      RegExp(r'(\d+(?:[.,]\d{1,2})?)\s*(?:£|pounds?)', caseSensitive: false), // 5.50£, 5.50 pounds
      
      // Generic patterns
      RegExp(r'(?:cost|price|paid|spend|spent)\s+\$?(\d+(?:[.,]\d{1,2})?)', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d{1,2})?)\s+(?:bucks?|dollars?)', caseSensitive: false),
      RegExp(r'for\s+\$?(\d+(?:[.,]\d{1,2})?)', caseSensitive: false),
      
      // Simple number patterns (last resort)
      RegExp(r'\b(\d+[.,]\d{1,2})\b'),  // 5.50, 5,50
      RegExp(r'\b(\d{1,4})\b(?!\s*(?:am|pm|clock|st|nd|rd|th|years?|months?|days?|hours?|minutes?))', caseSensitive: false), // Plain numbers, but not time/date
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        String amountStr = match.group(1)!;
        // Handle European comma decimal format
        amountStr = amountStr.replaceAll(',', '.');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0 && amount < 1000000) { // Reasonable range
          return amount;
        }
      }
    }
    
    return null;
  }

  /// Smart item extraction
  static String? _extractItem(String input) {
    // Remove amount and common words to isolate item
    String cleaned = input;
    
    // Remove amounts
    cleaned = cleaned.replaceAll(RegExp(r'\$?\d+(?:[.,]\d{1,2})?[^\w]*(?:usd|dollars?|euros?|pounds?|bucks?)?', caseSensitive: false), ' ');
    
    // Remove common expense words
    cleaned = cleaned.replaceAll(RegExp(r'\b(?:bought|buy|paid|spend|spent|cost|price|for|at|from|in|on|yesterday|today|tomorrow)\b', caseSensitive: false), ' ');
    
    // Extract meaningful words
    final words = cleaned.split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !_isCommonWord(word))
        .toList();
    
    if (words.isEmpty) return null;
    
    // Handle common patterns
    final itemPatterns = [
      RegExp(r'\b(coffee|latte|cappuccino|espresso|mocha)\b', caseSensitive: false),
      RegExp(r'\b(lunch|dinner|breakfast|meal|food)\b', caseSensitive: false),
      RegExp(r'\b(groceries|grocery|shopping)\b', caseSensitive: false),
      RegExp(r'\b(gas|fuel|gasoline)\b', caseSensitive: false),
      RegExp(r'\b(uber|taxi|ride|transport)\b', caseSensitive: false),
      RegExp(r'\b(movie|cinema|netflix|subscription)\b', caseSensitive: false),
    ];
    
    for (final pattern in itemPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        return _capitalizeFirst(match.group(1)!);
      }
    }
    
    // Return first meaningful word, capitalized
    return words.isNotEmpty ? _capitalizeFirst(words.first) : null;
  }

  /// Smart merchant extraction
  static String? _extractMerchant(String input) {
    // Common merchant patterns
    final merchantPatterns = [
      RegExp(r'\b(?:at|from)\s+([A-Z][a-zA-Z\s&\-]{2,20})', caseSensitive: false),
      RegExp(r'\b(Starbucks|McDonalds|KFC|Subway|Costco|Walmart|Target|Amazon|Apple|Google|Netflix|Uber|Lyft)\b', caseSensitive: false),
      RegExp(r'\b([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)?)\s+(?:store|market|restaurant|café|coffee|shop)', caseSensitive: false),
    ];
    
    for (final pattern in merchantPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        return _capitalizeWords(match.group(1)!.trim());
      }
    }
    
    return null;
  }

  /// Enhanced category inference with context
  static String? _inferCategory(String input) {
    final lower = input.toLowerCase();
    
    // Priority-based category matching
    final categoryMap = {
      'Coffee': ['coffee', 'latte', 'cappuccino', 'espresso', 'mocha', 'starbucks', 'café', 'cafe'],
      'Dining': ['lunch', 'dinner', 'breakfast', 'meal', 'restaurant', 'mcdonalds', 'kfc', 'subway', 'pizza', 'burger'],
      'Groceries': ['groceries', 'grocery', 'supermarket', 'costco', 'walmart', 'target', 'shopping', 'market'],
      'Transport': ['uber', 'lyft', 'taxi', 'ride', 'gas', 'fuel', 'parking', 'transport', 'bus', 'train'],
      'Entertainment': ['movie', 'cinema', 'netflix', 'spotify', 'game', 'entertainment', 'subscription'],
      'Health': ['doctor', 'pharmacy', 'medicine', 'hospital', 'health', 'medical', 'prescription'],
      'Bills': ['bill', 'rent', 'utility', 'electricity', 'water', 'internet', 'phone', 'insurance'],
      'Shopping': ['clothes', 'shirt', 'shoes', 'dress', 'shopping', 'amazon', 'online', 'store'],
      'Education': ['book', 'course', 'tuition', 'school', 'university', 'education', 'class'],
      'Travel': ['hotel', 'flight', 'travel', 'vacation', 'trip', 'airbnb', 'booking'],
    };
    
    // Find best matching category
    int maxMatches = 0;
    String? bestCategory;
    
    for (final entry in categoryMap.entries) {
      int matches = 0;
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          matches++;
        }
      }
      if (matches > maxMatches) {
        maxMatches = matches;
        bestCategory = entry.key;
      }
    }
    
    return bestCategory ?? 'Other';
  }

  /// Extract date information
  static DateTime? _extractDate(String input) {
    final lower = input.toLowerCase();
    final now = DateTime.now();
    
    if (lower.contains('yesterday')) {
      return now.subtract(const Duration(days: 1));
    } else if (lower.contains('today') || lower.contains('now')) {
      return now;
    } else if (lower.contains('tomorrow')) {
      return now.add(const Duration(days: 1));
    }
    
    // Pattern for specific dates (basic)
    final datePattern = RegExp(r'(\d{1,2})[\/\-](\d{1,2})(?:[\/\-](\d{2,4}))?');
    final match = datePattern.firstMatch(input);
    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = match.group(3) != null ? int.parse(match.group(3)!) : now.year;
        return DateTime(year > 99 ? year : 2000 + year, month, day);
      } catch (e) {
        // Invalid date format
      }
    }
    
    return null; // Default to now
  }

  /// Extract location information
  static String? _extractLocation(String input) {
    final locationPattern = RegExp(r'\bin\s+([A-Z][a-zA-Z\s]{2,20})(?:\s|$)', caseSensitive: false);
    final match = locationPattern.firstMatch(input);
    return match?.group(1)?.trim();
  }

  /// Extract payment method
  static String? _extractPaymentMethod(String input) {
    final lower = input.toLowerCase();
    
    if (lower.contains('cash')) return 'Cash';
    if (lower.contains('card') || lower.contains('credit') || lower.contains('debit')) return 'Card';
    if (lower.contains('paypal')) return 'PayPal';
    if (lower.contains('venmo')) return 'Venmo';
    if (lower.contains('apple pay')) return 'Apple Pay';
    if (lower.contains('google pay')) return 'Google Pay';
    
    return null;
  }

  /// Extract currency
  static String? _extractCurrency(String input) {
    if (input.contains('\$') || input.toLowerCase().contains('dollar')) return 'USD';
    if (input.contains('€') || input.toLowerCase().contains('euro')) return 'EUR';
    if (input.contains('£') || input.toLowerCase().contains('pound')) return 'GBP';
    
    return null; // Default to user preference
  }

  /// Extract description/notes
  static String? _extractDescription(String input) {
    // Look for descriptive phrases
    final descPattern = RegExp(r'(?:for|about|regarding)\s+(.+)', caseSensitive: false);
    final match = descPattern.firstMatch(input);
    return match?.group(1)?.trim();
  }

  // Helper methods
  static double? _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String _capitalizeWords(String text) {
    return text.split(' ').map((word) => _capitalizeFirst(word)).join(' ');
  }

  static bool _isCommonWord(String word) {
    const commonWords = {
      'the', 'and', 'for', 'with', 'from', 'that', 'this', 'was', 'were', 'been',
      'have', 'has', 'had', 'will', 'would', 'could', 'should', 'can', 'may',
      'i', 'me', 'my', 'you', 'your', 'he', 'she', 'it', 'we', 'they', 'them'
    };
    return commonWords.contains(word.toLowerCase());
  }
}
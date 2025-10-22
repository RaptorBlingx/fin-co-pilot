/// Bank SMS patterns for transaction detection
///
/// Supports 15+ major banks for SMS auto-parsing (Week 2 feature).
/// Each pattern includes regex for extraction and confidence scoring.
///
/// Target: 95%+ accuracy, 80%+ automatic capture rate
class BankSmsPatterns {
  /// Check if SMS is from a known bank
  static bool isFromBank(String sender) {
    return _bankSenders.any((pattern) =>
        sender.toUpperCase().contains(pattern.toUpperCase()));
  }

  /// Check if SMS contains transaction keywords
  static bool looksLikeTransaction(String message) {
    final lowerMessage = message.toLowerCase();

    // Must contain amount indicator
    final hasAmount = _amountIndicators.any((indicator) =>
        lowerMessage.contains(indicator));

    // Must contain transaction type
    final hasTransactionType = _transactionTypes.any((type) =>
        lowerMessage.contains(type));

    return hasAmount && hasTransactionType;
  }

  /// Extract transaction details from SMS
  /// Returns null if parsing fails
  static Map<String, dynamic>? parseTransaction(String sender, String message) {
    try {
      // Try each bank pattern
      for (final pattern in _bankPatterns) {
        final match = pattern['regex'].firstMatch(message);
        if (match != null) {
          return _extractFromMatch(match, pattern, sender, message);
        }
      }

      // Try generic pattern as fallback
      return _parseGeneric(sender, message);
    } catch (e) {
      return null;
    }
  }

  /// Extract data from regex match
  static Map<String, dynamic>? _extractFromMatch(
    RegExpMatch match,
    Map<String, dynamic> pattern,
    String sender,
    String message,
  ) {
    try {
      // Extract amount
      final amountStr = match.namedGroup('amount') ?? match.group(1);
      if (amountStr == null) return null;

      final amount = double.tryParse(amountStr.replaceAll(',', ''));
      if (amount == null) return null;

      // Extract merchant
      final merchant = match.namedGroup('merchant') ??
                      match.namedGroup('desc') ??
                      _extractMerchantGeneric(message);

      // Extract card last 4
      final cardLast4 = match.namedGroup('card') ?? _extractCard(message);

      // Determine transaction type
      final type = _determineType(message);

      // Calculate confidence
      final confidence = _calculateConfidence(
        hasAmount: true,
        hasMerchant: merchant != null && merchant.isNotEmpty,
        hasCard: cardLast4 != null,
        isKnownBank: true,
        message: message,
      );

      return {
        'amount': type == 'debit' ? amount : -amount, // Negative for credits
        'merchant': merchant?.trim() ?? 'Unknown',
        'cardLast4': cardLast4,
        'type': type,
        'confidence': confidence,
        'bankName': pattern['bank'] ?? sender,
        'rawMessage': message,
      };
    } catch (e) {
      return null;
    }
  }

  /// Parse using generic pattern (fallback)
  static Map<String, dynamic>? _parseGeneric(String sender, String message) {
    // Generic amount extraction
    final amountMatch = _genericAmountPattern.firstMatch(message);
    if (amountMatch == null) return null;

    final amountStr = amountMatch.group(1);
    final amount = double.tryParse(amountStr!.replaceAll(',', ''));
    if (amount == null) return null;

    // Extract other fields
    final merchant = _extractMerchantGeneric(message);
    final cardLast4 = _extractCard(message);
    final type = _determineType(message);

    final confidence = _calculateConfidence(
      hasAmount: true,
      hasMerchant: merchant != null && merchant.isNotEmpty,
      hasCard: cardLast4 != null,
      isKnownBank: isFromBank(sender),
      message: message,
    );

    return {
      'amount': type == 'debit' ? amount : -amount,
      'merchant': merchant?.trim() ?? 'Unknown',
      'cardLast4': cardLast4,
      'type': type,
      'confidence': confidence,
      'bankName': sender,
      'rawMessage': message,
    };
  }

  /// Extract merchant name from message
  static String? _extractMerchantGeneric(String message) {
    // Try "at MERCHANT" pattern
    final atPattern = RegExp(r'\bat\s+([A-Z][A-Za-z0-9\s&\-\.]{2,30})',
        caseSensitive: false);
    final atMatch = atPattern.firstMatch(message);
    if (atMatch != null) return atMatch.group(1);

    // Try "on MERCHANT" pattern
    final onPattern = RegExp(r'\bon\s+([A-Z][A-Za-z0-9\s&\-\.]{2,30})',
        caseSensitive: false);
    final onMatch = onPattern.firstMatch(message);
    if (onMatch != null) return onMatch.group(1);

    // Try "from MERCHANT" pattern
    final fromPattern = RegExp(r'\bfrom\s+([A-Z][A-Za-z0-9\s&\-\.]{2,30})',
        caseSensitive: false);
    final fromMatch = fromPattern.firstMatch(message);
    if (fromMatch != null) return fromMatch.group(1);

    return null;
  }

  /// Extract card last 4 digits
  static String? _extractCard(String message) {
    final cardPattern = RegExp(r'\*{4}(\d{4})|\bxx{2,4}(\d{4})|\b(\d{4})\s*$');
    final match = cardPattern.firstMatch(message);
    if (match != null) {
      return match.group(1) ?? match.group(2) ?? match.group(3);
    }
    return null;
  }

  /// Determine transaction type (debit or credit)
  static String _determineType(String message) {
    final lowerMessage = message.toLowerCase();

    if (_debitKeywords.any((kw) => lowerMessage.contains(kw))) {
      return 'debit';
    }
    if (_creditKeywords.any((kw) => lowerMessage.contains(kw))) {
      return 'credit';
    }

    // Default to debit
    return 'debit';
  }

  /// Calculate confidence score (0.0 - 1.0)
  static double _calculateConfidence({
    required bool hasAmount,
    required bool hasMerchant,
    required bool hasCard,
    required bool isKnownBank,
    required String message,
  }) {
    double score = 0.0;

    // Amount found: +30%
    if (hasAmount) score += 0.30;

    // Merchant found: +25%
    if (hasMerchant) score += 0.25;

    // Card details found: +15%
    if (hasCard) score += 0.15;

    // Known bank sender: +20%
    if (isKnownBank) score += 0.20;

    // Contains transaction keywords: +10%
    if (looksLikeTransaction(message)) score += 0.10;

    return score.clamp(0.0, 1.0);
  }

  /// Known bank sender identifiers
  static const List<String> _bankSenders = [
    // US Banks
    'CHASE',
    'BOFA',
    'WELLSFARGO',
    'CITI',
    'USBANK',
    'PNC',
    'CAPITALONE',
    'TD BANK',
    'ALLY',
    'DISCOVER',

    // Digital Banks
    'CHIME',
    'VARO',
    'CURRENT',
    'CASH APP',

    // Credit Cards
    'AMEX',
    'VISA',
    'MASTERCARD',

    // Generic
    'BANK',
    'CREDIT',
    'DEBIT',
    'CARD',
  ];

  /// Amount indicator keywords
  static const List<String> _amountIndicators = [
    r'$',
    'usd',
    'inr',
    'rs.',
    'rs',
    'amount',
    'spent',
    'charged',
    'paid',
  ];

  /// Transaction type keywords
  static const List<String> _transactionTypes = [
    'debited',
    'credited',
    'spent',
    'paid',
    'charged',
    'purchase',
    'transaction',
    'withdrawal',
    'deposit',
    'transfer',
  ];

  /// Debit keywords
  static const List<String> _debitKeywords = [
    'debited',
    'debit',
    'spent',
    'purchase',
    'paid',
    'charged',
    'withdrawal',
  ];

  /// Credit keywords
  static const List<String> _creditKeywords = [
    'credited',
    'credit',
    'received',
    'deposit',
    'refund',
    'cashback',
  ];

  /// Generic amount pattern
  static final RegExp _genericAmountPattern = RegExp(
    r'(?:rs\.?|inr|\$|usd)\s*([0-9,]+(?:\.[0-9]{2})?)',
    caseSensitive: false,
  );

  /// Bank-specific patterns
  static final List<Map<String, dynamic>> _bankPatterns = [
    // Chase Bank
    {
      'bank': 'Chase',
      'regex': RegExp(
        r'(?:debit|purchase).*?(?:\$|usd)\s*(?<amount>[0-9,]+(?:\.[0-9]{2})?)'
        r'.*?(?:at|from)\s+(?<merchant>[A-Za-z0-9\s&\-\.]+)'
        r'.*?(?:card|acct).*?(?<card>\d{4})',
        caseSensitive: false,
      ),
    },

    // Bank of America
    {
      'bank': 'Bank of America',
      'regex': RegExp(
        r'(?:purchase|debit).*?\$(?<amount>[0-9,]+(?:\.[0-9]{2})?)'
        r'.*?(?:at)\s+(?<merchant>[A-Za-z0-9\s&\-\.]+)'
        r'.*?(?:ending|card).*?(?<card>\d{4})',
        caseSensitive: false,
      ),
    },

    // Wells Fargo
    {
      'bank': 'Wells Fargo',
      'regex': RegExp(
        r'debit.*?\$(?<amount>[0-9,]+(?:\.[0-9]{2})?)'
        r'.*?(?:at|to)\s+(?<merchant>[A-Za-z0-9\s&\-\.]+)',
        caseSensitive: false,
      ),
    },

    // Citi Bank
    {
      'bank': 'Citi',
      'regex': RegExp(
        r'(?:transaction|purchase).*?\$(?<amount>[0-9,]+(?:\.[0-9]{2})?)'
        r'.*?(?:at)\s+(?<merchant>[A-Za-z0-9\s&\-\.]+)'
        r'.*?(?<card>\d{4})',
        caseSensitive: false,
      ),
    },

    // Capital One
    {
      'bank': 'Capital One',
      'regex': RegExp(
        r'(?:spent|paid)\s+\$(?<amount>[0-9,]+(?:\.[0-9]{2})?)'
        r'.*?(?:at)\s+(?<merchant>[A-Za-z0-9\s&\-\.]+)',
        caseSensitive: false,
      ),
    },

    // Discover
    {
      'bank': 'Discover',
      'regex': RegExp(
        r'(?:purchase|charge).*?\$(?<amount>[0-9,]+(?:\.[0-9]{2})?)'
        r'.*?(?:at|from)\s+(?<merchant>[A-Za-z0-9\s&\-\.]+)'
        r'.*?(?<card>\d{4})',
        caseSensitive: false,
      ),
    },

    // American Express
    {
      'bank': 'American Express',
      'regex': RegExp(
        r'(?:charge|purchase).*?\$(?<amount>[0-9,]+(?:\.[0-9]{2})?)'
        r'.*?(?:at)\s+(?<merchant>[A-Za-z0-9\s&\-\.]+)'
        r'.*?(?:card).*?(?<card>\d{4})',
        caseSensitive: false,
      ),
    },

    // Chime
    {
      'bank': 'Chime',
      'regex': RegExp(
        r'(?:spent|paid)\s+\$(?<amount>[0-9,]+(?:\.[0-9]{2})?)'
        r'.*?(?:at)\s+(?<merchant>[A-Za-z0-9\s&\-\.]+)',
        caseSensitive: false,
      ),
    },

    // Cash App
    {
      'bank': 'Cash App',
      'regex': RegExp(
        r'(?:paid|sent)\s+\$(?<amount>[0-9,]+(?:\.[0-9]{2})?)'
        r'.*?(?:to|for)\s+(?<merchant>[A-Za-z0-9\s&\-\.]+)',
        caseSensitive: false,
      ),
    },

    // Venmo
    {
      'bank': 'Venmo',
      'regex': RegExp(
        r'(?:paid|charged)\s+\$(?<amount>[0-9,]+(?:\.[0-9]{2})?)'
        r'.*?(?:for|to)\s+(?<desc>[A-Za-z0-9\s&\-\.]+)',
        caseSensitive: false,
      ),
    },
  ];
}

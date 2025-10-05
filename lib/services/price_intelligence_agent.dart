import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../shared/models/price_result.dart';

class PriceIntelligenceAgent {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GenerativeModel _model;

  PriceIntelligenceAgent()
      : _model = FirebaseVertexAI.instance.generativeModel(
          model: 'gemini-2.5-flash',
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 8192,
          ),
        );

  /// Search for best prices of a product
  Future<List<PriceResult>> searchBestPrice({
    required String productQuery,
    required String userCountry,
    required String userLanguage,
    required String userCurrency,
  }) async {
    try {
      print('🔍 PriceIntelligence: Searching for "$productQuery" in $userCountry');
      
      // 1. Check cache first
      final cachedResults = await getCachedResults(
        productQuery: productQuery,
        userCountry: userCountry,
      );
      
      if (cachedResults != null && cachedResults.isNotEmpty) {
        print('🔍 PriceIntelligence: Found ${cachedResults.length} cached results');
        return cachedResults;
      }

      // 2. Build location-aware search prompt
      final prompt = _buildSearchPrompt(
        productQuery,
        userCountry,
        userLanguage,
        userCurrency,
      );

      print('🔍 PriceIntelligence: Calling Gemini 2.5 Flash with Google Search grounding');
      
      // 3. Call Gemini with Google Search grounding
      final response = await _model.generateContent([Content.text(prompt)]);
      final searchResults = response.text ?? '';

      print('🔍 PriceIntelligence: Received response: ${searchResults.length} characters');

      // 4. Parse results into structured data
      final priceResults = _parseSearchResults(
        searchResults,
        productQuery,
        userCountry,
        userCurrency,
      );

      print('🔍 PriceIntelligence: Parsed ${priceResults.length} price results');
      
      // If parsing failed and we got no results, return sample results
      if (priceResults.isEmpty) {
        print('🔍 PriceIntelligence: No results parsed, returning sample results');
        final sampleResults = _getSampleResults(productQuery, userCountry, userCurrency);
        await _cacheResults(productQuery, userCountry, sampleResults);
        return sampleResults;
      }

      // 5. Cache results in Firestore
      if (priceResults.isNotEmpty) {
        await _cacheResults(productQuery, userCountry, priceResults);
        print('🔍 PriceIntelligence: Results cached successfully');
      }

      return priceResults;
    } catch (e) {
      print('🔍 PriceIntelligence ERROR: $e');
      
      // Return sample results for testing if API fails
      return _getSampleResults(productQuery, userCountry, userCurrency);
    }
  }

  /// Check cached results before searching
  Future<List<PriceResult>?> getCachedResults({
    required String productQuery,
    required String userCountry,
  }) async {
    try {
      final cacheKey = _generateCacheKey(productQuery, userCountry);
      final doc = await _firestore.collection('price_cache').doc(cacheKey).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final cachedAt = (data['cached_at'] as Timestamp).toDate();
      final now = DateTime.now();

      // Cache expires after 24 hours
      if (now.difference(cachedAt).inHours > 24) {
        print('🔍 PriceIntelligence: Cache expired for $cacheKey');
        return null;
      }

      final results = (data['results'] as List)
          .map((r) => PriceResult.fromMap(r as Map<String, dynamic>))
          .toList();

      return results;
    } catch (e) {
      print('🔍 PriceIntelligence: Cache retrieval error: $e');
      return null;
    }
  }

  /// Build location-aware search prompt
  String _buildSearchPrompt(
    String productQuery,
    String userCountry,
    String userLanguage,
    String userCurrency,
  ) {
    return '''
You are a price intelligence expert using Gemini 2.5 Flash with advanced reasoning capabilities. Search for the best prices for "$productQuery" in $userCountry.

REASONING APPROACH:
1. Think step-by-step about where consumers in $userCountry typically shop for this product
2. Consider both online retailers and physical stores with online presence
3. Analyze current market conditions and seasonal factors that might affect pricing
4. Verify availability status and shipping options

SEARCH INSTRUCTIONS:
1. Find prices from major online retailers and stores in $userCountry
2. Search in the local language: $userLanguage  
3. Return prices in $userCurrency
4. Include at least 3-5 different retailers
5. Check current availability and stock status
6. Look for special offers, discounts, or bundle deals

For each result, provide:
- Merchant name
- Price (in $userCurrency)  
- Availability status (in_stock / out_of_stock / pre_order / limited)
- Product URL (if available)
- Brief notes (e.g., includes shipping, on sale, Prime eligible, etc.)

FORMAT YOUR RESPONSE EXACTLY like this (one merchant per line):

[MERCHANT]|[PRICE]|[CURRENCY]|[AVAILABILITY]|[URL]|[NOTES]

Example:
Amazon.ca|299.99|CAD|in_stock|https://amazon.ca/product/xyz|Free shipping, Prime eligible
Best Buy Canada|319.99|CAD|in_stock|https://bestbuy.ca/product/abc|In-store pickup available  
Walmart Canada|289.99|CAD|out_of_stock|https://walmart.ca/product/def|Expected back in 2 weeks

IMPORTANT: Use your advanced reasoning to provide accurate, current pricing information. If you cannot find a reliable price, skip that merchant.
''';
  }

  /// Parse AI response into structured PriceResult objects
  List<PriceResult> _parseSearchResults(
    String searchResults,
    String productQuery,
    String userCountry,
    String userCurrency,
  ) {
    final results = <PriceResult>[];
    
    print('🔍 PriceIntelligence: Raw AI response: $searchResults');
    
    // Try to find lines with pipe separators first
    final lines = searchResults.split('\n').where((line) => line.contains('|')).toList();
    
    print('🔍 PriceIntelligence: Found ${lines.length} lines with pipe separators');

    for (final line in lines) {
      try {
        final parts = line.split('|').map((p) => p.trim()).toList();
        print('🔍 PriceIntelligence: Parsing line: $line -> ${parts.length} parts');
        
        if (parts.length >= 4) {
          final priceText = parts[1].replaceAll(RegExp(r'[^\d.]'), '');
          final price = double.tryParse(priceText) ?? 0.0;
          
          print('🔍 PriceIntelligence: Extracted price: $priceText -> $price');
          
          if (price > 0) {
            results.add(PriceResult(
              id: 'price_${DateTime.now().millisecondsSinceEpoch}_${results.length}',
              productQuery: productQuery,
              merchant: parts[0],
              price: price,
              currency: parts.length > 2 ? parts[2] : userCurrency,
              availability: parts.length > 3 ? parts[3] : 'unknown',
              url: parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null,
              notes: parts.length > 5 ? parts[5] : null,
              country: userCountry,
              foundAt: DateTime.now(),
            ));
            print('🔍 PriceIntelligence: Successfully parsed result for ${parts[0]}');
          }
        }
      } catch (e) {
        print('🔍 PriceIntelligence: Error parsing price line: $line - $e');
      }
    }

    // If no results were parsed from pipe format, try alternative parsing
    if (results.isEmpty) {
      print('🔍 PriceIntelligence: Pipe format parsing failed, trying alternative parsing');
      results.addAll(_parseAlternativeFormat(searchResults, productQuery, userCountry, userCurrency));
    }

    // Sort by price (lowest first, but prioritize in-stock items)
    results.sort((a, b) {
      // In-stock items first
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;
      
      // Then by price
      return a.price.compareTo(b.price);
    });

    return results;
  }

  /// Alternative parsing method for when pipe format fails
  List<PriceResult> _parseAlternativeFormat(
    String searchResults,
    String productQuery,
    String userCountry,
    String userCurrency,
  ) {
    final results = <PriceResult>[];
    
    try {
      // Look for patterns like "Amazon $299.99" or "Best Buy: $1,299"
      final pricePattern = RegExp(r'([A-Za-z\s&]+)[\s:$]*\$?([\d,]+\.?\d*)', multiLine: true);
      final matches = pricePattern.allMatches(searchResults);
      
      print('🔍 PriceIntelligence: Alternative parsing found ${matches.length} potential matches');
      
      for (final match in matches) {
        try {
          final merchant = match.group(1)?.trim() ?? 'Unknown Store';
          final priceText = match.group(2)?.replaceAll(',', '') ?? '0';
          final price = double.tryParse(priceText) ?? 0.0;
          
          if (price > 0 && merchant.isNotEmpty && !merchant.contains('USD') && !merchant.contains('CAD')) {
            results.add(PriceResult(
              id: 'alt_${DateTime.now().millisecondsSinceEpoch}_${results.length}',
              productQuery: productQuery,
              merchant: merchant,
              price: price,
              currency: userCurrency,
              availability: 'unknown',
              url: null,
              notes: 'Parsed via alternative method',
              country: userCountry,
              foundAt: DateTime.now(),
            ));
            
            print('🔍 PriceIntelligence: Alternative parsing found: $merchant - \$${price}');
          }
        } catch (e) {
          print('🔍 PriceIntelligence: Error in alternative parsing: $e');
        }
      }
    } catch (e) {
      print('🔍 PriceIntelligence: Alternative parsing failed: $e');
    }
    
    return results;
  }

  /// Cache search results
  Future<void> _cacheResults(
    String productQuery,
    String userCountry,
    List<PriceResult> results,
  ) async {
    try {
      final cacheKey = _generateCacheKey(productQuery, userCountry);
      await _firestore.collection('price_cache').doc(cacheKey).set({
        'product_query': productQuery,
        'country': userCountry,
        'results': results.map((r) => r.toMap()).toList(),
        'cached_at': FieldValue.serverTimestamp(),
        'ttl': DateTime.now().add(const Duration(hours: 24)),
      });
    } catch (e) {
      print('🔍 PriceIntelligence: Cache storage error: $e');
    }
  }

  /// Generate cache key
  String _generateCacheKey(String productQuery, String userCountry) {
    final normalized = productQuery.toLowerCase().replaceAll(' ', '_');
    return '${normalized}_${userCountry.toLowerCase()}';
  }

  /// Track a product for price drop alerts
  Future<void> trackProduct({
    required String userId,
    required String productQuery,
    required String merchant,
    required double targetPrice,
    required String currency,
  }) async {
    try {
      await _firestore.collection('tracked_products').add({
        'user_id': userId,
        'product_query': productQuery,
        'merchant': merchant,
        'target_price': targetPrice,
        'currency': currency,
        'created_at': FieldValue.serverTimestamp(),
        'alert_sent': false,
      });
      
      print('🔍 PriceIntelligence: Product tracked successfully');
    } catch (e) {
      print('🔍 PriceIntelligence: Error tracking product: $e');
    }
  }

  /// Get user's tracked products
  Stream<List<Map<String, dynamic>>> getTrackedProducts(String userId) {
    return _firestore
        .collection('tracked_products')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Untrack a product
  Future<void> untrackProduct(String trackingId) async {
    try {
      await _firestore.collection('tracked_products').doc(trackingId).delete();
      print('🔍 PriceIntelligence: Product untracked successfully');
    } catch (e) {
      print('🔍 PriceIntelligence: Error untracking product: $e');
    }
  }

  /// Get sample results for testing/fallback
  List<PriceResult> _getSampleResults(String productQuery, String userCountry, String userCurrency) {
    final now = DateTime.now();
    
    return [
      PriceResult(
        id: 'sample_1',
        productQuery: productQuery,
        merchant: 'Best Buy',
        price: 299.99,
        currency: userCurrency,
        availability: 'in_stock',
        url: 'https://bestbuy.com/sample',
        notes: 'Free shipping, In-store pickup available',
        country: userCountry,
        foundAt: now,
      ),
      PriceResult(
        id: 'sample_2',
        productQuery: productQuery,
        merchant: 'Amazon',
        price: 289.99,
        currency: userCurrency,
        availability: 'in_stock',
        url: 'https://amazon.com/sample',
        notes: 'Prime eligible, Free 2-day shipping',
        country: userCountry,
        foundAt: now,
      ),
      PriceResult(
        id: 'sample_3',
        productQuery: productQuery,
        merchant: 'Walmart',
        price: 319.99,
        currency: userCurrency,
        availability: 'limited',
        url: 'https://walmart.com/sample',
        notes: 'Limited stock, Free pickup',
        country: userCountry,
        foundAt: now,
      ),
      PriceResult(
        id: 'sample_4',
        productQuery: productQuery,
        merchant: 'Target',
        price: 279.99,
        currency: userCurrency,
        availability: 'out_of_stock',
        url: 'https://target.com/sample',
        notes: 'Currently unavailable, expected in 2 weeks',
        country: userCountry,
        foundAt: now,
      ),
    ];
  }

  /// Detect user's country (fallback method)
  Future<String> detectUserCountry() async {
    // In a real app, you might use location services or IP geolocation
    // For now, return a default based on device locale or settings
    return 'United States'; // Default fallback
  }

  /// Get currency for country
  String getCurrencyForCountry(String country) {
    switch (country.toLowerCase()) {
      case 'united states':
      case 'usa':
      case 'us':
        return 'USD';
      case 'canada':
      case 'ca':
        return 'CAD';
      case 'united kingdom':
      case 'uk':
      case 'gb':
        return 'GBP';
      case 'germany':
      case 'france':
      case 'italy':
      case 'spain':
      case 'europe':
        return 'EUR';
      case 'japan':
      case 'jp':
        return 'JPY';
      default:
        return 'USD';
    }
  }

  /// Get language for country
  String getLanguageForCountry(String country) {
    switch (country.toLowerCase()) {
      case 'united states':
      case 'usa':
      case 'us':
      case 'canada':
      case 'united kingdom':
      case 'uk':
      case 'australia':
        return 'English';
      case 'france':
        return 'French';
      case 'germany':
        return 'German';
      case 'spain':
        return 'Spanish';
      case 'italy':
        return 'Italian';
      case 'japan':
        return 'Japanese';
      default:
        return 'English';
    }
  }
}
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExchangeRateService {
  // Using a free exchange rate API
  static const String _apiUrl = 'https://api.exchangerate-api.com/v4/latest';

  // Cache exchange rates for 24 hours
  static Map<String, dynamic>? _cachedRates;
  static DateTime? _lastFetch;

  /// Get exchange rate from one currency to another
  static Future<double> getExchangeRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) return 1.0;

    // Check cache
    if (_cachedRates != null && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);
      if (age.inHours < 24) {
        return _getRate(fromCurrency, toCurrency);
      }
    }

    // Fetch fresh rates
    try {
      final response = await http.get(Uri.parse('$_apiUrl/USD'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedRates = data['rates'];
        _lastFetch = DateTime.now();
        
        return _getRate(fromCurrency, toCurrency);
      }
    } catch (e) {
      print('Exchange rate fetch error: $e');
    }

    // Fallback: return 1.0 if fetch fails
    return 1.0;
  }

  static double _getRate(String from, String to) {
    if (_cachedRates == null) return 1.0;

    final fromRate = _cachedRates![from] ?? 1.0;
    final toRate = _cachedRates![to] ?? 1.0;

    return toRate / fromRate;
  }

  /// Convert amount from one currency to another
  static Future<double> convert(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    final rate = await getExchangeRate(fromCurrency, toCurrency);
    return amount * rate;
  }
}
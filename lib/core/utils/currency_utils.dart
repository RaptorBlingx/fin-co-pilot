import 'dart:io';

class CurrencyUtils {
  // Auto-detect currency from device locale
  static String detectCurrency() {
    final locale = Platform.localeName; // e.g., "en_US", "tr_TR", "de_DE"
    
    // Extract country code
    final parts = locale.split('_');
    if (parts.length < 2) return 'USD'; // Default
    
    final countryCode = parts[1];
    
    // Map common country codes to currencies
    final currencyMap = {
      'US': 'USD',
      'CA': 'CAD',
      'GB': 'GBP',
      'EU': 'EUR',
      'DE': 'EUR',
      'FR': 'EUR',
      'ES': 'EUR',
      'IT': 'EUR',
      'TR': 'TRY',
      'IN': 'INR',
      'JP': 'JPY',
      'CN': 'CNY',
      'AU': 'AUD',
      'BR': 'BRL',
      'MX': 'MXN',
      'RU': 'RUB',
      'ZA': 'ZAR',
      'KR': 'KRW',
      'SA': 'SAR',
      'AE': 'AED',
      'CH': 'CHF',
      'SE': 'SEK',
      'NO': 'NOK',
      'DK': 'DKK',
      'PL': 'PLN',
      'NZ': 'NZD',
      'SG': 'SGD',
      'HK': 'HKD',
      'TH': 'THB',
      'MY': 'MYR',
      'ID': 'IDR',
      'PH': 'PHP',
      'VN': 'VND',
      'EG': 'EGP',
      'NG': 'NGN',
      'KE': 'KES',
      'AR': 'ARS',
      'CL': 'CLP',
      'CO': 'COP',
      'PE': 'PEN',
      'IL': 'ILS',
      'CZ': 'CZK',
      'HU': 'HUF',
      'RO': 'RON',
      'BG': 'BGN',
      'HR': 'HRK',
      'UA': 'UAH',
      'PK': 'PKR',
      'BD': 'BDT',
      'LK': 'LKR',
      'NP': 'NPR',
    };
    
    return currencyMap[countryCode] ?? 'USD';
  }
  
  // Get currency symbol
  static String getCurrencySymbol(String currencyCode) {
    final symbolMap = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CNY': '¥',
      'INR': '₹',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'TRY': '₺',
      'BRL': 'R\$',
      'MXN': 'Mex\$',
      'RUB': '₽',
      'ZAR': 'R',
      'KRW': '₩',
      'CHF': 'CHF',
      'SEK': 'kr',
      'NOK': 'kr',
      'DKK': 'kr',
      'PLN': 'zł',
      'NZD': 'NZ\$',
      'SGD': 'S\$',
      'HKD': 'HK\$',
      'THB': '฿',
      'MYR': 'RM',
      'IDR': 'Rp',
      'PHP': '₱',
      'VND': '₫',
      'SAR': 'SR',
      'AED': 'AED',
      'EGP': 'E£',
      'NGN': '₦',
      'KES': 'KSh',
      'ARS': 'AR\$',
      'CLP': 'CL\$',
      'COP': 'COL\$',
      'PEN': 'S/',
      'ILS': '₪',
      'CZK': 'Kč',
      'HUF': 'Ft',
      'RON': 'lei',
      'BGN': 'лв',
      'HRK': 'kn',
      'UAH': '₴',
      'PKR': '₨',
      'BDT': '৳',
      'LKR': 'Rs',
      'NPR': 'Rs',
    };
    
    return symbolMap[currencyCode] ?? currencyCode;
  }
  
  // Format amount with currency
  static String formatAmount(double amount, String currencyCode) {
    final symbol = getCurrencySymbol(currencyCode);
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
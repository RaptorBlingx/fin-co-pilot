import 'package:fin_copilot/services/ai/transaction_parser_service.dart';

/// Test script for TransactionParserService
/// Run with: flutter run -t scripts/test_transaction_parser.dart
void main() async {
  print('🧪 Testing TransactionParserService...\n');
  
  final parser = TransactionParserService();
  
  // Test cases
  final testInputs = [
    "Spent \$50 on groceries",
    "Coffee from Starbucks 4.50",
    "Got paid \$2000",
    "Uber ride yesterday \$15",
    "Lunch at McDonald's 12.50",
    "Paid electricity bill 85 dollars",
  ];
  
  for (final input in testInputs) {
    print('📝 Input: "$input"');
    
    try {
      final result = await parser.parseNaturalLanguage(input);
      
      if (result.success) {
        print('✅ Success!');
        print('   Amount: \$${result.amount}');
        print('   Category: ${result.category}');
        print('   Merchant: ${result.merchant ?? "N/A"}');
        print('   Description: ${result.description ?? "N/A"}');
        print('   Confidence: ${(result.confidence * 100).toStringAsFixed(0)}%');
        print('   Has required fields: ${result.hasRequiredFields}');
      } else {
        print('❌ Failed: ${result.error}');
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
    
    print('');
  }
  
  print('✅ Testing complete!');
}

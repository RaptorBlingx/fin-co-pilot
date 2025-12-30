import 'package:fin_copilot/services/ai/transaction_parser_service.dart';

/// Comprehensive end-to-end testing for TransactionParserService
/// Tests 20+ different input phrases for accuracy
/// 
/// Run with: dart scripts/test_conversational_e2e.dart
void main() async {
  print('🧪 CONVERSATIONAL TRANSACTION INPUT - END-TO-END TEST');
  print('=' * 60);
  print('Testing TransactionParserService with 20+ input phrases\n');

  final parser = TransactionParserService();
  
  final testCases = [
    // Basic amount + category
    TestCase('Spent \$50 on groceries', expectedAmount: 50, expectedCategory: 'Groceries'),
    TestCase('Coffee 4.50', expectedAmount: 4.50, expectedCategory: 'Food & Dining'),
    TestCase('Got paid \$2000', expectedAmount: 2000, expectedCategory: 'Income'),
    
    // With merchant
    TestCase('Coffee from Starbucks 4.50', expectedAmount: 4.50, expectedCategory: 'Food & Dining', expectedMerchant: 'Starbucks'),
    TestCase('Lunch at McDonald\'s 12.50', expectedAmount: 12.50, expectedCategory: 'Food & Dining', expectedMerchant: 'McDonald\'s'),
    TestCase('Uber ride 15 dollars', expectedAmount: 15, expectedCategory: 'Transport', expectedMerchant: 'Uber'),
    
    // Different phrasings
    TestCase('Paid electricity bill 85 bucks', expectedAmount: 85, expectedCategory: 'Bills'),
    TestCase('Bought new shoes for \$79.99', expectedAmount: 79.99, expectedCategory: 'Shopping'),
    TestCase('Dinner with friends \$45', expectedAmount: 45, expectedCategory: 'Food & Dining'),
    
    // Time references
    TestCase('Groceries yesterday \$67.50', expectedAmount: 67.50, expectedCategory: 'Groceries'),
    TestCase('Coffee this morning 5.25', expectedAmount: 5.25, expectedCategory: 'Food & Dining'),
    
    // Edge cases
    TestCase('Gas station 40', expectedAmount: 40, expectedCategory: 'Transport'),
    TestCase('Movie tickets 25', expectedAmount: 25, expectedCategory: 'Entertainment'),
    TestCase('Pharmacy 18.50', expectedAmount: 18.50, expectedCategory: 'Healthcare'),
    TestCase('Amazon purchase \$125', expectedAmount: 125, expectedCategory: 'Shopping'),
    
    // Complex descriptions
    TestCase('Whole Foods groceries for weekly shopping \$156.78', expectedAmount: 156.78, expectedCategory: 'Groceries'),
    TestCase('Netflix subscription monthly 15.99', expectedAmount: 15.99, expectedCategory: 'Entertainment'),
    TestCase('Gym membership payment \$50', expectedAmount: 50, expectedCategory: 'Healthcare'),
    
    // Income & transfers
    TestCase('Salary deposit 3500', expectedAmount: 3500, expectedCategory: 'Income'),
    TestCase('Transfer to savings 200', expectedAmount: 200, expectedCategory: 'Transfer'),
    
    // Very short inputs (ambiguous)
    TestCase('Coffee', expectedAmount: null, expectedCategory: 'Food & Dining'),
    TestCase('Lunch', expectedAmount: null, expectedCategory: 'Food & Dining'),
    
    // Numbers in different formats
    TestCase('Groceries \$123.45', expectedAmount: 123.45, expectedCategory: 'Groceries'),
    TestCase('Bus fare 2.50', expectedAmount: 2.50, expectedCategory: 'Transport'),
  ];

  int passed = 0;
  int failed = 0;
  final List<String> failedTests = [];

  for (int i = 0; i < testCases.length; i++) {
    final test = testCases[i];
    print('Test ${i + 1}/${testCases.length}: "${test.input}"');
    
    try {
      final result = await parser.parseNaturalLanguage(test.input);
      
      if (result.success) {
        final amountMatch = test.expectedAmount == null || 
                           (result.amount != null && (result.amount! - test.expectedAmount).abs() < 0.01);
        final categoryMatch = test.expectedCategory == null || result.category == test.expectedCategory;
        final merchantMatch = test.expectedMerchant == null || 
                             (result.merchant?.toLowerCase().contains(test.expectedMerchant.toLowerCase()) ?? false);
        
        if (amountMatch && categoryMatch && merchantMatch) {
          print('  ✅ PASS');
          print('     Amount: \$${result.amount ?? "N/A"}');
          print('     Category: ${result.category}');
          if (result.merchant != null) print('     Merchant: ${result.merchant}');
          print('     Confidence: ${(result.confidence * 100).toStringAsFixed(0)}%');
          passed++;
        } else {
          print('  ❌ FAIL - Incorrect parsing');
          print('     Expected: \$${test.expectedAmount}, ${test.expectedCategory}, ${test.expectedMerchant ?? "N/A"}');
          print('     Got: \$${result.amount}, ${result.category}, ${result.merchant ?? "N/A"}');
          failed++;
          failedTests.add(test.input);
        }
      } else {
        print('  ❌ FAIL - Parser error: ${result.error}');
        failed++;
        failedTests.add(test.input);
      }
    } catch (e) {
      print('  ❌ FAIL - Exception: $e');
      failed++;
      failedTests.add(test.input);
    }
    
    print('');
  }

  // Summary
  print('=' * 60);
  print('📊 TEST SUMMARY');
  print('=' * 60);
  print('Total Tests: ${testCases.length}');
  print('✅ Passed: $passed (${((passed / testCases.length) * 100).toStringAsFixed(1)}%)');
  print('❌ Failed: $failed (${((failed / testCases.length) * 100).toStringAsFixed(1)}%)');
  
  if (failedTests.isNotEmpty) {
    print('\n❌ Failed test cases:');
    for (final test in failedTests) {
      print('   - "$test"');
    }
  }
  
  print('\n' + '=' * 60);
  
  if (passed >= testCases.length * 0.8) {
    print('✅ TEST SUITE PASSED (>80% success rate)');
  } else {
    print('❌ TEST SUITE NEEDS IMPROVEMENT (<80% success rate)');
  }
  
  print('=' * 60);
}

class TestCase {
  final String input;
  final double? expectedAmount;
  final String? expectedCategory;
  final String? expectedMerchant;

  TestCase(
    this.input, {
    this.expectedAmount,
    this.expectedCategory,
    this.expectedMerchant,
  });
}

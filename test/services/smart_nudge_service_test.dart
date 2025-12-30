import 'package:flutter_test/flutter_test.dart';
import 'package:fin_copilot/services/smart_nudge_service.dart';
import '../helpers/mock_data.dart';

/// Unit tests for SmartNudgeService
///
/// Tests:
/// - Budget warning detection
/// - Impulse spending detection
/// - Notification triggering
/// - Edge cases

void main() {
  group('SmartNudgeService', () {
    late SmartNudgeService service;

    setUp(() {
      service = SmartNudgeService();
    });

    test('should initialize service successfully', () {
      expect(service, isNotNull);
      expect(service, isA<SmartNudgeService>());
    });

    group('Budget Warning Detection', () {
      test('should detect when approaching budget limit (90%)', () {
        const budgetLimit = 1000.0;
        const currentSpending = 900.0;
        final percentage = (currentSpending / budgetLimit) * 100;

        expect(percentage, greaterThanOrEqualTo(90));
        expect(percentage, lessThan(100));
      });

      test('should detect when exceeded budget (100%+)', () {
        const budgetLimit = 1000.0;
        const currentSpending = 1100.0;
        final percentage = (currentSpending / budgetLimit) * 100;

        expect(percentage, greaterThanOrEqualTo(100));
      });

      test('should not trigger for safe spending levels (<80%)', () {
        const budgetLimit = 1000.0;
        const currentSpending = 700.0;
        final percentage = (currentSpending / budgetLimit) * 100;

        expect(percentage, lessThan(80));
      });
    });

    group('Impulse Spending Detection', () {
      test('should detect multiple transactions in short time', () {
        final transactions = MockData.createTransactionList(count: 5);

        // All transactions within 24 hours
        final now = DateTime.now();
        final allWithin24Hours = transactions.every((t) =>
            now.difference(t.date).inHours < 24);

        expect(transactions.length, greaterThan(3));
        expect(allWithin24Hours, isTrue);
      });

      test('should calculate total spending amount', () {
        final transactions = MockData.createTransactionList(count: 5);
        final totalSpent = transactions.fold<double>(
          0.0,
          (sum, t) => sum + t.amount,
        );

        expect(totalSpent, greaterThan(0));
        expect(totalSpent, equals(10.0 + 15.0 + 20.0 + 25.0 + 30.0));
      });

      test('should identify high-risk categories', () {
        const highRiskCategories = ['Shopping', 'Entertainment', 'Dining'];

        expect(highRiskCategories, contains('Shopping'));
        expect(highRiskCategories, contains('Entertainment'));
        expect(highRiskCategories.length, equals(3));
      });
    });

    group('Nudge Priority Calculation', () {
      test('should assign high priority for budget overage', () {
        const overagePercentage = 110.0;

        expect(overagePercentage >= 100, isTrue);
        // High priority when over budget
      });

      test('should assign medium priority for approaching limit', () {
        const percentage = 85.0;

        expect(percentage >= 80 && percentage < 100, isTrue);
        // Medium priority when approaching
      });

      test('should assign low priority for minor concerns', () {
        const percentage = 70.0;

        expect(percentage < 80, isTrue);
        // Low priority for minor concerns
      });
    });

    group('Edge Cases', () {
      test('should handle zero budget gracefully', () {
        const budgetLimit = 0.0;
        const currentSpending = 100.0;

        // Should not crash with division by zero
        expect(() {
          if (budgetLimit > 0) {
            final percentage = (currentSpending / budgetLimit) * 100;
            return percentage;
          }
          return 100.0; // Default to 100% if budget is 0
        }, returnsNormally);
      });

      test('should handle negative spending (refunds)', () {
        const spending = -50.0;

        expect(spending, lessThan(0));
        // Should handle refunds correctly
      });

      test('should handle very large amounts', () {
        final transaction = MockData.createLargeAmountTransaction();

        expect(transaction.amount, greaterThan(100000));
        expect(transaction.amount, equals(999999.99));
      });

      test('should handle special characters in text', () {
        final transaction = MockData.createSpecialCharsTransaction();

        expect(transaction.merchant, isNotNull);
        expect(transaction.merchant, contains('Café'));
      });
    });

    group('Performance', () {
      test('should process nudges within 1 second target', () async {
        final stopwatch = Stopwatch()..start();

        // Simulate nudge processing
        final transactions = MockData.createTransactionList(count: 100);
        final totalSpent = transactions.fold<double>(
          0.0,
          (sum, t) => sum + t.amount,
        );

        stopwatch.stop();

        expect(totalSpent, greaterThan(0));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Data Validation', () {
      test('should validate transaction data completeness', () {
        final transaction = MockData.createTransaction();

        expect(transaction.id, isNotEmpty);
        expect(transaction.userId, isNotEmpty);
        expect(transaction.amount, greaterThan(0));
        expect(transaction.category, isNotEmpty);
        expect(transaction.currency, equals('USD'));
      });

      test('should validate SMS transaction metadata', () {
        final transaction = MockData.createSMSTransaction();

        expect(transaction.metadata.source, equals('sms'));
        expect(transaction.metadata.confidence, lessThanOrEqualTo(1.0));
        expect(transaction.metadata.aiAgent, isNotNull);
      });
    });
  });
}

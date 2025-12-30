import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Test helpers and utilities for consistent testing
///
/// Provides:
/// - Mock data factories
/// - Test wrappers
/// - Common assertions
/// - Timestamp helpers

/// Pump and settle with custom duration
Future<void> pumpAndSettle(WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 100),
}) async {
  await tester.pumpAndSettle(duration);
}

/// Create a test widget with MaterialApp wrapper
Widget createTestWidget(Widget child, {
  ThemeData? theme,
  Locale? locale,
}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    locale: locale,
    home: Scaffold(body: child),
  );
}

/// Create a test widget with full app context
Widget createTestWidgetWithContext(Widget child, {
  ThemeData? theme,
  Locale? locale,
  List<NavigatorObserver>? observers,
}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    locale: locale,
    navigatorObservers: observers ?? [],
    home: child,
  );
}

/// Timestamp helpers for testing
class TimestampHelpers {
  static Timestamp now() => Timestamp.now();

  static Timestamp fromDate(DateTime date) => Timestamp.fromDate(date);

  static Timestamp daysAgo(int days) {
    return Timestamp.fromDate(DateTime.now().subtract(Duration(days: days)));
  }

  static Timestamp hoursAgo(int hours) {
    return Timestamp.fromDate(DateTime.now().subtract(Duration(hours: hours)));
  }

  static Timestamp minutesAgo(int minutes) {
    return Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: minutes)));
  }
}

/// Find widgets by type helper
extension WidgetTesterExtensions on WidgetTester {
  /// Find a widget by type and index
  T widgetByType<T extends Widget>(int index) {
    return widget<T>(find.byType(T).at(index));
  }

  /// Find first widget of type
  T firstWidgetByType<T extends Widget>() {
    return widget<T>(find.byType(T).first);
  }

  /// Check if widget exists
  bool hasWidget(Type type) {
    return any(find.byType(type));
  }

  /// Check if text exists
  bool hasText(String text) {
    return any(find.text(text));
  }
}

/// Gesture helpers
extension GestureHelpers on WidgetTester {
  /// Tap a widget by key
  Future<void> tapByKey(Key key) async {
    await tap(find.byKey(key));
    await pump();
  }

  /// Tap a widget by text
  Future<void> tapByText(String text) async {
    await tap(find.text(text));
    await pump();
  }

  /// Tap a widget by icon
  Future<void> tapByIcon(IconData icon) async {
    await tap(find.byIcon(icon));
    await pump();
  }

  /// Long press by key
  Future<void> longPressByKey(Key key) async {
    await longPress(find.byKey(key));
    await pump();
  }

  /// Scroll until visible
  Future<void> scrollUntilVisible(
    Finder finder,
    double delta, {
    Finder? scrollable,
  }) async {
    await scrollUntilVisible(
      finder,
      delta,
      scrollable: scrollable ?? find.byType(Scrollable).first,
    );
  }
}

/// Common test assertions
class TestAssertions {
  /// Assert widget is visible
  static void assertVisible(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Assert widget is not visible
  static void assertNotVisible(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Assert multiple widgets
  static void assertCount(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

  /// Assert text contains
  static void assertTextContains(Finder finder, String substring) {
    final widget = finder.evaluate().single.widget as Text;
    expect(widget.data, contains(substring));
  }

  /// Assert widget has property
  static void assertHasProperty<T>(Finder finder, bool Function(T) predicate) {
    final widget = finder.evaluate().single.widget as T;
    expect(predicate(widget), isTrue);
  }
}

/// Animation test helpers
class AnimationHelpers {
  /// Pump frames for animation
  static Future<void> pumpFrames(
    WidgetTester tester,
    Duration duration, {
    Duration frameInterval = const Duration(milliseconds: 16),
  }) async {
    final frames = duration.inMilliseconds ~/ frameInterval.inMilliseconds;
    for (var i = 0; i < frames; i++) {
      await tester.pump(frameInterval);
    }
  }

  /// Wait for animation to complete
  static Future<void> waitForAnimation(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.pumpAndSettle(timeout);
  }
}

/// Async test helpers
class AsyncHelpers {
  /// Wait for condition to be true
  static Future<void> waitForCondition(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration checkInterval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      if (condition()) return;
      await Future.delayed(checkInterval);
    }
    throw TimeoutException('Condition not met within timeout');
  }

  /// Wait for future with timeout
  static Future<T> waitFor<T>(
    Future<T> future, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return future.timeout(timeout);
  }
}

/// Exception for test timeouts
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

/// Test data size helpers
class TestDataSize {
  static const int small = 5;
  static const int medium = 20;
  static const int large = 100;
}

/// Performance test helpers
class PerformanceHelpers {
  /// Measure execution time
  static Future<Duration> measureTime(Future<void> Function() action) async {
    final stopwatch = Stopwatch()..start();
    await action();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Assert performance threshold
  static void assertPerformance(
    Duration actual,
    Duration threshold, {
    String? message,
  }) {
    expect(
      actual.inMilliseconds,
      lessThanOrEqualTo(threshold.inMilliseconds),
      reason: message ?? 'Performance threshold exceeded',
    );
  }
}

/// Mock builders for common scenarios
class MockBuilders {
  /// Create a mock user
  static User createMockUser({
    String uid = 'test-user-123',
    String email = 'test@example.com',
    String displayName = 'Test User',
  }) {
    // Note: Actual implementation would use a mock package
    throw UnimplementedError('Use mockito or mocktail to implement');
  }

  /// Create mock Firestore document
  static DocumentSnapshot createMockDocument({
    required String id,
    required Map<String, dynamic> data,
  }) {
    throw UnimplementedError('Use fake_cloud_firestore package');
  }
}

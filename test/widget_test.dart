// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fin_copilot/main.dart';

void main() {
  testWidgets('Fin Co-Pilot app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FinCopilotApp());

    // Verify that our app loads with the correct title
    expect(find.text('Fin Co-Pilot'), findsOneWidget);
    expect(find.text('Test Firestore Write/Read'), findsOneWidget);
    
    // Verify the wallet icon is present
    expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
  });
}

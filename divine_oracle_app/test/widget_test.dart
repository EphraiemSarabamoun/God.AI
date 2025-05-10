// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:divine_oracle_app/main.dart'; // This import is correct

void main() {
  // testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  //   // Build our app and trigger a frame.
  //   await tester.pumpWidget(const DivineOracleApp()); // Changed MyApp to DivineOracleApp

  //   // Verify that our counter starts at 0.
  //   expect(find.text('0'), findsOneWidget);
  //   expect(find.text('1'), findsNothing);

  //   // Tap the '+' icon and trigger a frame.
  //   await tester.tap(find.byIcon(Icons.add));
  //   await tester.pump();

  //   // Verify that our counter has incremented.
  //   expect(find.text('0'), findsNothing);
  //   expect(find.text('1'), findsOneWidget);
  // });

  // A more relevant basic test for your app:
  testWidgets('OracleHomePage has a title and input field', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DivineOracleApp());

    // Verify that the AppBar title is present.
    expect(find.text('Seek Wisdom from God'), findsOneWidget);

    // Verify that the input field (TextField) is present.
    // You can find it by type or by a more specific property if needed.
    expect(find.byType(TextField), findsOneWidget);

    // Verify the initial text in the response area
    expect(find.text('Write your prayer...'), findsOneWidget);
  });
}
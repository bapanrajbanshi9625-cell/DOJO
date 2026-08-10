import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dojo/main.dart'; // Yahan 'dojo' ki jagah apne project ka actual package name likh sakte hain

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp()); // Agar aapke main widget ka naam alag hai toh use yahan badal lein

    // Verify that our app starts up without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

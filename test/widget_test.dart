import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dojo/main.dart'; // Apne app ka package name

void main() {
  testWidgets('Dojo App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp()); // Agar aapke main widget ka naam MyApp hai

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

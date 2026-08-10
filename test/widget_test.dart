import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dojo/main.dart'; // Aapke app ka package name

void main() {
  testWidgets('Dojo App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame using the correct class name 'Dojo'
    await tester.pumpWidget(const Dojo()); 

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

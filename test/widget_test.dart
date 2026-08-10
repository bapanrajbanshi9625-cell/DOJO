import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dojo/app.dart'; // Yahan main.dart ki jagah app.dart import karna hoga

void main() {
  testWidgets('Dojo App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame using the correct class name 'DojoApp'
    await tester.pumpWidget(const DojoApp()); 

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

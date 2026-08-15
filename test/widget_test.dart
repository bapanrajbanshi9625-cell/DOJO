import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Dojo Walk app smoke test',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Dojo Walk'),
            ),
          ),
        ),
      );

      expect(
        find.byType(MaterialApp),
        findsOneWidget,
      );

      expect(
        find.text('Dojo Walk'),
        findsOneWidget,
      );
    },
  );
}

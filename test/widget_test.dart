import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_walk/app.dart';

void main() {
  testWidgets(
    'Dojo Walk app smoke test',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const DojoApp(),
      );

      expect(
        find.byType(MaterialApp),
        findsOneWidget,
      );
    },
  );
}

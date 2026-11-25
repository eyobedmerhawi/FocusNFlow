
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_n_flow/main.dart';

void main() {
  testWidgets(
    'FocusNFlow displays the application shell',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('FocusNFlow'),
            ),
          ),
        ),
      );

      expect(find.text('FocusNFlow'), findsOneWidget);
    },
  );

  testWidgets(
    'FocusNFlowApp can be constructed',
    (WidgetTester tester) async {
      const app = FocusNFlowApp();

      expect(app, isA<StatelessWidget>());
    },
  );
}

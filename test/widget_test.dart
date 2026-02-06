// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/main.dart';

void main() {
  testWidgets('renders tabs and can switch to focus mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowForgeApp());

    expect(find.text('FlowForge'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Reflect'), findsOneWidget);

    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();

    expect(find.text('Start Session'), findsOneWidget);

    await tester.tap(find.text('Start Session'));
    await tester.pump();

    expect(find.text('Pause Session'), findsOneWidget);
  });

  testWidgets('can add a todo from Today tab', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowForgeApp());

    final todoInput = find.byKey(const ValueKey<String>('todo-input'));
    final addButton = find.byKey(const ValueKey<String>('todo-add-button'));

    await tester.ensureVisible(todoInput);
    await tester.enterText(todoInput, 'Refill standing-desk water bottle');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('Refill standing-desk water bottle'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowforge/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('renders main UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowForgeApp());
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('todo-input')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('todo-add-button')),
      findsOneWidget,
    );
  });

  testWidgets('can add a todo', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowForgeApp());

    final todoInput = find.byKey(const ValueKey<String>('todo-input'));

    await tester.enterText(todoInput, 'Refill standing-desk water bottle');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Refill standing-desk water bottle'), findsOneWidget);
  });

  testWidgets('can add deep-energy todo', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowForgeApp());

    final todoInput = find.byKey(const ValueKey<String>('todo-input'));
    final deepChip = find.byKey(const ValueKey<String>('todo-energy-deep'));

    await tester.tap(todoInput);
    await tester.pump();

    await tester.ensureVisible(deepChip);
    await tester.tap(deepChip, warnIfMissed: false);
    await tester.pump();

    await tester.enterText(todoInput, 'Hard architecture refactor');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Hard architecture refactor'), findsOneWidget);
  });

  testWidgets('todo add details are collapsed by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowForgeApp());

    expect(
      find.byKey(const ValueKey<String>('todo-energy-deep')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey<String>('todo-effort-90')), findsNothing);
  });

  testWidgets('todo input expands detail controls on focus', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowForgeApp());

    final todoInput = find.byKey(const ValueKey<String>('todo-input'));
    await tester.tap(todoInput);
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('todo-energy-deep')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('todo-effort-90')),
      findsOneWidget,
    );
  });

  testWidgets('can set due date chips', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowForgeApp());

    final todoInput = find.byKey(const ValueKey<String>('todo-input'));
    await tester.tap(todoInput);
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
  });
}

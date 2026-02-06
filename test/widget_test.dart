// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowforge/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

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

    await tester.ensureVisible(todoInput);
    await tester.enterText(todoInput, 'Refill standing-desk water bottle');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Refill standing-desk water bottle'), findsOneWidget);
  });

  testWidgets('can add high-effort deep-energy todo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowForgeApp());

    final todoInput = find.byKey(const ValueKey<String>('todo-input'));
    final deepChip = find.byKey(const ValueKey<String>('todo-energy-deep'));
    final effortChip = find.byKey(const ValueKey<String>('todo-effort-90'));

    await tester.ensureVisible(todoInput);
    await tester.tap(todoInput);
    await tester.pumpAndSettle();

    await tester.ensureVisible(deepChip);
    await tester.tap(deepChip);
    await tester.pumpAndSettle();

    await tester.ensureVisible(effortChip);
    await tester.tap(effortChip);
    await tester.pumpAndSettle();

    await tester.ensureVisible(todoInput);
    await tester.enterText(todoInput, 'Hard architecture refactor');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Hard architecture refactor'), findsOneWidget);
    expect(find.text('Deep energy'), findsOneWidget);
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
    await tester.ensureVisible(todoInput);
    await tester.tap(todoInput);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('todo-energy-deep')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('todo-effort-90')),
      findsOneWidget,
    );
  });

  testWidgets('energy presets auto-sync the focus block', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowForgeApp());

    final highEnergy = find.byKey(const ValueKey<String>('energy-preset-85'));
    final lowEnergy = find.byKey(const ValueKey<String>('energy-preset-25'));

    await tester.ensureVisible(highEnergy);
    await tester.tap(highEnergy);
    await tester.pumpAndSettle();
    await tester.ensureVisible(lowEnergy);
    await tester.tap(lowEnergy);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();

    expect(find.text('15:00'), findsOneWidget);
  });

  testWidgets('focus tab shows activity board', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowForgeApp());

    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Focus Activity'));
    expect(find.text('Focus Activity'), findsOneWidget);
  });

  testWidgets('todo list shows top three and rotates remaining tasks', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowForgeApp());

    final todoInput = find.byKey(const ValueKey<String>('todo-input'));

    await tester.enterText(todoInput, 'Write release notes draft');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.enterText(todoInput, 'Send follow-up email');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.enterText(todoInput, 'Review onboarding docs');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.enterText(todoInput, 'Schedule planning call');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Top 3'), findsOneWidget);
    expect(
      find.text('1 more queued. Finish one and the next appears here.'),
      findsOneWidget,
    );
    expect(find.text('Write release notes draft'), findsOneWidget);
    expect(find.text('Send follow-up email'), findsOneWidget);
    expect(find.text('Review onboarding docs'), findsOneWidget);
    expect(find.text('Schedule planning call'), findsNothing);
  });

  testWidgets('completed todos move into the finished section', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowForgeApp());

    final todoInput = find.byKey(const ValueKey<String>('todo-input'));

    await tester.enterText(todoInput, 'Wrap onboarding checklist');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final completedCheckbox = find.byType(Checkbox).last;
    await tester.ensureVisible(completedCheckbox);
    await tester.tap(completedCheckbox);
    await tester.pumpAndSettle();

    expect(find.text('Finished (1)'), findsOneWidget);
    expect(find.text('Wrap onboarding checklist'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('toggle-finished-todos')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wrap onboarding checklist'), findsOneWidget);
  });

  testWidgets('reset focus button asks for confirmation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowForgeApp());

    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Session'));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('focus-reset-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('focus-reset-dialog')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('focus-reset-cancel')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('focus-reset-dialog')),
      findsNothing,
    );
  });
}

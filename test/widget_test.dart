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

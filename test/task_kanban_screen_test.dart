import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowforge/flowforge/models/task_energy_requirement.dart';
import 'package:flowforge/flowforge/state/app_state.dart';
import 'package:flowforge/flowforge/state/project_state.dart';
import 'package:flowforge/flowforge/widgets/task_kanban_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('task board filters tasks by the active project', (
    WidgetTester tester,
  ) async {
    final appState = FlowForgeState();
    final projectState = ProjectState();

    appState.init();
    await projectState.init();
    await projectState.addProject(
      name: 'Code',
      color: Colors.orange,
      icon: Icons.code_rounded,
    );

    final codeProject = projectState.projects.last;
    await projectState.setActiveProject(codeProject.id);

    appState.addTodoFromKanban(
      title: 'Visible code task',
      energyRequirement: TaskEnergyRequirement.medium,
      estimateMinutes: 25,
      projectId: codeProject.id,
    );
    appState.addTodoFromKanban(
      title: 'Hidden general task',
      energyRequirement: TaskEnergyRequirement.low,
      estimateMinutes: 15,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ProjectState>.value(
        value: projectState,
        child: MaterialApp(
          home: TaskKanbanScreen(state: appState, onToggleTheme: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('kanban-project-scope-banner')),
      findsOneWidget,
    );
    expect(find.text('Visible code task'), findsOneWidget);
    expect(find.text('Hidden general task'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('kanban-clear-project-scope')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hidden general task'), findsOneWidget);
  });
}

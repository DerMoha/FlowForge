import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowforge/flowforge/state/analytics_state.dart';
import 'package:flowforge/flowforge/state/app_state.dart';
import 'package:flowforge/flowforge/state/project_state.dart';
import 'package:flowforge/flowforge/widgets/workspace_hub.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('workspace hub can activate and clear project scope', (
    WidgetTester tester,
  ) async {
    final appState = FlowForgeState();
    final projectState = ProjectState();
    final analyticsState = AnalyticsState();

    appState.init();
    await projectState.init();
    await projectState.addProject(
      name: 'Code',
      color: Colors.orange,
      icon: Icons.code_rounded,
    );

    final codeProject = projectState.projects.last;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProjectState>.value(value: projectState),
          ChangeNotifierProvider<AnalyticsState>.value(value: analyticsState),
        ],
        child: MaterialApp(home: WorkspaceHubPage(state: appState)),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('workspace-all-projects-card')),
      findsOneWidget,
    );

    await projectState.setActiveProject(codeProject.id);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('workspace-active-project-card')),
      findsOneWidget,
    );
    expect(find.text('Code'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey<String>('workspace-summary-show-all')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('workspace-all-projects-card')),
      findsOneWidget,
    );
  });
}

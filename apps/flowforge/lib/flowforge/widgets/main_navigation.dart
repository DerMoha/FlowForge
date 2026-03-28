import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'calm_scaffold.dart';
import 'task_kanban_screen.dart';
import 'schedule_view.dart';
import 'workspace_hub.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({
    super.key,
    required this.state,
    required this.onToggleTheme,
  });

  final FlowForgeState state;
  final VoidCallback onToggleTheme;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _selectDestination(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 980;
        final content = IndexedStack(
          index: _currentIndex,
          children: <Widget>[
            CalmScaffold(
              state: widget.state,
              onToggleTheme: widget.onToggleTheme,
            ),
            TaskKanbanScreen(
              state: widget.state,
              onToggleTheme: widget.onToggleTheme,
            ),
            const ScheduleView(),
            WorkspaceHubPage(state: widget.state),
          ],
        );

        if (!useRail) {
          return Scaffold(
            extendBody: true,
            body: content,
            bottomNavigationBar: _buildBottomNav(context),
          );
        }

        return Scaffold(
          body: Row(
            children: <Widget>[
              _buildNavigationRail(context),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _selectDestination,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 72,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.center_focus_strong_outlined),
              selectedIcon: Icon(Icons.center_focus_strong_rounded),
              label: 'Focus',
            ),
            NavigationDestination(
              icon: Icon(Icons.view_kanban_outlined),
              selectedIcon: Icon(Icons.view_kanban_rounded),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Workspace',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Container(
          width: 104,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20),
              Icon(Icons.spa_rounded, color: scheme.primary, size: 28),
              const SizedBox(height: 12),
              Expanded(
                child: NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _selectDestination,
                  backgroundColor: Colors.transparent,
                  indicatorColor: scheme.primaryContainer,
                  useIndicator: true,
                  labelType: NavigationRailLabelType.all,
                  leading: const SizedBox.shrink(),
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: Icon(Icons.center_focus_strong_outlined),
                      selectedIcon: Icon(Icons.center_focus_strong_rounded),
                      label: Text('Focus'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.view_kanban_outlined),
                      selectedIcon: Icon(Icons.view_kanban_rounded),
                      label: Text('Tasks'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month_rounded),
                      label: Text('Schedule'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.space_dashboard_outlined),
                      selectedIcon: Icon(Icons.space_dashboard_rounded),
                      label: Text('Workspace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

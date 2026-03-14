import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/date_helpers.dart';
import 'ambient_gradient_background.dart';
import 'calm_scaffold.dart';
import 'task_kanban_screen.dart';
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

  void _openWorkspace(BuildContext context) {
    openWorkspaceHub(context, widget.state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: <Widget>[
          CalmScaffold(
            state: widget.state,
            onToggleTheme: widget.onToggleTheme,
            onOpenWorkspace: () => _openWorkspace(context),
          ),
          _KanbanPage(
            state: widget.state,
            onToggleTheme: widget.onToggleTheme,
            onOpenWorkspace: () => _openWorkspace(context),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
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
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 68,
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
          ],
        ),
      ),
    );
  }
}

class _KanbanPage extends StatelessWidget {
  const _KanbanPage({
    required this.state,
    required this.onToggleTheme,
    required this.onOpenWorkspace,
  });

  final FlowForgeState state;
  final VoidCallback onToggleTheme;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AmbientGradientBackground(
      energy: state.energy,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: <Widget>[
                  _buildHeader(context, scheme, textTheme, isDark),
                  Expanded(child: TaskKanbanScreen(state: state)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme scheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'FlowForge',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Task board for ${formatCompactDate(DateTime.now())}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton.filledTonal(
                tooltip: 'Open workspace',
                onPressed: onOpenWorkspace,
                icon: const Icon(Icons.dashboard_customize_rounded),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: IconButton.filledTonal(
                  tooltip: isDark
                      ? 'Switch to light mode'
                      : 'Switch to dark mode',
                  onPressed: onToggleTheme,
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/date_helpers.dart';
import 'calm_scaffold.dart';
import 'task_kanban_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: <Widget>[
          CalmScaffold(
            state: widget.state,
            onToggleTheme: widget.onToggleTheme,
          ),
          _KanbanPage(state: widget.state, onToggleTheme: widget.onToggleTheme),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.8)
            : scheme.surface.withValues(alpha: 0.9),
        elevation: 0,
        height: 64,
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
    );
  }
}

class _KanbanPage extends StatelessWidget {
  const _KanbanPage({required this.state, required this.onToggleTheme});

  final FlowForgeState state;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  scheme.surface,
                  scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ]
              : [
                  scheme.primaryContainer.withValues(alpha: 0.1),
                  scheme.surface,
                ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            _buildHeader(context, scheme, textTheme, isDark),
            Expanded(child: TaskKanbanScreen(state: state)),
          ],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            formatCompactDate(DateTime.now()),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          IconButton.filledTonal(
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: onToggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

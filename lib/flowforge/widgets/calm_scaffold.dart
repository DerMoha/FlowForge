import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/date_helpers.dart';
import 'activity_heatmap.dart';
import 'ambient_gradient_background.dart';
import 'collapsible_section.dart';
import 'energy_floating_indicator.dart';
import 'focus_mode_transition.dart';
import 'focus_timer_ring.dart';
import 'hero_task_card.dart';
import 'session_stats_bar.dart';
import 'shutdown_ritual_section.dart';
import 'task_input_bar.dart';
import 'task_river.dart';

class CalmScaffold extends StatefulWidget {
  const CalmScaffold({
    super.key,
    required this.state,
    required this.onToggleTheme,
  });

  final FlowForgeState state;
  final VoidCallback onToggleTheme;

  @override
  State<CalmScaffold> createState() => _CalmScaffoldState();
}

class _CalmScaffoldState extends State<CalmScaffold> {
  bool _focusExpanded = false;
  bool _activityExpanded = false;
  bool _reflectExpanded = false;

  FlowForgeState get _state => widget.state;

  @override
  void initState() {
    super.initState();
    _state.onShowSnack = _handleSnack;
    _state.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(CalmScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.onShowSnack = null;
      oldWidget.state.removeListener(_onStateChanged);
      _state.onShowSnack = _handleSnack;
      _state.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    _state.onShowSnack = null;
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  void _handleSnack() {
    final message = _state.pendingSnackMessage;
    if (message == null) return;
    _state.consumeSnack();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFocusMode = _state.isRunning;

    return AmbientGradientBackground(
      energy: _state.energy,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  _minimalHeader(context),
                  FocusModeTransition(
                    isFocusMode: isFocusMode,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: TaskInputBar(state: _state),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: HeroTaskCard(state: _state),
                          ),
                          FocusModeTransition(
                            isFocusMode: isFocusMode,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: TaskRiver(state: _state),
                            ),
                          ),
                          CollapsibleSection(
                            title: 'Focus Timer',
                            icon: Icons.bolt_rounded,
                            isExpanded: _focusExpanded,
                            forceExpanded: isFocusMode,
                            onToggle: () => setState(
                              () => _focusExpanded = !_focusExpanded,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: FocusTimerRing(state: _state),
                            ),
                          ),
                          FocusModeTransition(
                            isFocusMode: isFocusMode,
                            child: CollapsibleSection(
                              title: 'Activity',
                              icon: Icons.insights_rounded,
                              isExpanded: _activityExpanded,
                              onToggle: () => setState(
                                () => _activityExpanded = !_activityExpanded,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  SessionStatsBar(state: _state),
                                  const SizedBox(height: 14),
                                  ActivityHeatmap(state: _state),
                                ],
                              ),
                            ),
                          ),
                          FocusModeTransition(
                            isFocusMode: isFocusMode,
                            child: CollapsibleSection(
                              title: 'Reflect',
                              icon: Icons.nights_stay_rounded,
                              isExpanded: _reflectExpanded,
                              onToggle: () => setState(
                                () => _reflectExpanded = !_reflectExpanded,
                              ),
                              child: ShutdownRitualSection(state: _state),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FocusModeTransition(
                  isFocusMode: isFocusMode,
                  child: EnergyFloatingIndicator(state: _state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _minimalHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            onPressed: widget.onToggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

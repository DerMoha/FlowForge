import 'package:flutter/material.dart';

import '../models/energy_preset.dart';
import '../state/app_state.dart';
import '../utils/date_helpers.dart';
import 'activity_heatmap.dart';
import 'ambient_gradient_background.dart';
import 'collapsible_section.dart';
import 'focus_mode_transition.dart';
import 'focus_timer_ring.dart';
import 'hero_task_card.dart';
import 'session_stats_bar.dart';
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
  bool _activityExpanded = false;

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
                  _focusHeader(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: _dailySnapshot(context),
                  ),
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
                          Text(
                            'Focus now',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pick the best task for your current energy, then lock into one block.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: HeroTaskCard(state: _state),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _primaryFocusSection(context),
                          ),
                          Text(
                            'Task queue',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Keep Today lean and let the rest wait in backlog until it earns attention.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          FocusModeTransition(
                            isFocusMode: isFocusMode,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: TaskRiver(state: _state),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _focusHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _state.activeEnergyPreset;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
                  formatCompactDate(DateTime.now()),
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              GestureDetector(
                onTap: () => _showEnergySheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(active.icon, size: 16, color: active.color),
                      const SizedBox(width: 6),
                      Text(
                        '${active.label} ${active.value}%',
                        style: textTheme.labelLarge?.copyWith(
                          color: active.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              IconButton.filledTonal(
                tooltip: isDark
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                onPressed: widget.onToggleTheme,
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dailySnapshot(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = _state.activeEnergyPreset;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(
          alpha: isDark ? 0.76 : 0.88,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${active.label} energy is active',
            style: textTheme.labelLarge?.copyWith(
              color: active.color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            active.hint,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _snapshotMetric(
                context,
                icon: Icons.today_rounded,
                label: 'Today',
                value: '${_state.todayTodoCount}',
                color: scheme.primary,
              ),
              _snapshotMetric(
                context,
                icon: Icons.inventory_2_rounded,
                label: 'Open',
                value: '${_state.openTodoCount}',
                color: scheme.tertiary,
              ),
              _snapshotMetric(
                context,
                icon: Icons.trending_up_rounded,
                label: 'Momentum',
                value: '${_state.momentumScore}',
                color: scheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _snapshotMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _primaryFocusSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(
          alpha: isDark ? 0.74 : 0.9,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.timer_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Focus timer',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Keep one timer visible at all times so starting a block is never hidden.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FocusTimerRing(state: _state),
        ],
      ),
    );
  }

  void _showEnergySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EnergySheet(state: _state),
    );
  }
}

class _EnergySheet extends StatelessWidget {
  const _EnergySheet({required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = state.activeEnergyPreset;
    final activeIndex = energyPresets.indexWhere(
      (p) => p.value == active.value,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(active.icon, color: active.color, size: 24),
              const SizedBox(width: 12),
              Text(
                'Energy Level',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            active.hint,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _buildBatteryBar(context, activeIndex),
          const SizedBox(height: 16),
          Text(
            '${active.value}% energy',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: active.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryBar(BuildContext context, int activeIndex) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: List<Widget>.generate(energyPresets.length, (index) {
                final preset = energyPresets[index];
                final lit = index <= activeIndex;
                final selected = index == activeIndex;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == energyPresets.length - 1 ? 0 : 4,
                    ),
                    child: Tooltip(
                      message: '${preset.label} ${preset.value}%',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            state.setEnergyPreset(preset);
                            Navigator.of(context).pop();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            height: 36,
                            decoration: BoxDecoration(
                              color: lit
                                  ? preset.color.withValues(
                                      alpha: selected ? 0.95 : 0.55,
                                    )
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: lit
                                    ? preset.color.withValues(alpha: 0.85)
                                    : scheme.outlineVariant.withValues(
                                        alpha: 0.4,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 5,
            height: 18,
            decoration: BoxDecoration(
              color: scheme.outlineVariant.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
